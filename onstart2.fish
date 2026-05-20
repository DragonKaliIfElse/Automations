#!/usr/bin/env fish

# No Fish, usamos um bloco 'begin ... end' para redirecionar toda a saída 
# de logs do script (stdout e stderr) para o arquivo de depuração.
echo "=== Iniciando configuração do llama.cpp ==="

# 1. Instalar dependências de compilação e CUDA Toolkit
# O Fish pode encadear comandos de sucesso com 'and' em vez de '&&'
apt-get update -y
and apt-get install -y git build-essential cmake curl wget nvidia-cuda-toolkit

# 2. Clonar e compilar llama.cpp com suporte a CUDA
cd /workspace
if not test -d "llama.cpp"
    git clone https://github.com/ggml-org/llama.cpp.git
end
cd llama.cpp

echo "Compilando llama.cpp com suporte CUDA..."
cmake -B build -DGGML_CUDA=ON

# A substituição de comando no Fish usa parênteses () em vez de $()
cmake --build build --config Release -j (nproc)
echo "Compilação finalizada."

# 3. Baixar o modelo (Qwen2.5 1.5B Instruct)
# A declaração de variáveis no Fish utiliza o comando 'set'
set MODEL_REPO "unsloth/Qwen3.6-35B-A3B-GGUF"
set MODEL_FILE "Qwen3.6-35B-A3B-UD-Q5_K_XL.gguf"

# 4. Iniciar o servidor em segundo plano
echo "Iniciando servidor llama.cpp..."

# O Fish 3.0+ suporta &> nativamente para redirecionar stdout e stderr combinados
nohup ./build/bin/llama-server \
    --host 0.0.0.0 \
    --port 8080 \
    --hf-repo "$MODEL_REPO" \
    --hf-file "$MODEL_FILE" \
    --n-gpu-layers 25 \
    --ctx-size 4096 \
    --metrics \
    --cont-batching \
    --cache-reuse 256 \
    --log-disable \
    &> /workspace/llama-server.log &

# Para acessar o PID do processo em background, o Fish utiliza $last_pid em vez de $!
echo "Servidor iniciado em background (PID: $last_pid)."
echo "Verifique /workspace/llama-server.log para status."
echo "=== Setup concluído ==="
