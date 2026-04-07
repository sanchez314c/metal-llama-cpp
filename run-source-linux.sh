#!/bin/bash
# METALlama.cpp - Run from Source (Linux)
#
# NOTE: This script is provided for completeness but METALlama.cpp is
# designed for macOS only. It requires Metal Performance Shaders (MPS)
# which is an Apple technology exclusive to macOS.
#
# For Linux AI inference, consider using the main llama.cpp project with
# CUDA, ROCm, or other GPU acceleration frameworks.
#
# https://github.com/ggerganov/llama.cpp

echo "=== METALlama.cpp - Platform Not Supported ==="
echo ""
echo "ERROR: METALlama.cpp is designed for macOS only."
echo ""
echo "This project requires:"
echo "  - macOS 11.0 (Big Sur) or later"
echo "  - Intel Mac with AMD discrete GPU"
echo "  - Metal Performance Shaders (MPS) framework"
echo ""
echo "For Linux AI inference, please use the main llama.cpp project:"
echo "  https://github.com/ggerganov/llama.cpp"
echo ""
echo "llama.cpp supports Linux with:"
echo "  - CUDA (NVIDIA GPUs)"
echo "  - ROCm (AMD GPUs)"
echo "  - Vulkan (various GPUs)"
echo ""
exit 1
