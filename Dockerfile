# Dockerfile to deploy a docker container with a ready-to-use text-generation-webui environment by oobabooga  

# docker pull continuumio/miniconda3:latest
ARG TAG=latest
FROM continuumio/miniconda3:$TAG 

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

# set a new hostname
# RUN hostnamectl set-hostname textgen-container 

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

# Updating conda to the latest version
RUN conda update conda -y

# Create virtalenv
RUN conda create -n textgen -y python=3.10.9

# Adding ownership of /opt/conda to $user
RUN chown -R textgen-user:users /opt/conda

# conda init bash for $user
RUN su - textgen-user -c "conda init bash"

# conda activate textgen env
RUN su - textgen-user -c "echo \"conda activate textgen\" >> ~/.bashrc "

# reload session within container build session
RUN su - textgen-user -c "source ~/.bashrc "

# Download latest oobabooga/text-generation-webui in text-generation-webui directory and compile it
RUN su - textgen-user -c "git clone https://github.com/oobabooga/text-generation-webui.git ~/text-generation-webui "

# Install pip upgrade
RUN su - textgen-user -c "/opt/conda/envs/textgen/bin/pip install --upgrade pip "

# Install pip requirements
RUN su - textgen-user -c "cd ~/text-generation-webui \ 
                            && /opt/conda/envs/textgen/bin/pip install -r requirements.txt --upgrade"

# Install xformers through pip 
RUN su - textgen-user -c "/opt/conda/envs/textgen/bin/pip install xformers "

# Install pytorchvision and torchaudio through pip (not recommended as this could break compatibility with xformers, be careful)
# RUN su - textgen-user -c "/opt/conda/envs/textgen/bin/pip install torchvision torchaudio"

# Install deepspeed (and its requirements)
# RUN su - textgen-user -c "conda install -c conda-forge -y mpi4py mpich \
#                              && /opt/conda/envs/textgen/bin/pip install -U deepspeed"

# Download default testing model
RUN su - textgen-user -c "cd ~/text-generation-webui \ 
                            && /opt/conda/envs/textgen/bin/python3.10 download-model.py EleutherAI/gpt-j-6b "

# Preparing for login
ENV HOME /home/textgen-home
WORKDIR ${HOME}/text-generation-webui
USER textgen-user

# Installing and Lanching text-generation-webui
# CMD ["/bin/bash", "-c", "/opt/conda/envs/textgen/bin/python3.10", "~/text-generation-webui/server.py", "--listen"] 
# CMD ["/bin/bash", "-c", "~/text-generation-webui/deepspeed", "--num_gpus=1", "server.py", "--deepspeed", "--chat", "--model", "gpt-j-6B"] 


COPY startup.sh .
# CMD ["/bin/bash","-c","./startup.sh"]
CMD ["/bin/bash"]
