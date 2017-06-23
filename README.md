# MaskRCNN_Tensorflow_Docker

Integration of [FastMaskRCNN] + [Tensorflow] + [Nvidia-docker].

  - Creates docker image "tensorflow_maskrcnn_gpu" using [Tensorflow_gpu] + [FastMaskRCNN] dependencies
  - Creates docker container "maskrcnn" from "tensorflow_maskrcnn_gpu"
  - Clones [FastMaskRCNN] code inside MaskRCNN_Tensorflow_Docker (host) and mounts it inside "maskrcnn" at /home/maskrcnn/FastMaskRCNN (docker).
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

Enter docker container:
$ sudo nvidia-docker exec -it maskrcnn bash
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

