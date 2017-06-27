#!/bin/bash

# Install Docker, Tensorflow and MaskRCNN


### GLOBALS
DCR_ROOT_PATH=/home/maskrcnn/
DCR_MASKRCNN_PATH=$DCR_ROOT_PATH/FastMaskRCNN/
REPO_NAME='tensorflow_maskrcnn_gpu'
CONTAINER_NAME='maskrcnn'
TENSORFLOW_TYPE='gpu'
DOCKER='nvidia-docker'
DOCKER_FILE='Dockerfile_gpu'
HOST_PERSISTENT_DATA_PATH=$(pwd)/FastMaskRCNN


### FUNCTIONS
function install_docker(){

	echo "### install_docker ###"

	echo "Installing/Updating Docker"
	sudo apt-get remove docker docker-engine

	sudo apt-get update

	# Recommended extra packages for Trusty 14.04
	#sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual

	# Install packages to allow apt to use a repository over HTTPS
	sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common

	# Add Docker’s official GPG key
	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

	# Set up the stable repository
	sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

	# Install/Update docker
	sudo apt-get update
	sudo apt-cache policy docker-ce
	sudo apt-get -y install docker-ce
	#sudo apt-get -y install docker-ce=<VERSION>

	# Test installation
	sudo docker run hello-world
}


function setup_docker_image(){

	echo "### setup_docker_image ###"

	echo "Installing Docker Tensorflow $TENSORFLOW_TYPE"

	if [[ $1 == 'cpu' ]];then
		# TODO
		DOCKER='docker'
		REPO_NAME='tensorflow_maskrcnn_cpu'
		DOCKER_FILE='Dockerfile_cpu'

		# Run non-GPU container using
		sudo docker pull gcr.io/tensorflow/tensorflow

	elif [[ $1 == 'gpu' ]];then
		DOCKER='nvidia-docker'
		REPO_NAME='tensorflow_maskrcnn_gpu'
		DOCKER_FILE='Dockerfile_gpu'

		# Install nvidia-docker and nvidia-docker-plugin
		wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb
		sudo dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb
		sudo nvidia-docker run --rm nvidia/cuda nvidia-smi

		# For GPU support install NVidia drivers (ideally latest) and nvidia-docker. Run using
		#sudo nvidia-docker run -it -p 8888:8888 gcr.io/tensorflow/tensorflow:latest-gpu

	else
		echo "Unknown docker image. Exiting..."
		exit 1
	fi

	sudo $DOCKER stop $CONTAINER_NAME
	sudo $DOCKER rm $CONTAINER_NAME
	sudo $DOCKER rmi $REPO_NAME


	# Create Docker Image
	echo "Generating Docker image using $DOCKER_FILE "
	sudo $DOCKER build -f $DOCKER_FILE -t $REPO_NAME .

}


function setup_docker_container(){

	echo "### setup_docker_container ###"

	if [[ $1 == 'cpu' ]];then
		DOCKER='docker'
		REPO_NAME='tensorflow_maskrcnn_cpu'

	elif [[ $1 == 'gpu' ]];then
		DOCKER='nvidia-docker'
		REPO_NAME='tensorflow_maskrcnn_gpu'
	fi

	sudo $DOCKER rm -f $CONTAINER_NAME
	mkdir -p $HOST_PERSISTENT_DATA_PATH

	sudo $DOCKER run -d -v $HOST_PERSISTENT_DATA_PATH:$DCR_MASKRCNN_PATH --name $CONTAINER_NAME $REPO_NAME

}


function setup_maskrcnn(){

	echo "### setup_maskrcnn ###"

	# Download code
	# Cannot remove FastMaskRCNN directorey as we have mounted FastMaskRCNN in docker container
	git clone https://github.com/CharlesShang/FastMaskRCNN /tmp/FastMaskRCNN
	rm -rf FastMaskRCNN/*
	mv /tmp/FastMaskRCNN/* FastMaskRCNN/
	rm -rf /tmp/FastMaskRCNN


	### Prerequisite
	sudo $DOCKER exec -it $CONTAINER_NAME bash -c "cd $DCR_MASKRCNN_PATH/libs/datasets/pycocotools; make"

	cd FastMaskRCNN
	mkdir -p data/coco
	mkdir -p data/pretrained_models
	mkdir -p output/mask_rcnn


	# Download models
	if [[ -n ${RESNET50_DATASET_PATH} ]];then
		echo "Copying resnet_v1_50_2016_08_28.tar.gz"
		cp $RESNET50_DATASET_PATH/resnet_v1_50_2016_08_28.tar.gz data/pretrained_models/
	fi

	cd data/pretrained_models
	wget -nc http://download.tensorflow.org/models/resnet_v1_50_2016_08_28.tar.gz
	tar -xzvf resnet_v1_50_2016_08_28.tar.gz
	cd ../..


	# Download dataset
	if [[ -n ${COCO_DATASET_PATH} ]];then
		echo "Copying COCO Dataset"
		cp "$COCO_DATASET_PATH""/train2014.zip" "data/coco/"
		cp "$COCO_DATASET_PATH""/val2014.zip" "data/coco/"
		cp "$COCO_DATASET_PATH""/instances_train-val2014.zip" "data/coco/"
		cp "$COCO_DATASET_PATH""/person_keypoints_trainval2014.zip" "data/coco/"
		cp "$COCO_DATASET_PATH""/captions_train-val2014.zip" "data/coco/"
	fi

	cd data/coco
	wget -nc http://msvocds.blob.core.windows.net/coco2014/train2014.zip
	unzip train2014.zip
	wget -nc http://msvocds.blob.core.windows.net/coco2014/val2014.zip
	unzip val2014.zip
	wget -nc http://msvocds.blob.core.windows.net/annotations-1-0-3/instances_train-val2014.zip
	unzip instances_train-val2014.zip
	wget -nc http://msvocds.blob.core.windows.net/annotations-1-0-3/person_keypoints_trainval2014.zip
	unzip person_keypoints_trainval2014.zip
	wget -nc http://msvocds.blob.core.windows.net/annotations-1-0-3/captions_train-val2014.zip
	unzip captions_train-val2014.zip
	cd ../..


	### Compile libraries
	sudo $DOCKER exec -it $CONTAINER_NAME bash -c "cd $DCR_MASKRCNN_PATH/libs; make"
	
}


function generate_annotations_maskrcnn(){

	echo "### generate_annotations_maskrcnn ###"

	sudo $DOCKER exec -it $CONTAINER_NAME bash -c "cd $DCR_MASKRCNN_PATH; python download_and_convert_data.py"

}

function train_maskrcnn(){

	echo "### train_maskrcnn ###"

	cd $HOST_PERSISTENT_DATA_PATH

	echo "Command for training with CPU"
	echo "sudo $DOCKER exec -it $CONTAINER_NAME bash -c \"cd $DCR_MASKRCNN_PATH; export CUDA_VISIBLE_DEVICES= ; python train/train.py\""
	#sudo $DOCKER exec -it $CONTAINER_NAME bash -c "cd $DCR_MASKRCNN_PATH; export CUDA_VISIBLE_DEVICES= ; python train/train.py"

	echo "Command for training with GPU"
	echo "sudo $DOCKER exec -it $CONTAINER_NAME bash -c \"cd $DCR_MASKRCNN_PATH; python train/train.py\""
	sudo $DOCKER exec -it $CONTAINER_NAME bash -c "cd $DCR_MASKRCNN_PATH; python train/train.py"

}



##### MAIN #####

# DOCKER
# echo -n "Install/Update Docker (Ubuntu 16.04) [y/n] ? "
# read input
# if [[ $input == 'y' ]] || [[ $input == 'Y' ]];then
# 	install_docker
# fi

# RESNET50 DATASET
echo -n "Enter resnet_v1_50_2016_08_28.tar.gz ABSOLUTE PATH starting with / [Example: /home/Downloads] (Press Enter to download): "
read input_resnet50
if [[ -n ${input_resnet50} ]];then
	RESNET50_DATASET_PATH=$input_resnet50
	echo "RESNET50 Dataset Path: $RESNET50_DATASET_PATH"
fi
echo ""

# COCO DATASET
echo "Enter train2014.zip, val2014.zip, instances_train-val2014.zip, person_keypoints_trainval2014.zip and captions_train-val2014.zip"
echo -n "ABSOLUTE PATH starting with / [Example: /home/Downloads] (Press Enter to download): "
read input_coco
if [[ -n ${input_coco} ]];then
	COCO_DATASET_PATH=$input_coco
	echo "COCO Dataset Path: $COCO_DATASET_PATH"
fi

# SETUP DOCKER ENVIRONMENT
# echo -n "Enter Tensorflow type to install [cpu/gpu] ? "
# read input_tf
# if [[ $input_tf == 'cpu' ]] || [[ $input_tf == 'CPU' ]] || [[ $input_tf == 'gpu' ]] || [[ $input_tf == 'GPU' ]];then
# 	TENSORFLOW_TYPE=$input_tf
# fi


setup_docker_image $TENSORFLOW_TYPE
setup_docker_container $TENSORFLOW_TYPE
setup_maskrcnn
generate_annotations_maskrcnn
train_maskrcnn


