# Build and Compilation Guide

This document provides detailed instructions for building METALlama.cpp and its components from source.

## Prerequisites

### System Requirements
- **macOS 11.0+** (Big Sur or later) for Metal MPS support
- **Intel Mac with AMD GPU** or Apple Silicon Mac
- **8GB+ RAM** (16GB+ recommended for larger models)
- **10GB free disk space** for build artifacts and models

### Development Tools
```bash
# Xcode Command Line Tools
xcode-select --install

# Homebrew (package manager)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Required build tools
brew install cmake ninja git

# Python environment management
brew install miniconda
```

### Metal Development
```bash
# Verify Metal support
system_profiler SPDisplaysDataType | grep "Metal"

# Check GPU capabilities
system_profiler SPDisplaysDataType | grep "Chipset Model"

# Metal SDK (included with Xcode)
# No separate installation needed
```

## Building llama.cpp with Metal Support

### 1. Clone Repository
```bash
# Clone official llama.cpp repository
git clone https://github.com/ggerganov/llama.cpp.git
cd llama.cpp

# Or use METALlama's fork with Metal patches
git clone https://github.com/sanchez314c/METALlama.cpp.git
cd METALlama.cpp/llama.cpp
```

### 2. Prepare Build Environment
```bash
# Create conda environment
conda create -n metallama-build python=3.10
conda activate metallama-build

# Install Python dependencies
pip install torch torchvision

# Verify Metal support
python3 -c "
import torch
if torch.backends.mps.is_available():
    print('MPS available - ready for Metal build')
else:
    print('MPS not available - check system')
"
```

### 3. Configure CMake
```bash
# Basic Metal configuration
cmake -B build \
    -DLLAMA_METAL=ON \
    -DLLAMA_METAL_EMBED_LIBRARY=ON \
    -DCMAKE_BUILD_TYPE=Release

# Advanced configuration
cmake -B build \
    -DLLAMA_METAL=ON \
    -DLLAMA_METAL_EMBED_LIBRARY=ON \
    -DLLAMA_ACCELERATE=ON \
    -DLLAMA_BLAS=ON \
    -DLLAMA_BLAS_VENDOR=Apple \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0

# Debug configuration
cmake -B build \
    -DLLAMA_METAL=ON \
    -DCMAKE_BUILD_TYPE=Debug \
    -DLLAMA_DEBUG=ON
```

### 4. Compile
```bash
# Standard build
cmake --build build --config Release

# Parallel build (faster)
cmake --build build --config Release -j$(sysctl -n hw.ncpu | awk '{print $2}')

# Verbose build
cmake --build build --config Release --verbose

# Clean build
rm -rf build
cmake -B build -DLLAMA_METAL=ON
cmake --build build --config Release
```

## Build Options

### Metal-Specific Flags
```cmake
# Enable Metal support
-DLLAMA_METAL=ON

# Embed Metal library
-DLLAMA_METAL_EMBED_LIBRARY=ON

# Metal shader optimization
-DLLAMA_METAL_SHADER_DEBUG=OFF

# Metal performance tuning
-DLLAMA_METAL_MAX_BUFFERS=1024
```

### Performance Optimizations
```cmake
# Enable Accelerate framework
-DLLAMA_ACCELERATE=ON

# BLAS optimization
-DLLAMA_BLAS=ON
-DLLAMA_BLAS_VENDOR=Apple

# CPU optimizations
-DLLAMA_FMA=ON
-DLLAMA_F16C=ON

# Vector instructions
-DLLAMA_AVX2=ON
-DLLAMA_FMA=ON
```

### Build Types
```cmake
# Release (optimized)
-DCMAKE_BUILD_TYPE=Release
    -O3 optimizations
    -DNDEBUG
    - Strip symbols

# Debug (development)
-DCMAKE_BUILD_TYPE=Debug
    -g symbols
    -DDEBUG
    - No optimization

# RelWithDebInfo (profiling)
-DCMAKE_BUILD_TYPE=RelWithDebInfo
    -O2 optimizations
    -g symbols
    -DDEBUG
```

## Troubleshooting Build Issues

### Common Errors

#### Metal Not Found
```bash
# Error: Metal framework not found
# Solution: Check macOS version and Xcode tools
sw_vers
xcode-select --print-path

# Update Xcode Command Line Tools
sudo xcode-select --install
```

#### CMake Configuration Errors
```bash
# Error: CMake cannot find Metal
# Solution: Set deployment target
-DCMAKE_OSX_DEPLOYMENT_TARGET=11.0

# Error: Missing dependencies
# Solution: Install with Homebrew
brew install cmake ninja
```

#### Compilation Failures
```bash
# Error: Metal shader compilation failed
# Solution: Check GPU driver support
system_profiler SPDisplaysDataType

# Error: Linker errors
# Solution: Clean and rebuild
rm -rf build
cmake -B build -DLLAMA_METAL=ON
cmake --build build --config Release
```

### Performance Issues

#### Slow Compilation
```bash
# Use parallel builds
cmake --build build -j$(sysctl -n hw.ncpu | awk '{print $2}')

# Use Ninja instead of Make
cmake -G Ninja -B build
ninja -C build
```

#### Large Binary Size
```bash
# Use Release build type
-DCMAKE_BUILD_TYPE=Release

# Strip debug symbols
strip build/bin/main
```

## Custom Build Configurations

### Development Build
```bash
#!/bin/bash
# build-dev.sh
set -e

conda activate metallama-build

cmake -B build \
    -DLLAMA_METAL=ON \
    -DLLAMA_METAL_EMBED_LIBRARY=ON \
    -DCMAKE_BUILD_TYPE=Debug \
    -DLLAMA_DEBUG=ON

cmake --build build --config Release -j$(sysctl -n hw.ncpu | awk '{print $2}')

echo "Development build completed"
```

### Production Build
```bash
#!/bin/bash
# build-prod.sh
set -e

conda activate metallama-build

cmake -B build \
    -DLLAMA_METAL=ON \
    -DLLAMA_METAL_EMBED_LIBRARY=ON \
    -DLLAMA_ACCELERATE=ON \
    -DLLAMA_BLAS=ON \
    -DLLAMA_BLAS_VENDOR=Apple \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=11.0

cmake --build build --config Release -j$(sysctl -n hw.ncpu | awk '{print $2}')

strip build/bin/main
echo "Production build completed"
```

### Cross-Platform Build
```bash
# For Apple Silicon
cmake -B build \
    -DLLAMA_METAL=ON \
    -DCMAKE_OSX_ARCHITECTURES=arm64

# For Intel Macs
cmake -B build \
    -DLLAMA_METAL=ON \
    -DCMAKE_OSX_ARCHITECTURES=x86_64

# Universal Binary
cmake -B build \
    -DLLAMA_METAL=ON \
    -DCMAKE_OSX_ARCHITECTURES="arm64;x86_64"
```

## Integration with METALlama.cpp

### Using Custom Build
```bash
# Replace built llama.cpp with custom version
cd ~/METALlama.cpp
rm -rf llama.cpp
cp -r /path/to/custom/llama.cpp .
cp -r /path/to/custom/build .

# Restart service
~/llama-service.sh restart
```

### Build Verification
```bash
# Test Metal support
~/run-llama-direct.sh --verbose

# Check GPU utilization
sudo powermetrics --samplers gpu_power -n 5 -i 1000

# Verify API functionality
curl http://127.0.0.1:8080/health
```

## Advanced Build Options

### Compiler Flags
```bash
# Custom compiler flags
export CFLAGS="-O3 -march=native -mtune=native"
export CXXFLAGS="-O3 -march=native -mtune=native"

# Linker flags
export LDFLAGS="-framework Metal -framework Foundation"
```

### Metal Shader Optimization
```bash
# Optimize for specific GPU
cmake -B build \
    -DLLAMA_METAL=ON \
    -DLLAMA_METAL_SHADER_OPTIMIZATION=aggressive

# Conservative optimization
cmake -B build \
    -DLLAMA_METAL=ON \
    -DLLAMA_METAL_SHADER_OPTIMIZATION=conservative
```

This build guide provides comprehensive options for customizing METALlama.cpp builds for different use cases and performance requirements.