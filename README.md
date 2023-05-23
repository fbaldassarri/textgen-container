# Dockerfile script to build a docker container for oobabooga/text-generation-webui with conda-ready environments 
For low GPU VRAM-capable machines

## Requirements

1. You have gnu/linux or macOS
2. You have at least 64 GB of RAM
3. You have docker engine installed
4. You have an NVIDIA gpu with >=6GB VRAM and supporting CUDA >=7.5

## Preliminary steps

Please, make sure you have fully installed/configure the NVIDIA Container Toolkit checking [this guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html).

## To build the container 

```bash
chmod +x build start stop rm
```

```bash
./build
```

## To start the container 

```bash
./start
```

## To connect locally

```bash
docker container attach alpaca-cpp-container
```

## To stop the container 

```bash
./stop
```

## To remove the container 

```bash
./rm
```

### Note

* Deepspeed does not correctly compile
