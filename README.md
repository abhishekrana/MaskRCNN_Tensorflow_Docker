# MaskRCNN_Tensorflow_Docker

Integration of [FastMaskRCNN] + [Tensorflow] + [Nvidia-docker]. (Tested in Ubuntu 16.04)

  - Creates docker image "tensorflow_maskrcnn_gpu" using [Tensorflow_gpu] + [FastMaskRCNN] dependencies
  - Creates docker container "maskrcnn" from "tensorflow_maskrcnn_gpu"
  - Clones [FastMaskRCNN] code inside MaskRCNN_Tensorflow_Docker (host) and mounts it inside "maskrcnn" container at /home/maskrcnn/FastMaskRCNN (docker).
    (Host and Docker are now sharing the same code i.e. FastMaskRCNN. So code changes can be made at host side and code can be run inside the docker container)
  - Downloads/Copies datasets required for [FastMaskRCNN] inside FastMaskRCNN (host/docker)
  - Runs [FastMaskRCNN] code to:
    - Generate annotations
    - Train the network


# Prerequisite
  - Install Docker


# Installation
```sh
$ cd MaskRCNN_Tensorflow_Docker
$ ./install.sh

Training with CPU:
$ sudo nvidia-docker exec -it maskrcnn bash -c "cd /home/maskrcnn/FastMaskRCNN/; export CUDA_VISIBLE_DEVICES= ; python train/train.py"

Training with GPU:
$ sudo nvidia-docker exec -it maskrcnn bash -c "cd /home/maskrcnn/FastMaskRCNN/; python train/train.py"
```

# Notes
  - Using Tensorflow 1.1 (due to issue [#88] with TF 1.2)
  - Tested on
    - Ubuntu 	16.04.1	x86_64
    - Kernel	4.8.0-56-generic
    - Cuda 	  8.0.61
    - CuDNN	  5.1.10


# Acknowledgment
- [FastMaskRCNN]
- [Tensorflow]
- [Nvidia-docker]



[//]: #
[FastMaskRCNN]: https://github.com/CharlesShang/FastMaskRCNN
[Tensorflow]: https://github.com/tensorflow/tensorflow/tree/master/tensorflow/tools/docker
[Tensorflow_gpu]: https://github.com/tensorflow/tensorflow/tree/master/tensorflow/tools/docker
[Nvidia-docker]: https://github.com/NVIDIA/nvidia-docker
[#88]: https://github.com/CharlesShang/FastMaskRCNN/issues/88

