# Model Information

This document provides information about models compatible with METALlama.cpp and recommendations for optimal performance.

## Default Model

METALlama.cpp comes configured to use:

- **Model**: Llama-3.2-1B-Instruct.Q4_K_M.gguf
- **Source**: QuantFactory/Llama-3.2-1B-Instruct-GGUF on Hugging Face
- **Size**: Approximately 1.5GB
- **Quantization**: Q4_K_M (4-bit quantization with medium precision)

This small model provides a good balance between performance and resource usage, making it ideal for getting started on most Macs.

## Recommended Models

For better results, consider these alternatives:

### Balanced Performance

- **Llama-3.1-8B-Instruct** (Q4_K_M or Q5_K_M variants)
- Size: ~6-8GB
- Good for most general purpose tasks
- Works well on M1/M2 Macs with 16GB+ RAM

### High Performance

- **Llama-3.1-70B-Instruct** (Q4_K_M variant)
- Size: ~40GB
- Excellent quality responses
- Requires M1 Pro/Max/Ultra or M2 Pro/Max/Ultra with 32GB+ RAM

## Changing Models

To change the model:

1. Download your preferred model from [Hugging Face](https://huggingface.co/)
2. Place it in `~/METALlama.cpp/models/`
3. Update the model path in `~/.config/llama_mps_server/run_server.sh`
4. Restart the service: `~/llama-service.sh restart`

## Optimizing Model Performance

### Metal/MPS Layers

The installer configures 1 GPU layer by default. For better performance:

- 1 GPU layer: Most compatible, works on all Macs
- 4-8 GPU layers: Good balance for most models
- 32+ GPU layers: Best for larger models on newer Macs

To adjust:
1. Edit `~/.config/llama_mps_server/run_server.sh`
2. Change `--n-gpu-layers 1` to your preferred number
3. Restart the service

### Context Size

The default context size is 8192 tokens. For using longer contexts:

1. Edit `~/.config/llama_mps_server/run_server.sh`
2. Change `--ctx-size 8192` to a larger value (e.g., 16384)
3. Restart the service

Note that larger context sizes require more memory.

## Troubleshooting Model Issues

If your model doesn't load:

1. Check that the model file exists in the specified path
2. Verify your Mac has sufficient RAM for the model
3. Try reducing the number of GPU layers
4. Try a smaller model or different quantization level

Logs at `~/Desktop/llama_server_logs/` will provide specific error information.