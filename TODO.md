## TODO

### check docker server host requirements within ./build and ./start scripts

### CUDA_HOME installation is required.
~~sudo apt install software-properties-common gnupg~~
~~sudo add-apt-repository contrib~~
~~sudo apt-key del 7fa2af80~~
~~wget https://developer.download.nvidia.com/compute/cuda/repos/debian11/x86_64/cuda-keyring_1.0-1_all.deb~~
~~sudo dpkg -i cuda-keyring_1.0-1_all.deb~~
~~sudo apt-get update~~
~~sudo apt-get --allow-releaseinfo-change update~~

**decided method**
docker pull nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04

~~### install requirements~~ 
~~pip install -r requirements.txt --upgrade~~
~~+ pip3 install torch torchvision torchaudio~~


### install deepspeed
pip install -U deepspeed

~~### launch with deepspeed~~
~~deepspeed --num_gpus=1 server.py --deepspeed --chat --model gpt-j-6B~~

### start script
to be corrected to be launched though nvidia-container-runtime

#### external volumes
externalize `/text-generation-webui/models

#### Enable SSH/SCP

~~### bitsandbytes GPU-ready~~
~~conda install pytorch pytorch-cuda -c pytorch -c nvidia~~
~~pip install accelerate~~
~~pip install transformers~~
~~pip install bitsandbytes~~
