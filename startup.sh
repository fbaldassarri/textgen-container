#!/usr/bin/env bash

su - textgen-user -c "~/miniconda3/envs/textgen/bin/python3.10 ~/text-generation-webui/server.py --listen --model facebook_opt-350m"

# python server.py --listen --model-menu --chat --xformers --verbose --auto-devices --rwkv-cuda-on --disk --gpu-memory 5800MiB --cpu-memory 60000MiB

# su - textgen-user -c "~deepspeed --num_gpus=1 server.py --deepspeed --chat --model gpt-j-6B"