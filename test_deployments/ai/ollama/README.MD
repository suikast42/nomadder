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
