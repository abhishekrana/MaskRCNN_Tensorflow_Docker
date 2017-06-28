#!/usr/bin/python3

### IMPORTS ###
import subprocess
import os


### FUNCTIONS ###

def setup_docker_image(doc_repo_name, docker_file):
    print('### setup_docker_image ###')

    # Run non-GPU container using
    # subprocess.call('sudo docker pull gcr.io/tensorflow/tensorflow', shell=True)


    # Install nvidia-docker and nvidia-docker-plugin
    subprocess.call('wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.1/nvidia-docker_1.0.1-1_amd64.deb', shell=True)
    subprocess.call('sudo dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb', shell=True)
    subprocess.call('sudo nvidia-docker run --rm nvidia/cuda nvidia-smi', shell=True)


    # Create Docker Image
    cmd='sudo ' + DOCKER + ' rm -f ' + container_name
    print('cmd', cmd)
    subprocess.call(cmd, shell=True)

    cmd='sudo ' + DOCKER + ' rmi ' +  doc_repo_name
    print('cmd', cmd)
    subprocess.call(cmd , shell=True)

    print("Generating Docker image using $docker_file ")
    cmd='sudo ' + DOCKER + ' build -f ' + docker_file + ' -t ' + doc_repo_name + ' .'
    print('cmd', cmd)
    subprocess.call(cmd, shell=True)



def setup_docker_container(doc_repo_name, container_name, host_project_path, docker_project_path):
    print('### setup_docker_container ###')

    cmd='sudo ' + DOCKER + ' rm -f ' + container_name
    print('cmd', cmd)
    subprocess.call(cmd, shell=True)

    cmd='mkdir -p ' + host_project_path
    print('cmd', cmd)
    subprocess.call(cmd, shell=True)

    cmd='sudo ' + DOCKER + ' run -d -v ' + host_project_path + ':' + docker_project_path + ' --name ' + container_name + ' ' + doc_repo_name
    print('cmd', cmd)
    subprocess.call(cmd, shell=True)


def setup_dot_files(container_name, user):

    cmd_cont='git clone https://github.com/VundleVim/Vundle.vim.git ~/.vim/bundle/Vundle.vim'
    cmd_container(container_name, cmd_cont)

    cmd='sudo ' + DOCKER + ' cp dotfiles/vim/.vimrc ' + container_name + ':/home/' + user
    print('cmd', cmd)
    subprocess.call(cmd, shell=True)

    cmd_cont='vim +BundleInstall +qall'
    cmd_container(container_name, cmd_cont)




# Creating directories outside container due to 'permission denied' issue
def setup_maskrcnn(container_name, project_name, repo_link, repo_name, resnet50_dataset_path=None, coco_dataset_path=None, delete_old_repo=None):
    print('### setup_maskrcnn ###')

    cd_root_dir='cd ' + project_name + '/' + repo_name + '; '
    print('cd_root_dir', cd_root_dir)

    if delete_old_repo is 'y':
        cmd_cont='rm -rf ' + project_name + '/*'
        cmd_container(container_name, cmd_cont)
        #cmd_host(cmd_cont)


    # Don't remove project_name directory as it is mounted inside docker
    cmd_cont='git clone ' + repo_link + ' ' + project_name + '/' + repo_name
    #cmd_container(container_name, cmd_cont)
    cmd_host(cmd_cont)


    ### Prerequisite
    cmd_cont=cd_root_dir + 'cd libs/datasets/pycocotools; make'
    cmd_container(container_name, cmd_cont)

    cmd_cont=cd_root_dir + 'mkdir -p data/coco; mkdir -p data/pretrained_models; mkdir -p output/mask_rcnn'
    # cmd_container(container_name, cmd_cont)
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
    print('cmd: ', cmd)
    subprocess.call(cmd, shell=True)

def cmd_container(container_name, cmd_cont):

    print('cmd_cont : ', cmd_cont)
    cmd='sudo '+ DOCKER + ' exec -it ' + container_name + ' bash -c "' + cmd_cont + '"'
    print('cmd      : ', cmd)
    subprocess.call(cmd, shell=True)


### MAIN ###


### GLOBALS
DOCKER="nvidia-docker"

# Also modify in .dockerignore
project_name='MRCNN'
dataset_name='Dataset'

# Also modify in Dockerfile
user='user'

docker_file         = 'dockerfiles/Dockerfile_gpu_tf1.1'
tf_version          = docker_file.split("_")
doc_repo_name           = user+'/tensorflow_gpu_'+project_name.lower()
container_name      = user+'-'+project_name.lower()+'_'+tf_version[-1]
host_project_path   = os.path.join(os.getcwd(), project_name)
docker_project_path = os.path.join('/home/'+user+'/', project_name)
repo_link           = 'https://github.com/CharlesShang/FastMaskRCNN'
repo_name           =  repo_link.split("/")[-1]


### USER INPUT
resnet50_dataset_path=None
coco_dataset_path=None

resnet50_dataset_path = input('Enter resnet_v1_50_2016_08_28.tar.gz ABSOLUTE PATH starting with / [Example: /home/Downloads] (or Press Enter to download): ')
print('Resnet50 dataset path: ', resnet50_dataset_path)


coco_dataset_path = input('Enter train2014.zip, val2014.zip, instances_train-val2014.zip, person_keypoints_trainval2014.zip and \ncaptions_train-val2014.zip ABSOLUTE PATH starting with / [Example: /home/Downloads] (or Press Enter to download): ')
print('COCO dataset path: ', coco_dataset_path)

delete_old_repo = input('Delete old repository (' + os.getcwd() + '/' +  project_name + '/' + repo_name + '): ')
print('Delete: ', coco_dataset_path)


### FUNCTIONS

# DOCKER
setup_docker_image(doc_repo_name, docker_file)
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
print('Repo name            : ', doc_repo_name)
print('Container name       : ', container_name)
print('Host project path    : ', host_project_path)
print('Docker project path  : ', docker_project_path)
print('Repository           : ', repo_link)
print('Repository Name      : ', repo_name)

print('\nCommands:')
print('sudo ' + DOCKER + ' exec -it ' + container_name + ' bash \n')
print('##################################################\n')


