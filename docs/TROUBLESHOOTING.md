# Troubleshooting Guide

This document provides solutions to common issues with METALlama.cpp.

## Installation Issues

### Metal Framework Not Detected

**Symptoms:**
- Error: "Metal MPS not available"
- Installation fails at GPU detection step
- Metal acceleration not working

**Solutions:**
```bash
# Check macOS version (requires 11.0+)
sw_vers | grep "ProductVersion:" | cut -d' ' -f3

# Verify Metal support
system_profiler SPDisplaysDataType | grep "Metal"

# Update Xcode Command Line Tools
sudo xcode-select --install

# Check GPU model compatibility
system_profiler SPDisplaysDataType | grep "Chipset Model"
# Supported: Most AMD GPUs from 2015+
```

**Common Causes:**
- macOS version older than 11.0
- Very old AMD GPU (pre-2015)
- Corrupted Xcode installation

### Conda Environment Issues

**Symptoms:**
- Error: "command not found: conda"
- Python packages not found
- Environment activation fails

**Solutions:**
```bash
# Find Conda installation
find / -name "conda.sh" 2>/dev/null

# Manually initialize Conda
~/miniconda3/bin/conda init zsh

# Source Conda profile
source ~/.zshrc

# Verify Conda
conda --version
```

**Alternative: Use system Python**
```bash
# Skip Conda installation
./install-metallama.sh --no-conda

# Use system Python 3.8+
python3 --version
```

### Build Failures

**Symptoms:**
- CMake configuration errors
- Compilation failures
- Missing dependencies

**Solutions:**
```bash
# Clean build directory
rm -rf ~/METALlama.cpp/llama.cpp/build

# Update build tools
brew update && brew upgrade cmake ninja

# Check Xcode tools
xcode-select --print-path

# Build with verbose output
cmake -B build -DLLAMA_METAL=ON --verbose
cmake --build build --verbose
```

**Specific Build Errors:**
```bash
# Metal not found
export CMAKE_PREFIX_PATH=/Applications/Xcode.app/Contents/Developer

# Linker errors
export LDFLAGS="-framework Metal -framework Foundation"

# Permission errors
sudo chown -R $USER:$(id -gn) ~/METALlama.cpp
```

## Service Issues

### Service Won't Start

**Symptoms:**
- Service starts and immediately stops
- LaunchAgent fails to load
- No response on port 8080

**Diagnostics:**
```bash
# Check service status
launchctl list | grep llama

# View service logs
~/llama-service.sh logs

# Check for errors
grep -i error ~/Desktop/llama_server_logs/server.log

# Manual start for debugging
~/run-llama-direct.sh --verbose
```

**Common Solutions:**
```bash
# Model file not found
ls -la ~/METALlama.cpp/models/

# Incorrect permissions
chmod 600 ~/.config/llama_mps_server/config.json
chmod 700 ~/llama-service.sh

# Port already in use
lsof -i :8080
# Change port in configuration
```

### Service Not Accessible

**Symptoms:**
- Connection refused on localhost
- Timeout errors
- Service not responding

**Network Diagnostics:**
```bash
# Check if service is running
ps aux | grep metallama

# Test local connection
curl -v http://127.0.0.1:8080/health

# Check port binding
netstat -an | grep 8080

# Check firewall
sudo pfctl -sr | grep 8080
```

**Solutions:**
```bash
# Restart service
~/llama-service.sh restart

# Check configuration
cat ~/.config/llama_mps_server/run_server.sh

# Verify host binding
grep "host" ~/.config/llama_mps_server/run_server.sh
```

## Performance Issues

### Poor GPU Utilization

**Symptoms:**
- Slow inference speed
- GPU not being used
- High CPU usage instead

**Diagnostics:**
```bash
# Check GPU utilization
sudo powermetrics --samplers gpu_power -n 5 -i 1000

# Monitor during inference
top -pid $(pgrep metallama) -s 0 -d 1

# Check Metal activity
sudo metal_debugger
```

**Solutions:**
```bash
# Increase GPU layers
nano ~/.config/llama_mps_server/run_server.sh
# Change --n-gpu-layers 1 to higher value

# For different VRAM sizes:
8GB VRAM: 16-24 layers
16GB VRAM: 32-40 layers
32GB+ VRAM: 48+ layers

# Restart service
~/llama-service.sh restart
```

### Out of Memory Errors

**Symptoms:**
- "Out of memory" errors
- Service crashes with large models
- System becomes unresponsive

**Diagnostics:**
```bash
# Check memory usage
vm_stat | head -5

# Monitor during inference
top -pid $(pgrep metallama) -o mem

# Check available memory
free -h  # Linux equivalent
sysctl hw.memsize
```

**Solutions:**
```bash
# Use smaller model
./install-metallama.sh --model "Llama-3.2-1B-Instruct"

# Reduce context size
nano ~/.config/llama_mps_server/run_server.sh
# Change --ctx-size 8192 to 4096

# Reduce batch size
# Change --batch-size 512 to 256

# Close other applications
# Free up system RAM
```

### Thermal Throttling

**Symptoms:**
- Performance degrades over time
- Fans running at high speed
- GPU temperature warnings

**Diagnostics:**
```bash
# Check temperature
sudo powermetrics --samplers smc -n 1

# Monitor GPU temperature
sudo ioreg -r -c IOAccelerator

# Check thermal state
sudo pmset -g thermlog
```

**Solutions:**
```bash
# Reduce GPU layers
# Temporary reduction during sustained use

# Improve cooling
# Clean dust from fans/vents
# Ensure proper ventilation

# Take breaks
# Allow system to cool between intensive tasks
```

## Model Issues

### Model Loading Failures

**Symptoms:**
- "Failed to load model" errors
- Model file not recognized
- Corrupted model errors

**Diagnostics:**
```bash
# Check model file
ls -la ~/METALlama.cpp/models/
file ~/METALlama.cpp/models/*.gguf

# Verify model integrity
sha256sum ~/METALlama.cpp/models/*.gguf

# Check model format
# Should be GGUF format
```

**Solutions:**
```bash
# Re-download model
rm ~/METALlama.cpp/models/corrupted.gguf
~/llama-service.sh download-model "model-name"

# Try different quantization
# Q4_K_M → Q5_K_M or Q2_K

# Verify compatibility
# Check llama.cpp version supports model
```

### Model Performance Issues

**Symptoms:**
- Poor quality responses
- Slow generation
- Repetitive output

**Solutions:**
```bash
# Adjust sampling parameters
nano ~/.config/llama_mps_server/config.json

# Common adjustments:
{
  "temperature": 0.7,      # Lower for more focused responses
  "top_p": 0.9,         # Lower for more deterministic output
  "top_k": 40,           # Lower for more conservative output
  "repeat_penalty": 1.1    # Higher to reduce repetition
}
```

## Network Issues

### Cannot Access from Other Devices

**Symptoms:**
- Connection refused from network
- Only works on localhost
- Firewall blocking access

**Diagnostics:**
```bash
# Check binding
grep "host" ~/.config/llama_mps_server/run_server.sh

# Test from local network
curl -v http://$(ipconfig getifaddr en0 | cut -d' ' -f2):8080/health

# Check firewall
sudo pfctl -sr

# Check router settings
# Port forwarding may be required
```

**Solutions:**
```bash
# Enable network access
# Change host from 127.0.0.1 to 0.0.0.0

# Configure firewall
sudo pfctl -f /etc/pf.conf.llama

# Use authentication
./install-metallama.sh --auth-token "secure-token"
```

### SSL/TLS Issues

**Symptoms:**
- Certificate errors
- HTTPS not working
- Mixed content warnings

**Solutions:**
```bash
# Use reverse proxy
# Nginx/Apache with SSL termination

# Generate self-signed cert
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365

# Configure proxy for SSL
# See DEPLOYMENT.md for examples
```

## API Issues

### Invalid Request Format

**Symptoms:**
- 400 Bad Request errors
- "Invalid JSON" errors
- Parameters not recognized

**Diagnostics:**
```bash
# Test with curl
curl -X POST http://127.0.0.1:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"test","messages":[{"role":"user","content":"test"}]}'

# Check API documentation
cat docs/API.md
```

**Solutions:**
```bash
# Verify JSON format
# Use proper escaping
# Check required parameters

# Example correct format:
{
  "model": "Llama-3.2-1B-Instruct",
  "messages": [
    {"role": "user", "content": "Your message"}
  ],
  "temperature": 0.7,
  "max_tokens": 100
}
```

### Streaming Issues

**Symptoms:**
- Streaming not working
- Connection drops during stream
- No response in streaming mode

**Solutions:**
```bash
# Check client implementation
# Must handle Server-Sent Events
# Must support chunked transfer encoding

# Test streaming
curl -X POST http://127.0.0.1:8080/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"test","messages":[{"role":"user","content":"test"}],"stream":true}'
```

## System-Specific Issues

### Intel Mac with AMD GPU

**Common Problems:**
- Metal drivers less mature than Apple Silicon
- Thermal throttling under load
- Variable performance between GPU models

**Solutions:**
```bash
# Conservative GPU layers
# Start with 16-24 layers

# Monitor temperature
# Reduce layers if >85°C

# Update drivers
# Install macOS updates for Metal improvements
```

### Older Mac Models

**Compatibility:**
- 2015-2017 Intel Macs: Limited support
- 2012-2014 Intel Macs: No Metal support
- AMD GPUs older than 2015: May not work

**Solutions:**
```bash
# Check compatibility
system_profiler SPHardwareDataType | grep "Model Name"
system_profiler SPDisplaysDataType | grep "Chipset Model"

# Use CPU-only mode if needed
# Set --n-gpu-layers 0
```

## Getting Help

### Collect Debug Information
```bash
# Create debug report
~/llama-service.sh debug-info

# Include in issue:
- macOS version
- Hardware details
- Error messages
- Configuration files
- Log excerpts
```

### Community Support
- **GitHub Issues**: Report bugs and request features
- **Discussions**: Ask questions and share experiences
- **Discord**: Real-time community support (if available)

### Professional Support
- **Installation Support**: Remote assistance available
- **Performance Tuning**: Custom optimization services
- **Enterprise Deployment**: Commercial support options

This troubleshooting guide helps resolve common issues with METALlama.cpp.