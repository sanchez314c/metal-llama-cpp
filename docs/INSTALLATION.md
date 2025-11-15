# Installation Guide

This document provides comprehensive installation instructions for METALlama.cpp on macOS.

## Prerequisites

### System Requirements
- **macOS 11.0 or later** - Required for Metal Performance Shaders support
- **Intel Mac with AMD GPU** or Apple Silicon Mac for optimal performance
- **8GB+ RAM** (16GB+ recommended for larger models)
- **10GB free disk space** for build artifacts and models

### Required Software
```bash
# Xcode Command Line Tools
xcode-select --install

# Homebrew (package manager)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Conda/Miniconda (Python environment)
# Download from: https://docs.conda.io/en/latest/miniconda.html
# Or install via Homebrew:
brew install miniconda

# Git (version control)
# Usually pre-installed, or:
brew install git
```

### Hugging Face Account
- Create account at: https://huggingface.co/
- Generate access token at: https://huggingface.co/settings/tokens
- Required for model downloads

## Quick Installation

### Standard Install
```bash
# Clone repository
git clone https://github.com/sanchez314c/METALlama.cpp.git
cd METALlama.cpp

# Make installer executable
chmod +x install-metallama.sh

# Run installation
./install-metallama.sh
```

### Installation Options
```bash
# Verbose output
./install-metallama.sh --verbose

# Custom model selection
./install-metallama.sh --model "Llama-3.2-3B-Instruct"

# Secure mode (localhost only)
./install-metallama.sh --secure

# Dry run (preview actions)
./install-metallama.sh --dry-run

# Skip service autostart
./install-metallama.sh --no-autostart

# Custom port
./install-metallama.sh --port 8081

# Authentication token
./install-metallama.sh --auth-token "your-secure-token"
```

## Detailed Installation Process

### Step 1: System Validation
The installer checks:
```bash
# macOS version
sw_vers | grep "ProductVersion:" | cut -d' ' -f3

# Architecture
uname -m

# GPU detection
system_profiler SPDisplaysDataType | grep "Chipset Model"

# Metal support
system_profiler SPDisplaysDataType | grep "Metal"
```

### Step 2: Environment Setup
```bash
# Install dependencies via Homebrew
brew install cmake ninja wget

# Create conda environment
conda create -n METALlama python=3.10 -y
conda activate METALlama

# Install Python packages
pip install torch torchvision requests huggingface_hub
```

### Step 3: Build llama.cpp
```bash
# Clone repository
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

# Configure with Metal support
cmake -B build \
    -DLLAMA_METAL=ON \
    -DLLAMA_METAL_EMBED_LIBRARY=ON \
    -DCMAKE_BUILD_TYPE=Release

# Compile
cmake --build build --config Release -j$(sysctl -n hw.ncpu | awk '{print $2}')
```

### Step 4: Model Download
```bash
# Default model
MODEL_REPO="QuantFactory/Llama-3.2-1B-Instruct-GGUF"
MODEL_FILE="Llama-3.2-1B-Instruct.Q4_K_M.gguf"

# Download with progress
wget --progress=bar:force \
    https://huggingface.co/$MODEL_REPO/resolve/main/$MODEL_FILE \
    -O ~/METALlama.cpp/models/$MODEL_FILE
```

### Step 5: Service Configuration
```bash
# Create configuration directory
mkdir -p ~/.config/llama_mps_server

# Generate config file
cat > ~/.config/llama_mps_server/config.json << EOF
{
  "model": "~/METALlama.cpp/models/$MODEL_FILE",
  "gpu_layers": 32,
  "context_size": 4096,
  "batch_size": 512,
  "threads": 8,
  "host": "127.0.0.1",
  "port": 8080,
  "temperature": 0.7,
  "top_p": 0.9,
  "top_k": 40,
  "repeat_penalty": 1.1
}
EOF

# Create LaunchAgent
cat > ~/Library/LaunchAgents/com.llama.mps.server.plist << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.llama.mps.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>~/METALlama.cpp/build/bin/main</string>
        <string>-m</string>
        <string>~/METALlama.cpp/models/$MODEL_FILE</string>
        <string>--host</string>
        <string>127.0.0.1</string>
        <string>--port</string>
        <string>8080</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
</dict>
</plist>
EOF
```

### Step 6: Verification
```bash
# Test Metal support
python3 -c "
import torch
if torch.backends.mps.is_available():
    print('✓ Metal MPS available')
else:
    print('✗ Metal MPS not available')
"

# Start service
launchctl load ~/Library/LaunchAgents/com.llama.mps.server.plist

# Verify API
curl http://127.0.0.1:8080/health
```

## Post-Installation

### Created Files
```bash
# Installation directory
~/METALlama.cpp/
├── llama.cpp/          # Source and build
├── models/             # Downloaded models
└── build/              # Compiled binaries

# Configuration
~/.config/llama_mps_server/
├── config.json         # Server configuration
└── run_server.sh       # Runtime script

# Service
~/Library/LaunchAgents/
└── com.llama.mps.server.plist

# Helper scripts
~/llama-service.sh        # Service management
~/llama-chat.sh          # CLI interface
~/run-llama-direct.sh    # Direct execution
```

### First Usage
```bash
# Check service status
~/llama-service.sh status

# Interactive chat
~/llama-chat.sh

# Single query
~/llama-chat.sh "Hello, how are you?"

# View logs
~/llama-service.sh logs
```

## Configuration

### Server Settings
Edit `~/.config/llama_mps_server/config.json`:
```json
{
  "model": "path/to/model.gguf",
  "gpu_layers": 32,           // Number of layers to offload to GPU
  "context_size": 4096,        // Context window size
  "batch_size": 512,           // Batch processing size
  "threads": 8,                // CPU threads
  "host": "127.0.0.1",        // Server bind address
  "port": 8080,               // Server port
  "temperature": 0.7,           // Response randomness
  "top_p": 0.9,              // Nucleus sampling
  "top_k": 40,                // Top-k sampling
  "repeat_penalty": 1.1         // Repetition penalty
}
```

### Performance Tuning
```bash
# GPU layers (based on VRAM)
8GB VRAM: 16-24 layers
16GB VRAM: 32-40 layers
32GB+ VRAM: 48+ layers

# Context size (based on RAM)
8GB RAM: 2048-4096 tokens
16GB RAM: 4096-8192 tokens
32GB+ RAM: 8192-16384 tokens
```

## Troubleshooting

### Common Issues

#### Installation Fails
```bash
# Check system requirements
system_profiler SPHardwareDataType | grep "Model Name"
system_profiler SPDisplaysDataType | grep "Chipset Model"

# Verify tools
xcode-select --print-path
brew --version
conda --version

# Check permissions
ls -la install-metallama.sh
```

#### Build Errors
```bash
# Clean build directory
rm -rf ~/METALlama.cpp/llama.cpp/build

# Update tools
brew update && brew upgrade

# Check logs
~/llama-service.sh logs
```

#### Service Issues
```bash
# Manual start
~/run-llama-direct.sh --verbose

# Check LaunchAgent
launchctl list | grep llama

# Debug mode
METALLAMA_DEBUG=1 ~/llama-service.sh start
```

#### Model Problems
```bash
# Verify model file
ls -la ~/METALlama.cpp/models/

# Check model format
file ~/METALlama.cpp/models/*.gguf

# Download manually
wget -O ~/METALlama.cpp/models/model.gguf \
  https://huggingface.co/repo/model.gguf
```

## Uninstallation

### Complete Removal
```bash
# Stop service
~/llama-service.sh stop

# Remove LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.llama.mps.server.plist
rm ~/Library/LaunchAgents/com.llama.mps.server.plist

# Remove installation
rm -rf ~/METALlama.cpp

# Remove configuration
rm -rf ~/.config/llama_mps_server

# Remove logs
rm -rf ~/Desktop/llama_server_logs

# Remove scripts
rm ~/llama-service.sh ~/llama-chat.sh ~/run-llama-direct.sh

# Clean conda environment
conda env remove -n METALlama
```

## Advanced Options

### Custom Model Installation
```bash
# Download specific model
./install-metallama.sh \
    --model-repo "TheBloke/Llama-2-7B-Chat-GGUF" \
    --model-file "llama-2-7b-chat.Q4_K_M.gguf"

# Multiple models
./install-metallama.sh --model "Llama-3.2-1B-Instruct"
# Then manually download additional models to ~/METALlama.cpp/models/
```

### Development Installation
```bash
# Development mode
./install-metallama.sh --development

# Debug build
./install-metallama.sh --debug-build

# Skip model download
./install-metallama.sh --no-model
```

This installation guide covers all aspects of setting up METALlama.cpp on macOS systems.