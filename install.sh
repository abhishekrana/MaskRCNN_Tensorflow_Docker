#!/bin/bash

# Install Docker

DCR_ROOT_PATH=/home/maskrcnn/
DCR_MASKRCNN_PATH=$DCR_ROOT_PATH/FastMaskRCNN/
CONTAINER_NAME=maskrcnn

### DOCKER CE
# Installs/updated Docker CE
function install_docker(){

	echo "Installing/Updating Docker"
	sudo apt-get remove docker docker-engine

	sudo apt-get update

	# Recommended extra packages for Trusty 14.04
	sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual

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

	# Run non-GPU container using
	sudo docker pull gcr.io/tensorflow/tensorflow

	# TODO
	# For GPU support install NVidia drivers (ideally latest) and nvidia-docker. Run using
	#nvidia-docker run -it -p 8888:8888 gcr.io/tensorflow/tensorflow:latest-gpu

	#image_id=gcr.io/tensorflow/tensorflow
	image_id=5f86ff0436e8

	sudo docker stop $CONTAINER_NAME
	sudo docker rm $CONTAINER_NAME
	sudo docker run -d --name $CONTAINER_NAME $image_id

	sudo docker exec -it $CONTAINER_NAME apt-get update
	sudo docker exec -it $CONTAINER_NAME apt-get -y install git
	sudo docker exec -it $CONTAINER_NAME apt-get -y install wget
	sudo docker exec -it $CONTAINER_NAME apt-get -y install python-tk
	sudo docker exec -it $CONTAINER_NAME mkdir -p $DCR_ROOT_PATH


}

function setup_maskrcnn(){

	script_name=maskRCNN.sh

	sudo docker exec -it $CONTAINER_NAME rm -rf $DCR_ROOT_PATH/FastMaskRCNN
	sudo docker exec -it $CONTAINER_NAME git clone https://github.com/CharlesShang/FastMaskRCNN $DCR_ROOT_PATH/FastMaskRCNN

	sudo docker exec -it $CONTAINER_NAME mkdir -p $DCR_MASKRCNN_PATH/data/coco
	sudo docker exec -it $CONTAINER_NAME mkdir -p $DCR_MASKRCNN_PATH/data/pretrained_models
	sudo docker exec -it $CONTAINER_NAME mkdir -p $DCR_MASKRCNN_PATH/output/mask_rcnn


	if [[ -n ${RESNET50_DATASET_PATH} ]];then
		echo "Copying resnet_v1_50_2016_08_28.tar.gz in container"
		sudo docker cp $RESNET50_DATASET_PATH/resnet_v1_50_2016_08_28.tar.gz $CONTAINER_NAME:"$DCR_ROOT_PATH""FastMaskRCNN/data/pretrained_models"

	fi

	if [[ -n ${COCO_DATASET_PATH} ]];then
		echo "Copying COCO Dataset in container"
		sudo docker cp "$COCO_DATASET_PATH""/train2014.zip" $CONTAINER_NAME:"$DCR_ROOT_PATH""FastMaskRCNN/data/coco"
		sudo docker cp "$COCO_DATASET_PATH""/val2014.zip" $CONTAINER_NAME:"$DCR_ROOT_PATH""FastMaskRCNN/data/coco"
		sudo docker cp "$COCO_DATASET_PATH""/instances_train-val2014.zip" $CONTAINER_NAME:"$DCR_ROOT_PATH""FastMaskRCNN/data/coco"
		sudo docker cp "$COCO_DATASET_PATH""/person_keypoints_trainval2014.zip" $CONTAINER_NAME:"$DCR_ROOT_PATH""FastMaskRCNN/data/coco"
		sudo docker cp "$COCO_DATASET_PATH""/captions_train-val2014.zip" $CONTAINER_NAME:"$DCR_ROOT_PATH""FastMaskRCNN/data/coco"
	fi

	sudo docker cp $script_name $CONTAINER_NAME:$DCR_ROOT_PATH/FastMaskRCNN/

}


function run_maskrcnn(){

	sudo docker exec $CONTAINER_NAME /bin/bash $DCR_ROOT_PATH/FastMaskRCNN/$script_name

}

##### MAIN #####

# DOCKER
echo -n "Install/Update Docker (y/n) ? "
read input
if [[ $input == 'y' ]] || [[ $input == 'Y' ]];then
	echo "dd"
	install_docker
fi

# RESNET50 DATASET
echo -n "Enter resnet_v1_50_2016_08_28.tar.gz path starting from / [Eg /home/Downloads] (Press Enter to download): "
read input_resnet50
if [[ -n ${input_resnet50} ]];then
	RESNET50_DATASET_PATH=$input_resnet50
	echo "RESNET50 Dataset Path: $RESNET50_DATASET_PATH"
fi

# COCO DATASET
echo -n "Enter train2014.zip, val2014.zip, instances_train-val2014.zip, person_keypoints_trainval2014.zip and captions_train-val2014.zip  path starting from / [Eg: /home/Downloads] (Press Enter to download): "
read input_coco
if [[ -n ${input_coco} ]];then
	COCO_DATASET_PATH=$input_coco
	echo "COCO Dataset Path: $COCO_DATASET_PATH"
fi

# DOCKER ENVIRONMENT
setup_docker_env

# MASKRCNN ENVIRONMENT
setup_maskrcnn

# RUN MASKRCNN
run_maskrcnn

