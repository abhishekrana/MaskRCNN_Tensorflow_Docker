# MaskRCNN_Tensorflow_Docker

Integration of [FastMaskRCNN] + [Tensorflow] + [Nvidia-docker].

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

# Notes

  - FasterMaskRCNN code (inside docker container) is present at /home/maskrcnn/
  - /home/maskrcnn (inside docker container) is persisted at MaskRCNN_Tensorflow_Docker/maskrcnn (host)


# Acknowledgment
- [FastMaskRCNN]
- [Tensorflow]
- [Nvidia-docker]




[//]: #
[FastMaskRCNN]: https://github.com/CharlesShang/FastMaskRCNN
[Tensorflow]: https://github.com/tensorflow/tensorflow/tree/master/tensorflow/tools/docker
[Tensorflow_gpu]: https://github.com/tensorflow/tensorflow/tree/master/tensorflow/tools/docker
[Nvidia-docker]: https://github.com/NVIDIA/nvidia-docker

