https://medium.com/data-science-in-your-pocket/run-claude-code-with-local-llms-using-ollama-a97d2c2f2bd1
export ANTHROPIC_AUTH_TOKEN=ollama
export ANTHROPIC_BASE_URL=http://192.168.30.124:11434

claude --model glm-4.7-flash
claude --model qwen3-coder

FROM qwen3-coder-next
PARAMETER num_ctx 32768

ollama create qwen3-coder-next-32k -f Model
ollama run qwen3-coder-next-32k
claude --model qwen3-coder-next-32k

FROM qwen3.8:27b
PARAMETER num_ctx 32768
ollama create qwen3.8-32k -f Model
ollama run qwen3.8-32k

## CPU-only Ollama tuning

If the server has no GPU, keep the runtime pinned to CPU-only and avoid model thrashing by applying these Ollama-side settings:

```yaml
environment:
  - CUDA_VISIBLE_DEVICES=-1
  - OLLAMA_NUM_PARALLEL=1
  - OLLAMA_MAX_LOADED_MODELS=1
  - OLLAMA_KEEP_ALIVE=-1
```

For a direct container launch without GPU support:

```shell
docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
```


# With docker and gpu support

https://docs.ollama.com/docker

## Nvidia GPU 
. Configure the repository
```shell
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
| sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
| sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' \
| sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update

```

. Install the NVIDIA Container Toolkit packages
```shell
sudo apt-get install -y nvidia-container-toolkit
```

### Configure Docker to use Nvidia driver
```shell
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker
```

. start docker container 
```shell
docker run -d --gpus=all -v ollama:/root/.ollama -p 11434:11434 --name ollama ollama/ollama
```
. track gpu acitivity 
```shell
nvidia-smi -l 1
```
