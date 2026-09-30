wslc run --rm -it ^
  --name ollama-qwen ^
  -p 11434:11434 ^
  -e OMP_NUM_THREADS=32 ^
  -e OLLAMA_NUM_PARALLEL=1 ^
  ollama/ollama:0.35.0

REM wslc exec -it ollama-qwen ollama run qwen3.8:27b
REM wslc exec -it ollama-qwen  /bin/bash
