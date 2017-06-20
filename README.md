# MaskRCNN_Tensorflow_Docker

MaskRCNN (Tensorflow) using Docker.

  - Install docker
  - Install docker image of [Tensorflow] / [Tensorflow_gpu]
  - Create docker container "maskrcnn" from [Tensorflow] / [Tensorflow_gpu]
  - Clone [FastMaskRCNN] code in "maskrcnn" container
  - Download/copy datasets required for [FastMaskRCNN] code in "maskrcnn" container
  - Run [FastMaskRCNN] code:
    - Generate annotations
    - Train the network


# Installation
```sh
$ cd MaskRCNN_Tensorflow_Docker
$ ./install.sh


$ sudo docker exec -it maskrcnn bash
$ cd /home/maskrcnn/FastMaskRCNN
```


# Acknowledgment
- [FastMaskRCNN]
- [Tensorflow]
- [Nvidia-docker]




[//]: #
[FastMaskRCNN]: https://github.com/CharlesShang/FastMaskRCNN
[Tensorflow]: https://github.com/tensorflow/tensorflow/tree/master/tensorflow/tools/docker
[Tensorflow_gpu]: https://github.com/tensorflow/tensorflow/tree/master/tensorflow/tools/docker
[Nvidia-docker]: https://github.com/NVIDIA/nvidia-docker

