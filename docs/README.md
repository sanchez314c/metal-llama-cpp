# METALlama.cpp Documentation

Complete documentation for the METALlama.cpp installer and AI inference system for Intel Macs with AMD GPUs.

## Documentation Index

### Getting Started

| File | Description |
|------|-------------|
| [QUICK_START.md](QUICK_START.md) | Get running in 5 minutes: system check, clone, install, first query |
| [INSTALLATION.md](INSTALLATION.md) | Full installation walkthrough with all flags, step-by-step details, and uninstall instructions |

### Architecture & Design

| File | Description |
|------|-------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | System components: install-metallama.sh module breakdown, LaunchAgent setup, config layout at `~/.config/llama_mps_server/`, Metal/MPS data flow |
| [PRD.md](PRD.md) | Product requirements: problem statement, user personas, acceptance criteria, success metrics |
| [TECHSTACK.md](TECHSTACK.md) | Full tech stack: Bash, CMake, Metal/MPS, Conda, Python deps, GGUF formats, ShellCheck, CI tools |

### Build & Operations

| File | Description |
|------|-------------|
| [BUILD_COMPILE.md](BUILD_COMPILE.md) | CMake flags for Metal builds (`-DLLAMA_METAL=ON -DLLAMA_METAL_EMBED_LIBRARY=ON`), debug/release/universal binary configs |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Local, network, Docker, AWS mac1.metal, Nginx/Apache reverse proxy, and HAProxy load balancing configs |
| [WORKFLOW.md](WORKFLOW.md) | Development, testing, release, maintenance, and contribution process end-to-end |

### API Reference

| File | Description |
|------|-------------|
| [API.md](API.md) | OpenAI-compatible server at `http://127.0.0.1:8080`: `GET /health`, `POST /v1/chat/completions` with streaming, Python/JS SDK examples |

### Development

| File | Description |
|------|-------------|
| [DEVELOPMENT.md](DEVELOPMENT.md) | Dev environment setup, code organization in install-metallama.sh (1482 lines), coding standards, test framework, debug/profile commands |
| [LEARNINGS.md](LEARNINGS.md) | Real-world findings: GPU layer sweet spots per model size, Q4_K_M vs Q5_K_M trade-offs, thermal throttling thresholds, Bash scripting patterns |
| [TODO.md](TODO.md) | Prioritized backlog: P1 critical fixes, P2 Web UI/model management, P3 UX, P4 Linux/Windows ports, known bugs |

### Models & Performance

| File | Description |
|------|-------------|
| [MODELS.md](MODELS.md) | Supported GGUF models, quantization options (Q2_K through Q8), GPU layer tuning, `run_server.sh` config edits |
| [BENCHMARKS.md](BENCHMARKS.md) | Measured TPS on M1/M2 and Intel Mac configurations; Intel Macs run ~30-50% of Apple Silicon throughput |

### Support

| File | Description |
|------|-------------|
| [FAQ.md](FAQ.md) | Answers for Conda path issues, model download failures, CMake errors, slow inference, Metal not detected |
| [TROUBLESHOOTING.md](TROUBLESHOOTING.md) | Symptom-based diagnostics: Metal not detected, service won't start, OOM errors, thermal throttling, API issues |

## Quick File Reference

### Runtime Paths (post-install)

| Path | Purpose |
|------|---------|
| `~/.config/llama_mps_server/config.json` | Server config: gpu_layers, context_size, host, port |
| `~/.config/llama_mps_server/run_server.sh` | Runtime launch script with llama.cpp binary args |
| `~/Library/LaunchAgents/com.llama.mps.server.plist` | macOS LaunchAgent definition |
| `~/METALlama.cpp/models/` | GGUF model files |
| `~/METALlama.cpp/build/` | Compiled llama.cpp binaries |
| `~/Desktop/llama_server_logs/` | Runtime logs |
| `~/llama-service.sh` | Service control script |
| `~/llama-chat.sh` | CLI chat interface |
| `~/run-llama-direct.sh` | Direct debug launch |

### Repository Layout

```
metal-llama-cpp/
├── install-metallama.sh      # Main installer (1482-line Bash program)
├── run-source-macos.sh       # Entry point: validates macOS + AMD GPU, runs installer
├── run-source-linux.sh       # Stub: explains platform is not supported
├── run-source-windows.bat    # Stub: explains platform is not supported
├── docs/                     # This directory
├── resources/
│   ├── icons/                # App icons (icns, ico, png)
│   └── screenshots/          # metallama-interface.png
└── archive/                  # Timestamped backups of prior versions
```

## Navigation by Role

**New user:** QUICK_START.md → INSTALLATION.md → FAQ.md

**Developer contributing:** DEVELOPMENT.md → ARCHITECTURE.md → WORKFLOW.md → BUILD_COMPILE.md

**System admin deploying:** DEPLOYMENT.md → ARCHITECTURE.md → TROUBLESHOOTING.md → BENCHMARKS.md

**API integrator:** API.md → MODELS.md → QUICK_START.md
