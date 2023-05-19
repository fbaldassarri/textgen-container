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

# conda activate alpacacpp env
RUN su - textgen-user -c "echo \"conda activate textgen\" >> ~/.bashrc "

# Download latest oobabooga/text-generation-webui in text-generation-webui directory and compile it
RUN su - textgen-user -c "git clone https://github.com/oobabooga/text-generation-webui.git ~/text-generation-webui \
                            && cd ~/text-generation-webui "

# Install pip requirements
RUN su - textgen-user -c "cd ~/text-generation-webui \ 
                            && pip install -r requirements.txt "

# Download default testing model
RUN su - textgen-user -c "cd ~/text-generation-webui \ 
                            && python download-model.py facebook/opt-6.7b "

# Preparing for login
ENV HOME /home/textgen-home
WORKDIR ${HOME}/text-generation-webui
USER textgen-user

# Installing and Lanching text-generation-webui
CMD ["/bin/bash", "-c", "~/alpaca.cpp/python", "server.py"] 
