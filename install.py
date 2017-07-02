#!/usr/bin/python3

### IMPORTS ###
import subprocess
import os


### FUNCTIONS ###

# Installs/updated Docker CE
def install_docker():

	print('Installing/Updating Docker')

	cmd_host('sudo apt-get remove docker docker-engine')

	cmd_host('sudo apt-get update')

	# Recommended extra packages for Trusty 14.04
	#cmd_host('sudo apt-get -y install linux-image-extra-$(uname -r) linux-image-extra-virtual')

	# Install packages to allow apt to use a repository over HTTPS
	cmd_host('sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common')

	# Add Docker’s official GPG key
	cmd_host('curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -')

	# Set up the stable repository
	cmd_host('sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"')

	# Install/Update docker
	cmd_host('sudo apt-get update')
	cmd_host('sudo apt-cache policy docker-ce')
	cmd_host('sudo apt-get -y install docker-ce')
	#sudo apt-get -y install docker-ce=<VERSION>

	# Test installation
	cmd_host('sudo docker run hello-world')


def setup_docker_image(doc_repo_name, docker_file, gpu):
    print('### setup_docker_image ###')

    if gpu is 0:
        # Run non-GPU container using
        cmd_host('sudo docker pull gcr.io/tensorflow/tensorflow')

    if gpu is 1:
        # Install nvidia-docker and nvidia-docker-plugin
        cmd_host('wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb')
        cmd_host('sudo dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb')
        cmd_host('sudo nvidia-docker run --rm nvidia/cuda nvidia-smi')

    # Create Docker Image
    cmd_host('sudo ' + DOCKER + ' rm -f ' + container_name)

    cmd_host('sudo ' + DOCKER + ' rmi ' +  doc_repo_name)

    print("Generating Docker image using $docker_file ")
    cmd_host('sudo ' + DOCKER + ' build -f ' + docker_file + ' -t ' + doc_repo_name + ' .')



def setup_docker_container(doc_repo_name, container_name, host_project_path, docker_project_path):
    print('### setup_docker_container ###')

    cmd_host('sudo ' + DOCKER + ' rm -f ' + container_name)
    cmd_host('mkdir -p ' + host_project_path)

    cmd_host('sudo ' + DOCKER + ' run -dit -v ' + host_project_path + ':' + docker_project_path + ' --name ' + container_name + ' ' + doc_repo_name + ' /bin/bash')


def setup_dot_files(container_name, user):
    print('### setup_dot_files ###')

    cmd_cont='git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim'
    cmd_container(container_name, cmd_cont)

    cmd_host('sudo ' + DOCKER + ' cp dotfiles/vim/.vimrc ' + container_name + ':/home/' + user)

    cmd_cont='vim +BundleInstall +qall'
    cmd_container(container_name, cmd_cont)


# Creating directories outside container due to 'permission denied' issue (as docker user is root)
def setup_maskrcnn(container_name, project_name, repo_link, repo_name, resnet50_dataset_path=None, coco_dataset_path=None, delete_old_repo=None):
    print('### setup_maskrcnn ###')

    cd_root_dir='cd ' + project_name + '/' + repo_name + '; '
    print('cd_root_dir', cd_root_dir)

    if delete_old_repo is 'y':
        cmd_cont='rm -rf ' + project_name + '/*'
        cmd_container(container_name, cmd_cont)


    # Don't remove project_name directory as it is mounted inside docker
    cmd_cont='git clone ' + repo_link + ' ' + project_name + '/' + repo_name
    cmd_host(cmd_cont)


    ### Prerequisite
    cmd_cont=cd_root_dir + 'cd libs/datasets/pycocotools; make'
    cmd_container(container_name, cmd_cont)

    cmd_cont=cd_root_dir + 'mkdir -p data/coco; mkdir -p data/pretrained_models; mkdir -p output/mask_rcnn'
    cmd_host(cmd_cont)


    # RESNET
    cwd=cd_root_dir + 'cd data/pretrained_models/; '
    print('resnet50_dataset_path', resnet50_dataset_path)
    if resnet50_dataset_path:
        cmd_host(cwd + 'cp -v ' + resnet50_dataset_path + '/resnet_v1_50_2016_08_28.tar.gz .')
    cmd_host(cwd + 'wget -nc http://download.tensorflow.org/models/resnet_v1_50_2016_08_28.tar.gz; tar -xzvf resnet_v1_50_2016_08_28.tar.gz')


    # COCO
    cwd=cd_root_dir + 'cd data/coco/; '
    print('coco_dataset_path', coco_dataset_path)
    if coco_dataset_path:
        cmd_host(cwd + 'cp ' + coco_dataset_path + '/train2014.zip .')
        cmd_host(cwd + 'cp ' + coco_dataset_path + '/val2014.zip .')
        cmd_host(cwd + 'cp ' + coco_dataset_path + '/instances_train-val2014.zip .')
        cmd_host(cwd + 'cp ' + coco_dataset_path + '/person_keypoints_trainval2014.zip .')
        cmd_host(cwd + 'cp ' + coco_dataset_path + '/captions_train-val2014.zip .')

    cmd_host(cwd + 'wget -nc http://msvocds.blob.core.windows.net/coco2014/train2014.zip; unzip train2014.zip')
    cmd_host(cwd + 'wget -nc http://msvocds.blob.core.windows.net/coco2014/val2014.zip; unzip val2014.zip')
    cmd_host(cwd + 'wget -nc http://msvocds.blob.core.windows.net/annotations-1-0-3/instances_train-val2014.zip; unzip instances_train-val2014.zip')
    cmd_host(cwd + 'wget -nc http://msvocds.blob.core.windows.net/annotations-1-0-3/person_keypoints_trainval2014.zip; unzip person_keypoints_trainval2014.zip')
    cmd_host(cwd + 'wget -nc http://msvocds.blob.core.windows.net/annotations-1-0-3/captions_train-val2014.zip; unzip captions_train-val2014.zip')


    ### Compile libraries
    cmd_container(container_name, cd_root_dir + 'cd libs; make')



def generate_annotations_maskrcnn(project_name, repo_name):

    print('### generate_annotations_maskrcnn ###')

    cd_root_dir='cd ' + project_name + '/' + repo_name + '; '
    print('cd_root_dir', cd_root_dir)

    cmd_container(container_name, cd_root_dir + 'python download_and_convert_data.py')


def train_maskrcnn(container_name, project_name, repo_name):

    print('### train_maskrcnn ###')

    cd_root_dir='cd ' + project_name + '/' + repo_name + '; '

    # print('Command for training with CPU')
    # cmd_container(container_name, cd_root_dir + 'export CUDA_VISIBLE_DEVICES= ; python train/train.py ')

    print('Command for training with GPU')
    cmd_container(container_name, cd_root_dir + 'python train/train.py ')



### HELPER FUNCTIONS

def cmd_host(cmd):
    print('$ cmd: ', cmd)
    subprocess.call(cmd, shell=True)

def cmd_container(container_name, cmd_cont):

    print('$ cmd_cont : ', cmd_cont)
    cmd='sudo '+ DOCKER + ' exec -it ' + container_name + ' bash -c "' + cmd_cont + '"'
    print('$ cmd      : ', cmd)
    subprocess.call(cmd, shell=True)


### MAIN ###


### GLOBALS

# CPU
#gpu=0
#DOCKER="nvidia"
#docker_file         = 'dockerfiles/Dockerfile_cpu_tf1.1'

# GPU
gpu=1
DOCKER              = "nvidia-docker"
docker_file         = 'dockerfiles/Dockerfile_gpu_tf1.1'

# Also modify in .dockerignore
project_name='MRCNN'
dataset_name='Dataset'

# Also modify in Dockerfile
user='user'

tf_version          = docker_file.split("_")
doc_repo_name       = user+'/tensorflow_gpu_'+project_name.lower()
container_name      = user+'-'+project_name.lower()+'_'+tf_version[-1]
host_project_path   = os.path.join(os.getcwd(), project_name)
docker_project_path = os.path.join('/home/'+user+'/', project_name)
repo_link           = 'https://github.com/CharlesShang/FastMaskRCNN'
repo_name           = repo_link.split("/")[-1]


### USER INPUT
resnet50_dataset_path=None
coco_dataset_path=None

resnet50_dataset_path = input('Enter resnet_v1_50_2016_08_28.tar.gz ABSOLUTE PATH starting with / [Example: /home/Downloads] (or Press Enter to download): ')
print('Resnet50 dataset path: ', resnet50_dataset_path)


coco_dataset_path = input('\nEnter train2014.zip, val2014.zip, instances_train-val2014.zip, person_keypoints_trainval2014.zip and \ncaptions_train-val2014.zip ABSOLUTE PATH starting with / [Example: /home/Downloads] (or Press Enter to download): ')
print('COCO dataset path: ', coco_dataset_path)

delete_old_repo = input('\nDelete old repository (' + os.getcwd() + '/' +  project_name + '/' + repo_name + ') [y/n]: ')
print('Delete: ', coco_dataset_path)


### FUNCTIONS

# DOCKER
#install_docker()
setup_docker_image(doc_repo_name, docker_file, gpu)
setup_docker_container(doc_repo_name, container_name, host_project_path, docker_project_path)
setup_dot_files(container_name, user)

# MaskRCNN
setup_maskrcnn(container_name, project_name, repo_link, repo_name, resnet50_dataset_path, coco_dataset_path, delete_old_repo)
generate_annotations_maskrcnn(project_name, repo_name)
train_maskrcnn(container_name, project_name, repo_name)


# SUMMARY
print('\n##################################################')
print('Project name         : ', project_name)
print('Docker file          : ', docker_file)
print('Docker repo name     : ', doc_repo_name)
print('Container name       : ', container_name)
print('Host project path    : ', host_project_path)
print('Docker project path  : ', docker_project_path)
print('Repository           : ', repo_link)
print('Repository Name      : ', repo_name)
print('GPU                  : ', gpu)

if gpu is 1:
    print('\nTo disable GPU (inside docker): \nexport CUDA_VISIBLE_DEVICES=')

print('\nTo access docker:')
print('sudo ' + DOCKER + ' exec -it ' + container_name + ' bash ')

print('\nTo train:')
print('sudo nvidia-docker exec -it user-mrcnn_tf1.1 bash -c "cd MRCNN/FastMaskRCNN; python train/train.py" \n')

print('##################################################')


