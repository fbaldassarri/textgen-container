# Dockerfile to deploy a docker container with a ready-to-use text-generation-webui environment by oobabooga  

# docker pull nvidia/cuda:12.1.1-cudnn8-runtime-ubuntu22.04
ARG TAG=12.1.1-cudnn8-runtime-ubuntu22.04
FROM nvidia/cuda:$TAG 

RUN apt-get update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        git \
        locales \
        sudo \
        build-essential \
        dpkg-dev \
        wget \
        openssh-server \
        nano \
    && rm -rf /var/lib/apt/lists/*

# Setting up locales
RUN locale-gen en_US.UTF-8
ENV LANG en_US.UTF-8

# SSH exposition
EXPOSE 22/tcp
RUN service ssh start

# text-generation-webui port exposition
EXPOSE 7860/tcp

# Create user
RUN groupadd --gid 1020 textgen-group
RUN useradd -rm -d /home/textgen-home -s /bin/bash -G users,sudo,textgen-group -u 1000 textgen-user

# Update user password
RUN echo 'textgen-user:admin' | chpasswd

# Downloading miniconda3 
RUN su - textgen-user -c "wget https://repo.anaconda.com/miniconda/Miniconda3-py38_23.3.1-0-Linux-x86_64.sh "

# Installing miniconda3 
RUN su - textgen-user -c "cd ~/ \
                            && chmod +x Miniconda3-py38_23.3.1-0-Linux-x86_64.sh \
                            && ./Miniconda3-py38_23.3.1-0-Linux-x86_64.sh -b \
                            && rm -rf Miniconda3-py38_23.3.1-0-Linux-x86_64.sh " 

# Conda init
RUN su - textgen-user -c "cd ~/miniconda3/bin \
                            && ./conda init " 

# reload session within container build session
RUN su - textgen-user -c "source ~/.bashrc "

# Updating conda to the latest version
RUN su - textgen-user -c "cd ~/miniconda3/bin \
                            && ./conda update conda -y " 

# check eventual conda (base) env updates
RUN su - textgen-user -c "cd ~/miniconda3/bin \
                            && ./conda update --all -y " 

# Create virtalenv
RUN su - textgen-user -c "cd ~/miniconda3/bin \
                            && ./conda create -n textgen -y python=3.10.9 " 

# Adding ownership of /opt/conda to $user
# RUN chown -R textgen-user:users /opt/conda

# conda init bash for $user
# RUN su - textgen-user -c "conda init bash"

# conda activate textgen env
RUN su - textgen-user -c "echo \"conda activate textgen\" >> ~/.bashrc \
                            && echo \" \" >> ~/.bashrc "

# reload session within container build session
RUN su - textgen-user -c "source ~/.bashrc "

# Download latest oobabooga/text-generation-webui in text-generation-webui directory and compile it
ARG TEXTGENVER=v1.3.1
RUN su - textgen-user -c "git clone -b $TEXTGENVER https://github.com/oobabooga/text-generation-webui.git ~/text-generation-webui "

# Upgrading pip within textgen conda env
RUN su - textgen-user -c "~/miniconda3/bin/activate textgen \
                            && ~/miniconda3/envs/textgen/bin/pip install --upgrade pip "

# Install pip requirements
RUN su - textgen-user -c "~/miniconda3/bin/activate textgen \
                            && cd ~/text-generation-webui \
                            && ~/miniconda3/envs/textgen/bin/pip install -r requirements.txt --upgrade"

# Install additional requirements through pip 
RUN su - textgen-user -c "~/miniconda3/bin/activate textgen \
                            && ~/miniconda3/envs/textgen/bin/pip install torch xformers "

# Install pytorchvision and torchaudio through pip (not recommended as this could break compatibility with xformers, be careful)
# RUN su - textgen-user -c "~/miniconda3/bin/activate textgen \
#                           && ~/miniconda3/envs/textgen/bin/pip install torchvision torchaudio "

# Resolving "The installed version of bitsandbytes was compiled without GPU support." issue
RUN su - textgen-user -c "~/miniconda3/bin/activate textgen \
                            && ~/miniconda3/bin/conda install pytorch pytorch-cuda -c pytorch -c nvidia -y -n textgen \
                            && ~/miniconda3/envs/textgen/bin/pip install accelerate \
                            && ~/miniconda3/envs/textgen/bin/pip install transformers \
                            && ~/miniconda3/envs/textgen/bin/pip install bitsandbytes "

# Install deepspeed and its pre-requirements 
ARG DISTRONAME=ubuntu
ARG DISTROVERSION=2204
ARG DISTROARCH=x86_64

RUN wget https://developer.download.nvidia.com/compute/cuda/repos/$DISTRONAME$DISTROVERSION/$DISTROARCH/cuda-keyring_1.0-1_all.deb \
    && dpkg -i cuda-keyring_1.0-1_all.deb \
    && apt update \
    && DEBIAN_FRONTEND="noninteractive" apt-get install -y --no-install-recommends \
        linux-headers-$(uname -r) \
        cuda \
        nvidia-gds \
        # nvidia-cuda-toolkit \
        # nvidia-cuda-toolkit-gc \
        #libcuda \
    && rm -rf /var/lib/apt/lists/*

RUN su - textgen-user -c "~/miniconda3/bin/activate textgen \
                          && ~/miniconda3/condabin/conda install -c conda-forge -y mpi4py mpich -n textgen \
                          && ~/miniconda3/envs/textgen/bin/pip install -U deepspeed "

# Download default testing model
RUN su - textgen-user -c "cd ~/text-generation-webui \ 
                            && ~/miniconda3/envs/textgen/bin/python3.10 download-model.py facebook/opt-350m "

# ENV for NVIDIA / CUDA to exclude graphics,video,display capabilities as they are not needed
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=7.5 driver>=450"

# Preparing for login
ENV HOME /home/textgen-home
WORKDIR ${HOME}/text-generation-webui
USER textgen-user

COPY startup.sh .
# CMD ["/bin/bash","-c","./startup.sh"]
CMD ["/bin/bash"]
