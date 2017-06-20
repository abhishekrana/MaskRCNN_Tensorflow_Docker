#!/bin/bash

# Install Docker, Tensorflow and MaskRCNN


### GLOBALS
DCR_ROOT_PATH=/home/maskrcnn/
DCR_MASKRCNN_PATH=$DCR_ROOT_PATH/FastMaskRCNN/
CONTAINER_NAME='maskrcnn'
TENSORFLOW_TYPE='cpu'
IMAGE_ID='gcr.io/tensorflow/tensorflow'
DOCKER='docker'
SCRIPT_NAME='maskRCNN.sh'


### FUNCTIONS
function install_docker(){

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


function setup_docker_env(){

	echo "Installing Docker Tensorflow $TENSORFLOW_TYPE"

	if [[ $1 == 'cpu' ]];then
		DOCKER='docker'
		IMAGE_ID='gcr.io/tensorflow/tensorflow'
		#IMAGE_ID=5f86ff0436e8

		# Run non-GPU container using
		sudo docker pull gcr.io/tensorflow/tensorflow

	elif [[ $1 == 'gpu' ]];then
		DOCKER='nvidia-docker'
		IMAGE_ID='gcr.io/tensorflow/tensorflow:latest-gpu'
		#IMAGE_ID=85c8f551e1d2

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

	# Create docker container
	sudo $DOCKER run -d -v maskrcnn:$DCR_ROOT_PATH --name $CONTAINER_NAME $IMAGE_ID

	# Install dependencies
	sudo $DOCKER exec -it $CONTAINER_NAME apt-get update
	sudo $DOCKER exec -it $CONTAINER_NAME apt-get -y install git
	sudo $DOCKER exec -it $CONTAINER_NAME apt-get -y install wget
	sudo $DOCKER exec -it $CONTAINER_NAME apt-get -y install python-tk
	sudo $DOCKER exec -it $CONTAINER_NAME mkdir -p $DCR_ROOT_PATH
	sudo $DOCKER exec -it $CONTAINER_NAME pip install future
	sudo $DOCKER exec -it $CONTAINER_NAME pip install Cython
	sudo $DOCKER exec -it $CONTAINER_NAME pip install scikit-image


}

function setup_maskrcnn(){


	sudo $DOCKER exec -it $CONTAINER_NAME rm -rf $DCR_ROOT_PATH/FastMaskRCNN
	sudo $DOCKER exec -it $CONTAINER_NAME git clone https://github.com/CharlesShang/FastMaskRCNN $DCR_ROOT_PATH/FastMaskRCNN

	sudo $DOCKER exec -it $CONTAINER_NAME mkdir -p $DCR_MASKRCNN_PATH/data/coco
	sudo $DOCKER exec -it $CONTAINER_NAME mkdir -p $DCR_MASKRCNN_PATH/data/pretrained_models
	sudo $DOCKER exec -it $CONTAINER_NAME mkdir -p $DCR_MASKRCNN_PATH/output/mask_rcnn


	if [[ -n ${RESNET50_DATASET_PATH} ]];then
		echo "Copying resnet_v1_50_2016_08_28.tar.gz in container"
		sudo $DOCKER cp $RESNET50_DATASET_PATH/resnet_v1_50_2016_08_28.tar.gz $CONTAINER_NAME:"$DCR_ROOT_PATH""FastMaskRCNN/data/pretrained_models"

	fi

	if [[ -n ${COCO_DATASET_PATH} ]];then
		echo "Copying COCO Dataset in container"
		sudo $DOCKER cp "$COCO_DATASET_PATH""/train2014.zip" $CONTAINER_NAME:"$DCR_ROOT_PATH""FastMaskRCNN/data/coco"
		sudo $DOCKER cp "$COCO_DATASET_PATH""/val2014.zip" $CONTAINER_NAME:"$DCR_ROOT_PATH""FastMaskRCNN/data/coco"
		sudo $DOCKER cp "$COCO_DATASET_PATH""/instances_train-val2014.zip" $CONTAINER_NAME:"$DCR_ROOT_PATH""FastMaskRCNN/data/coco"
		sudo $DOCKER cp "$COCO_DATASET_PATH""/person_keypoints_trainval2014.zip" $CONTAINER_NAME:"$DCR_ROOT_PATH""FastMaskRCNN/data/coco"
		sudo $DOCKER cp "$COCO_DATASET_PATH""/captions_train-val2014.zip" $CONTAINER_NAME:"$DCR_ROOT_PATH""FastMaskRCNN/data/coco"
	fi

	sudo $DOCKER cp $SCRIPT_NAME $CONTAINER_NAME:$DCR_ROOT_PATH/FastMaskRCNN/

}


function run_maskrcnn(){

	sudo $DOCKER exec $CONTAINER_NAME /bin/bash $DCR_ROOT_PATH/FastMaskRCNN/$SCRIPT_NAME

}



##### MAIN #####

# DOCKER
echo -n "Install/Update Docker (Ubuntu 16.04) [y/n] ? "
read input
if [[ $input == 'y' ]] || [[ $input == 'Y' ]];then
	install_docker
fi

# RESNET50 DATASET
echo -n "Enter resnet_v1_50_2016_08_28.tar.gz path starting with / [Example: /home/Downloads] (Press Enter to download): "
read input_resnet50
if [[ -n ${input_resnet50} ]];then
	RESNET50_DATASET_PATH=$input_resnet50
	echo "RESNET50 Dataset Path: $RESNET50_DATASET_PATH"
fi

# COCO DATASET
echo -n "Enter train2014.zip, val2014.zip, instances_train-val2014.zip, person_keypoints_trainval2014.zip and captions_train-val2014.zip  path starting with / [Example: /home/Downloads] (Press Enter to download): "
read input_coco
if [[ -n ${input_coco} ]];then
	COCO_DATASET_PATH=$input_coco
	echo "COCO Dataset Path: $COCO_DATASET_PATH"
fi

# SETUP DOCKER ENVIRONMENT
echo -n "Enter Tensorflow type to install [cpu/gpu] ? "
read input_tf
if [[ $input_tf == 'cpu' ]] || [[ $input_tf == 'CPU' ]] || [[ $input_tf == 'gpu' ]] || [[ $input_tf == 'GPU' ]];then
	TENSORFLOW_TYPE=$input_tf
fi
setup_docker_env $TENSORFLOW_TYPE

# SETUP MASKRCNN ENVIRONMENT
setup_maskrcnn

# RUN MASKRCNN
run_maskrcnn



