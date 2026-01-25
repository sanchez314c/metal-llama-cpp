# Project: METALlama.cpp

## Overview
METALlama.cpp is a prepackaged bare-metal installer for Llama.cpp with Metal Performance Shaders (MPS) acceleration on Intel Macs with AMD GPUs. The installer script (`install-metallama.sh`) clones and compiles llama.cpp, downloads a GGUF model from Hugging Face, creates a macOS launchd service (`com.llama.mps.server`), and generates runtime helper scripts in the user's home directory.

## Tech Stack
- **Language:** Shell (Bash), Python 3.10 (model download utilities)
- **Primary:** llama.cpp compiled with `-DLLAMA_METAL=ON -DLLAMA_METAL_EMBED_LIBRARY=ON`
- **Platform:** macOS 11.0+ (Big Sur or later) — Intel x86_64 with AMD discrete GPU
- **Build:** CMake + Ninja via Homebrew; Conda for Python env (`METALlama`)
- **Service:** macOS launchd (`~/Library/LaunchAgents/com.llama.mps.server.plist`)
- **API:** llama.cpp's built-in OpenAI-compatible HTTP server on port 8080
- **Linting:** ShellCheck (`.shellcheckrc` disables SC1090, SC1091, SC2034)
- **CI:** GitHub Actions — lint (`shellcheck`), validate (bash -n, permissions), docs

## Primary Entry Points
- **Main installer:** `install-metallama.sh` — 1482-line Bash program; run with `./install-metallama.sh [flags]`
- **macOS launch:** `run-source-macos.sh` — validates OS + AMD GPU, then calls `install-metallama.sh --verbose`
- **Linux/Windows:** `run-source-linux.sh` / `run-source-windows.bat` — stubs that exit with "platform not supported"

## Key Installer Flags
```bash
./install-metallama.sh --verbose        # Verbose output
./install-metallama.sh --dry-run        # Preview only, no changes
./install-metallama.sh --secure         # Bind to 127.0.0.1 only
./install-metallama.sh --no-autostart   # Skip launchd service start
./install-metallama.sh --port 8081      # Custom port
./install-metallama.sh --auth-token X  # Enable API auth
./install-metallama.sh --model "Llama-3.2-3B-Instruct"  # Model selection
```

## Runtime Files Created by install-metallama.sh
```
~/.config/llama_mps_server/config.json    # Server settings
~/.config/llama_mps_server/run_server.sh  # Runtime launch script
~/Library/LaunchAgents/com.llama.mps.server.plist
~/METALlama.cpp/                          # Cloned and compiled llama.cpp
~/METALlama.cpp/models/*.gguf             # Downloaded model files
~/llama-service.sh                        # Service control
~/llama-chat.sh                           # CLI chat interface
~/run-llama-direct.sh                     # Debug direct launch
~/Desktop/llama_server_logs/              # Log files
```

## Default Model
- **Repo:** `QuantFactory/Llama-3.2-1B-Instruct-GGUF`
- **File:** `Llama-3.2-1B-Instruct.Q4_K_M.gguf`
- **Other options:** Llama-3.2-3B, Llama-3.2-8B, Mistral-7B-v0.2 (all Q4_K_M)

## Project Structure
```
metal-llama-cpp/
├── install-metallama.sh          # Main installer
├── run-source-macos.sh           # macOS entry point
├── run-source-linux.sh           # Linux stub (unsupported)
├── run-source-windows.bat        # Windows stub (unsupported)
├── .shellcheckrc                 # ShellCheck config
├── .editorconfig                 # Editor standards (4-space indent, LF, UTF-8)
├── docs/                         # Full documentation suite
│   ├── README.md                 # Documentation index
│   ├── QUICK_START.md
│   ├── INSTALLATION.md
│   ├── ARCHITECTURE.md
│   ├── API.md
│   ├── BUILD_COMPILE.md
│   ├── DEPLOYMENT.md
│   ├── DEVELOPMENT.md
│   ├── FAQ.md
│   ├── TROUBLESHOOTING.md
│   ├── TECHSTACK.md
│   ├── WORKFLOW.md
│   ├── LEARNINGS.md
│   ├── PRD.md
│   ├── TODO.md
│   ├── MODELS.md
│   └── BENCHMARKS.md
├── resources/
│   ├── icons/                    # App icons (icns, ico, png)
│   └── screenshots/              # metallama-interface.png
├── .github/
│   ├── ISSUE_TEMPLATE/bug_report.md
│   ├── ISSUE_TEMPLATE/feature_request.md
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/ci.yml
└── archive/                      # Prior versions (gitignored)
```

## Notes for AI Assistants
- This is a shell-script-only project — no package.json, pyproject.toml, Makefile, or application binary
- The deliverable is the installer that builds and runs llama.cpp, not a standalone application
- "METALlama.cpp" is the project name; `~/METALlama.cpp/` is the runtime install directory created by the installer
- When suggesting changes to `install-metallama.sh`, respect the `set -euo pipefail` strict mode
- The CI workflow runs on ubuntu-latest for linting/syntax only; actual Metal builds require macOS hardware
- Installer calls `system_profiler SPDisplaysDataType` to detect AMD GPU; warnings if not found but execution can continue with user confirmation

## User Contact Info
- **Name:** J. Michaels
- **GitHub:** https://github.com/sanchez314c
- **Project URL:** https://github.com/sanchez314c/METALlama.cpp
