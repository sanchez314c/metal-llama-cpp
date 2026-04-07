# AGENTS.md — METALlama.cpp

Guidance for Claude Code, GitHub Copilot, Cursor, and other AI coding tools working in this repository.

## What This Project Is

A single-file Bash installer (`install-metallama.sh`, 1482 lines) that:
1. Validates macOS 11.0+ and AMD GPU presence via `system_profiler`
2. Installs Homebrew dependencies (cmake, ninja, wget)
3. Creates a Conda environment named `METALlama` with Python 3.10
4. Clones `github.com/ggerganov/llama.cpp` and compiles it with `-DLLAMA_METAL=ON`
5. Downloads a GGUF model from Hugging Face into `~/METALlama.cpp/models/`
6. Creates a macOS LaunchAgent at `~/Library/LaunchAgents/com.llama.mps.server.plist`
7. Generates `~/llama-service.sh`, `~/llama-chat.sh`, and `~/run-llama-direct.sh`

The project does not have application source code. There is no `main()`, no web server code, no Python package. The installer orchestrates other tools.

## Repository Layout

```
metal-llama-cpp/
├── install-metallama.sh        # The entire codebase (1482-line Bash)
├── run-source-macos.sh         # Entry point: macOS validation wrapper
├── run-source-linux.sh         # Stub: exits 1, explains MPS is macOS-only
├── run-source-windows.bat      # Stub: exits 1, same reason
├── .shellcheckrc               # Disables SC1090, SC1091, SC2034; sets shell=bash
├── .editorconfig               # 4-space indent, LF, UTF-8
├── .github/workflows/ci.yml    # lint (shellcheck), validate (bash -n + perms), docs
├── docs/                       # 17-file documentation suite (see docs/README.md)
└── resources/                  # Icons and screenshots (not source code)
```

## Critical Context

**Platform:** macOS only. `run-source-linux.sh` and `run-source-windows.bat` are intentional stubs that reject execution. Do not attempt to port the installer logic to Linux/Windows unless working on a dedicated cross-platform branch.

**Strict mode:** `install-metallama.sh` starts with `set -euo pipefail`. Every command you add must handle its own errors — an unchecked failure will abort the entire install.

**Idempotency:** The installer is designed to be re-runnable. When modifying logic, preserve checks like `[[ -d "$LLAMA_CPP_FULL_PATH" ]]` before re-cloning.

**Variable naming:** Global constants use `UPPER_SNAKE_CASE`. Function-local vars use `snake_case` with `local`. Configuration paths are centralized at the top of the file (lines 1-30).

## Key Variables (installer top section)

```bash
DEFAULT_CONDA_ENV_NAME="METALlama"
DEFAULT_PYTHON_VERSION="3.10"
LLAMA_CPP_DIR_NAME="METALlama.cpp"
LLAMA_CPP_FULL_PATH="$HOME/$LLAMA_CPP_DIR_NAME"
MODELS_INSTALL_FULL_PATH="$LLAMA_CPP_FULL_PATH/models"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/llama_mps_server"
LOG_DIR="$HOME/Desktop/llama_server_logs"
SERVICE_LABEL="com.llama.mps.server"
SERVICE_PLIST_PATH="$HOME/Library/LaunchAgents/$SERVICE_LABEL.plist"
```

## API Server (runtime, not repo)

Once installed, the server runs at `http://127.0.0.1:8080` with:
- `GET /health` — returns "ok"
- `POST /v1/chat/completions` — OpenAI-compatible, supports streaming

Default config: `~/.config/llama_mps_server/config.json` — edit `gpu_layers`, `context_size`, `port`, etc.

## CI Pipeline (.github/workflows/ci.yml)

Three jobs run on push/PR to main/master:
- **lint:** `shellcheck --severity=warning install-metallama.sh` on ubuntu-latest
- **validate:** `bash -n install-metallama.sh` + executable permission check + required files check
- **docs:** Scan for empty markdown files (excludes `archive/`)

The required files checked by CI: README.md, LICENSE, CHANGELOG.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md, SECURITY.md, .editorconfig, .gitignore

## What Not to Do

- Do not add `node_modules`, `package.json`, or Python packaging files — there is no application to package
- Do not modify `.gitignore` to un-ignore `archive/` or `*.gguf` — models are never committed
- Do not change the default port (8080) in documentation without also updating `install-metallama.sh`
- Do not add `--no-verify` to git commands; run ShellCheck and fix warnings before committing

## Testing Changes

```bash
# Syntax check
bash -n install-metallama.sh

# Linting
shellcheck --severity=warning install-metallama.sh

# Dry run (no side effects)
./install-metallama.sh --dry-run --verbose

# macOS entry point
./run-source-macos.sh
```

## Documentation

All docs live in `docs/`. The index is `docs/README.md`. When adding a feature, update:
1. `docs/TODO.md` (remove from backlog)
2. `docs/ARCHITECTURE.md` (if structure changes)
3. `CHANGELOG.md` (required)
4. `docs/INSTALLATION.md` (if flags change)
