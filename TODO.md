## TODO

### check docker server host requirements within ./build and ./start scripts

### CUDA_HOME installation is required.

### install requirements 
pip install -r requirements.txt --upgrade
+ pip3 install torch torchvision torchaudio


### install deepspeed
conda install -c conda-forge mpi4py mpich
pip install -U deepspeed

### launch with deepspeed
deepspeed --num_gpus=1 server.py --deepspeed --chat --model gpt-j-6B

### start script
to be corrected to be launched though nvidia-container-runtime

#### external volumes
externalize `/text-generation-webui/models
