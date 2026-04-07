#!/bin/bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Running METALlama.cpp from source (macOS) ==="

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "ERROR: METALlama.cpp is designed for macOS only."
    echo "This project requires Metal Performance Shaders (MPS) which is macOS-only."
    exit 1
fi

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
MACOS_MAJOR=$(echo "$MACOS_VERSION" | cut -d. -f1)
MACOS_MINOR=$(echo "$MACOS_VERSION" | cut -d. -f2)

if [[ "$MACOS_MAJOR" -lt 11 ]] || [[ "$MACOS_MAJOR" -eq 10 && "$MACOS_MINOR" -lt 16 ]]; then
    echo "ERROR: macOS 11.0 (Big Sur) or later required."
    echo "Current version: $MACOS_VERSION"
    exit 1
fi

# Check for AMD GPU
GPU_INFO=$(system_profiler SPDisplaysDataType | grep "Chipset Model")
if ! echo "$GPU_INFO" | grep -qi "amd\|radeon"; then
    echo "WARNING: No AMD GPU detected."
    echo "This project is designed for Intel Macs with AMD discrete graphics."
    echo "Continue anyway? (y/n)"
    read -r response
    if [[ "$response" != "y" ]]; then
        exit 1
    fi
fi

# Check if installer exists
if [ ! -f "install-metallama.sh" ]; then
    echo "ERROR: install-metallama.sh not found."
    exit 1
fi

# Make installer executable
chmod +x install-metallama.sh

# Run the installer with verbose output
echo "Launching METALlama.cpp installer..."
./install-metallama.sh --verbose
