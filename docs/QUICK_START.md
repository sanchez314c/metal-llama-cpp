# Quick Start Guide

Get METALlama.cpp running in 5 minutes with this quick start guide.

## Prerequisites Check

Verify your system meets requirements:
```bash
# Check macOS version (requires 11.0+)
sw_vers | grep "ProductVersion:" | cut -d' ' -f3

# Check for Intel Mac
uname -m | grep "x86_64"

# Check for AMD GPU
system_profiler SPDisplaysDataType | grep -i "amd\|radeon"

# Check available RAM
sysctl hw.memsize | awk '{print $2/1024/1024/1024 "GB"}'
```

## One-Command Installation

### Standard Install
```bash
# Clone and install
git clone https://github.com/sanchez314c/METALlama.cpp.git
cd METALlama.cpp
chmod +x install-metallama.sh
./install-metallama.sh
```

### What Happens During Installation
1. **System Check** - Validates macOS version and hardware
2. **Dependencies** - Installs Homebrew, Conda, build tools
3. **Build** - Compiles llama.cpp with Metal support
4. **Model Download** - Downloads default 1B model
5. **Service Setup** - Configures automatic startup
6. **Verification** - Tests everything works

## First Use

### Test the Installation
```bash
# Check if service is running
~/llama-service.sh status

# Try a simple query
~/llama-chat.sh "Hello! How are you today?"

# Check API is accessible
curl http://127.0.0.1:8080/health
```

### Basic Chat Usage
```bash
# Interactive chat mode
~/llama-chat.sh

# Single question mode
~/llama-chat.sh "Explain quantum computing in simple terms"

# Scripting mode
echo "Your prompt here" | ~/llama-chat.sh
```

## Common First Tasks

### Change Model
```bash
# Download a different model
cd ~/METALlama.cpp/models
wget https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGUF/resolve/main/llama-2-7b-chat.Q4_K_M.gguf

# Update configuration
nano ~/.config/llama_mps_server/run_server.sh
# Change the model path to your new model

# Restart service
~/llama-service.sh restart
```

### Enable Network Access
```bash
# Edit server configuration
nano ~/.config/llama_mps_server/run_server.sh
# Change "--host 127.0.0.1" to "--host 0.0.0.0"

# Restart service
~/llama-service.sh restart

# Test from another device
curl http://YOUR_MAC_IP:8080/health
```

### Adjust Performance
```bash
# For better performance (if you have VRAM)
nano ~/.config/llama_mps_server/run_server.sh
# Change "--n-gpu-layers 1" to "--n-gpu-layers 32"

# Restart service
~/llama-service.sh restart
```

## Integration with Applications

### BoltAI (macOS)
1. Open BoltAI
2. Go to Settings → AI Providers
3. Add new provider:
   - Name: METALlama
   - API Type: OpenAI Compatible
   - Base URL: http://127.0.0.1:8080/v1
   - Model: Llama-3.2-1B-Instruct

### OpenWebUI (Docker)
```bash
# Run OpenWebUI connected to local METALlama
docker run -d -p 3000:8080 \
  -e OPENAI_API_BASE_URL=http://host.docker.internal:8080/v1 \
  -e OPENAI_API_KEY=dummy \
  ghcr.io/open-webui/open-webui:main

# Access at http://localhost:3000
```

### VS Code with Continue.dev
```json
// settings.json
{
  "continue.telemetryEnabled": false,
  "continue.models": [
    {
      "title": "METALlama",
      "provider": "openai",
      "model": "Llama-3.2-1B-Instruct",
      "apiKey": "dummy",
      "apiBase": "http://127.0.0.1:8080/v1"
    }
  ]
}
```

## Quick Troubleshooting

### Service Not Starting
```bash
# Check what went wrong
~/llama-service.sh logs

# Try manual start
~/run-llama-direct.sh

# Common fix: Not enough RAM for model
# Try a smaller model or restart your Mac
```

### Poor Performance
```bash
# Increase GPU layers (if you have VRAM)
nano ~/.config/llama_mps_server/run_server.sh
# Find: --n-gpu-layers 1
# Change to: --n-gpu-layers 32

# Restart service
~/llama-service.sh restart
```

### Can't Access from Network
```bash
# Check if bound to all interfaces
grep "host" ~/.config/llama_mps_server/run_server.sh

# Should show: --host 0.0.0.0 (not 127.0.0.1)

# Check firewall
sudo pfctl -sr | grep 8080
```

## Next Steps

### Learn More
- **Full Documentation**: [README.md](../README.md) for complete guide
- **API Reference**: [API.md](API.md) for integration details
- **Troubleshooting**: [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
- **FAQ**: [FAQ.md](FAQ.md) for frequently asked questions

### Optimize Further
- Try different models from [MODELS.md](MODELS.md)
- Check performance benchmarks in [BENCHMARKS.md](BENCHMARKS.md)
- Learn about configuration options in [ARCHITECTURE.md](ARCHITECTURE.md)

### Get Help
- **GitHub Issues**: Report problems or request features
- **Discussions**: Ask questions and share experiences
- **Discord**: Join community chat (if available)

## Quick Reference

### Essential Commands
```bash
~/llama-service.sh status    # Check service
~/llama-service.sh start      # Start service
~/llama-service.sh stop       # Stop service
~/llama-service.sh restart    # Restart service
~/llama-service.sh logs       # View logs
~/llama-chat.sh "prompt"     # Send query
```

### File Locations
```bash
Configuration: ~/.config/llama_mps_server/config.json
Models:       ~/METALlama.cpp/models/
Logs:         ~/Desktop/llama_server_logs/
Binaries:     ~/METALlama.cpp/build/
```

### Default Settings
- **Port**: 8080
- **Host**: 127.0.0.1 (localhost only)
- **Model**: Llama-3.2-1B-Instruct.Q4_K_M.gguf
- **GPU Layers**: 1 (conservative default)

You're now ready to use AI on your Intel Mac! 🚀