# Architecture Documentation

This document describes the system architecture and design of METALlama.cpp.

## System Overview

METALlama.cpp is a comprehensive installation and management system for running llama.cpp with Metal Performance Shaders (MPS) acceleration on Intel Macs with AMD GPUs. The system consists of multiple interconnected components that work together to provide a seamless AI inference experience.

## Core Components

### 1. Installation Script (`install-metallama.sh`)

The main installer script is a 1482-line Bash program that orchestrates the entire setup process:

```bash
install-metallama.sh
├── System Validation Module
│   ├── macOS version check (11.0+)
│   ├── Architecture verification (Intel)
│   └── GPU detection (AMD)
├── Environment Setup Module
│   ├── Homebrew installation
│   ├── Conda environment creation
│   └── Dependency management
├── Build Module
│   ├── llama.cpp repository clone
│   ├── Metal patch application
│   └── CMake compilation with MPS support
├── Model Management Module
│   ├── HuggingFace integration
│   ├── GGUF model download
│   └── Model verification
├── Service Configuration Module
│   ├── LaunchAgent plist creation
│   ├── Service scripts generation
│   └── Configuration file setup
└── Verification Module
    ├── Metal support testing
    ├── Server functionality check
    └── Performance benchmarking
```

### 2. Service Management System

#### LaunchAgent Integration
```xml
~/Library/LaunchAgents/com.llama.mps.server.plist
├── Service Definition
│   ├── Program arguments
│   ├── Environment variables
│   └── Execution parameters
├── Resource Management
│   ├── Memory limits
│   ├── CPU priority
│   └── I/O redirection
└── Lifecycle Management
    ├── Automatic startup
    ├── Health monitoring
    └── Restart policies
```

#### Service Scripts
```bash
~/llama-service.sh          # Primary service control
├── Status monitoring
├── Start/stop operations
├── Log management
└── Health checks

~/llama-chat.sh            # CLI interface
├── Interactive chat mode
├── Single query mode
└── Script integration

~/run-llama-direct.sh      # Direct execution
├── Debug mode
├── Verbose logging
└── Manual parameter override
```

### 3. Configuration System

#### Server Configuration
```json
~/.config/llama_mps_server/config.json
{
  "model": "path/to/model.gguf",
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
```

#### Runtime Script
```bash
~/.config/llama_mps_server/run_server.sh
├── Model path configuration
├── GPU layer allocation
├── Memory management
├── Network binding
└── Performance parameters
```

## Data Flow

### Installation Flow
```
User Input → System Check → Environment Setup → Build Process → Model Download → Service Config → Verification
     │              │                │               │              │              │
     │              │                │               │              │              │
     ▼              ▼                ▼               ▼              ▼              ▼
  Requirements    Dependencies     llama.cpp      GGUF Model    LaunchAgent   Functional
    Check         Installation     Compilation     Download       Creation       Testing
```

### Runtime Flow
```
Client Request → API Server → llama.cpp Engine → Metal/MPS → GPU/CPU → Response
      │              │               │               │           │           │
      │              │               │               │           │           │
      ▼              ▼               ▼               ▼           ▼           ▼
  HTTP/HTTPS    OpenAI          Inference       GPU         Model       Generated
  Request       Compatible       Engine          Acceleration  Processing   Text
               Format
```

## Directory Structure

### Installation Layout
```
~/
├── METALlama.cpp/                    # Main installation directory
│   ├── llama.cpp/                   # Cloned llama.cpp repository
│   │   ├── .git/                   # Git metadata
│   │   ├── src/                    # Source code
│   │   ├── examples/                # Example applications
│   │   └── CMakeLists.txt           # Build configuration
│   ├── models/                      # Downloaded GGUF models
│   │   ├── Llama-3.2-1B-Instruct.Q4_K_M.gguf
│   │   └── [additional models...]
│   └── build/                       # Compiled binaries
│       ├── bin/                     # Executable files
│       ├── lib/                     # Library files
│       └── CMakeCache.txt           # Build cache
├── .config/llama_mps_server/        # Configuration directory
│   ├── config.json                 # Server configuration
│   └── run_server.sh               # Runtime script
├── Library/LaunchAgents/             # macOS service definitions
│   └── com.llama.mps.server.plist  # LaunchAgent configuration
├── Desktop/llama_server_logs/       # Log directory
│   ├── server.log                 # Main server log
│   ├── error.log                  # Error log
│   └── access.log                 # Access log
├── llama-service.sh                # Service control script
├── llama-chat.sh                  # CLI interface script
└── run-llama-direct.sh            # Direct execution script
```

## Metal Integration

### MPS (Metal Performance Shaders) Architecture
```
Application Layer
       │
       ▼
llama.cpp Engine
       │
       ▼
Metal API Layer
├── Command Buffer Management
├── Shader Compilation
├── Memory Management
└── Synchronization
       │
       ▼
GPU Driver Layer
├── AMD GPU Drivers
├── Metal Runtime
└── Hardware Abstraction
       │
       ▼
Hardware Layer
└── AMD GPU Hardware
    ├── Compute Units
    ├── VRAM
    └── Texture Units
```

### Memory Management
```
System RAM (16GB+)
       │
       ├─ Model Weights (partial)
       ├─ Context Cache
       └─ Intermediate Results
       │
GPU VRAM (8GB+)
       │
       ├─ Model Layers (offloaded)
       ├─ KV Cache
       └─ Attention Matrices
       │
Memory Flow: VRAM → System RAM (overflow handling)
```

## Security Architecture

### Process Isolation
```
User Space
├── METALlama Service (user process)
├── Configuration Files (600 permissions)
└── Log Files (user-writable)

System Space
├── Metal Framework (system)
├── GPU Drivers (system)
└── LaunchAgent (system-managed)

Network Boundary
├── Localhost Binding (default)
├── Firewall Rules (optional)
└── Authentication (optional)
```

### Access Control
```
Configuration Levels:
├── Local Only (secure mode)
│   └── 127.0.0.1:8080
├── Network Access (default)
│   └── 0.0.0.0:8080
└── Authenticated Access
    ├── API Key validation
    └── Token-based authentication
```

## Performance Optimization

### GPU Layer Allocation Strategy
```
Model Size → VRAM Requirements → GPU Layers
    │              │                   │
    ▼              ▼                   ▼
1B Model  → 2-4GB VRAM      → 16-24 layers
3B Model  → 6-8GB VRAM      → 24-32 layers
8B Model  → 12-16GB VRAM    → 32-48 layers
```

### Thermal Management
```
Temperature Monitoring
├── GPU temperature sensors
├── CPU temperature sensors
└── System fan control

Throttling Logic
├── Temperature threshold: 85°C
├── Layer reduction: 25%
└── Performance recovery: gradual
```

## Integration Points

### External Applications
```
AI Applications
├── BoltAI (macOS)
├── OpenWebUI (Docker)
├── LibreChat (self-hosted)
├── Continue.dev (VS Code)
└── Custom Clients

API Compatibility
├── OpenAI Chat Completions
├── Streaming Support
├── Model Listing
└── Health Checks
```

### Model Ecosystem
```
HuggingFace Integration
├── Model Discovery
├── Download Management
├── Progress Tracking
└── Verification

Local Model Management
├── GGUF Format Support
├── Quantization Options
├── Model Switching
└── Custom Model Loading
```

## Extensibility

### Plugin Architecture (Future)
```
Core System
├── Plugin Manager
├── Event System
└── Configuration API

Plugin Types
├── Model Plugins
├── Hardware Plugins
├── Network Plugins
└── UI Plugins
```

### Configuration Extensions
```
Current Configuration
├── JSON-based settings
├── Script-based parameters
└── Environment variables

Future Extensions
├── YAML configuration
├── GUI configuration tool
├── Remote configuration
└── Dynamic reconfiguration
```

This architecture provides a solid foundation for AI inference on Intel Macs while maintaining flexibility for future enhancements and integrations.