# Frequently Asked Questions

## Installation Issues

### Q: The installer fails to find my Conda installation
**A:** The installer looks for Conda in common locations. If your Conda is installed in a non-standard location, you'll be prompted to enter the full path manually. Make sure you provide the path to the Conda base directory, not just the bin directory.

### Q: I get "command not found: conda" even after providing the path
**A:** This typically happens if Conda wasn't initialized properly. The installer attempts to source the Conda profile script, but it might fail in some environments. Try running `source ~/miniconda3/etc/profile.d/conda.sh` (adjust path as needed) before running the installer.

### Q: The installer can't download the model
**A:** Check that:
1. Your Hugging Face token is valid
2. You have an internet connection
3. The model repository still exists
If issues persist, you can download the model manually and place it in `~/METALlama.cpp/models/`.

### Q: CMake fails during the build process
**A:** Ensure you have the required build tools:
```bash
xcode-select --install
brew install cmake ninja
```
Then retry the installation.

## Service Issues

### Q: The service starts but terminates immediately
**A:** Check the logs:
```bash
~/llama-service.sh logs
```
Common issues include:
- Insufficient memory for the model
- Model file not found at the expected path
- Permission issues with the log directories

### Q: The service runs but isn't accessible on my network
**A:** By default, the server is configured to listen on 0.0.0.0 (all interfaces) on port 8080. Check:
1. Your Mac's firewall settings
2. Network settings if you're on a VPN
3. Try accessing from the same machine first: `curl http://127.0.0.1:8080/health`

### Q: How do I change the port the server runs on?
**A:** Edit `~/.config/llama_mps_server/run_server.sh` and change the `--port 8080` parameter to your desired port. Then restart the service with `~/llama-service.sh restart`.

## Performance Issues

### Q: The model is running very slowly
**A:** Try these optimizations:
1. Increase GPU layers: Edit `~/.config/llama_mps_server/run_server.sh` and change `--n-gpu-layers 1` to a higher number (e.g., 32)
2. Use a smaller model or different quantization
3. Close other GPU-intensive applications
4. If on an Intel Mac, ensure your discrete GPU is active

### Q: I get "Metal device not found" errors
**A:** This indicates that the Metal framework couldn't initialize properly. Check:
1. Your Mac supports Metal (most Macs from 2015 onwards do)
2. You're using a recent macOS version (Big Sur or later recommended)
3. Your GPU drivers are up to date

### Q: The model consumes too much memory
**A:** You can reduce memory usage by:
1. Using a smaller model (e.g., 1B instead of 8B parameters)
2. Using more aggressive quantization (e.g., Q2_K instead of Q4_K_M)
3. Reducing the context size (e.g., `--ctx-size 4096` instead of 8192)
4. Reducing the number of GPU layers to offload less to system RAM

## Compatibility Issues

### Q: Can I use other models with this installer?
**A:** Yes, you can use any GGUF format model that's compatible with llama.cpp. After downloading your preferred model, place it in `~/METALlama.cpp/models/` and update the model path in `~/.config/llama_mps_server/run_server.sh`.

### Q: Is this compatible with the official OpenAI API?
**A:** The server implements a subset of the OpenAI Chat Completions API. Most basic functionalities work, but advanced features like function calling are not supported. Most OpenAI client libraries will work if you set the API base URL to your local server.

### Q: Can I use METALlama.cpp on a remote server?
**A:** While the installer is designed for local use on macOS, you could potentially use it on a remote Mac and access it over the network. However, always be cautious about exposing AI models on networks without proper security measures.

## Upgrading and Maintenance

### Q: How do I update to a newer version of llama.cpp?
**A:** The simplest approach is to:
1. Stop the service: `~/llama-service.sh stop`
2. Update the repository: `cd ~/METALlama.cpp && git pull`
3. Rebuild: `cd build && cmake --build . --config Release`
4. Restart the service: `~/llama-service.sh start`

### Q: How do I completely remove METALlama.cpp?
**A:** Follow the uninstallation instructions in the INSTALL.md document to remove all components.