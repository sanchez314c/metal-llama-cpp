@echo off
REM METALlama.cpp - Run from Source (Windows)
REM
REM NOTE: This script is provided for completeness but METALlama.cpp is
REM designed for macOS only. It requires Metal Performance Shaders (MPS)
REM which is an Apple technology exclusive to macOS.
REM
REM For Windows AI inference, consider using the main llama.cpp project with
REM DirectML, CUDA, or other GPU acceleration frameworks.
REM
REM https://github.com/ggerganov/llama.cpp

echo === METALlama.cpp - Platform Not Supported ===
echo.
echo ERROR: METALlama.cpp is designed for macOS only.
echo.
echo This project requires:
echo   - macOS 11.0 (Big Sur) or later
echo   - Intel Mac with AMD discrete GPU
echo   - Metal Performance Shaders (MPS) framework
echo.
echo For Windows AI inference, please use the main llama.cpp project:
echo   https://github.com/ggerganov/llama.cpp
echo.
echo llama.cpp supports Windows with:
echo   - DirectML (various GPUs)
echo   - CUDA (NVIDIA GPUs)
echo   - Vulkan (various GPUs)
echo.
exit /b 1
