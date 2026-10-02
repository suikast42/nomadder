docker run --rm -d \
  --name ollama \
  --gpus all \
  -v ./ai/ollama_data:/root/.ollama \
  -p 11434:11434 \
  -e OMP_NUM_THREADS=32 \
  -e OLLAMA_NUM_PARALLEL=1 \
  ollama/ollama:0.35.0

# 2. Trigger model download & run session inside the container
#docker exec -it ollama-server ollama run qwen3.8:27b
#
#First
## Add NVIDIA Container Toolkit repository
#curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
#curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
#  sed 's#deb [^ ]* #&[signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] #' | \
#  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

## Install toolkit & restart Docker
#sudo apt-get update
#sudo apt-get install -y nvidia-container-toolkit
#sudo systemctl restart docker
