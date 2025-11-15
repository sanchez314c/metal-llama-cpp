# Technology Stack

This document outlines the complete technology stack used in METALlama.cpp.

## Core Technologies

### Operating System
- **macOS 11.0+** (Big Sur or later)
  - Required for Metal Performance Shaders support
  - Provides Metal framework for GPU acceleration
  - Offers Unix-like environment with Apple extensions

### Programming Languages
- **Bash (Zsh)**
  - Primary scripting language for installer
  - System integration and automation
  - Cross-platform compatibility

- **Python 3.10+**
  - Model downloading utilities
  - Configuration management
  - Testing and validation scripts

- **C++**
  - llama.cpp core implementation
  - Metal shader integration
  - Performance-critical operations

### Shell Frameworks
- **Metal Performance Shaders (MPS)**
  - GPU acceleration framework
  - Shader compilation and execution
  - Memory management for GPU operations

- **LaunchAgents**
  - macOS service management
  - Automatic startup on login
  - Process lifecycle management

## Build Tools

### Compilation
- **CMake 3.15+**
  - Cross-platform build system
  - Metal-specific configuration
  - Dependency management

- **Ninja**
  - Fast build system
  - Parallel compilation
  - Incremental builds

- **Clang**
  - Default macOS compiler
  - Metal shader compilation
  - Optimization support

### Package Management
- **Homebrew**
  - macOS package manager
  - Dependency installation
  - Binary distribution

- **Conda/Miniconda**
  - Python environment management
  - Isolated dependencies
  - Reproducible builds

- **Git**
  - Version control
  - Source code management
  - Update distribution

## Runtime Dependencies

### Python Libraries
```python
# Core dependencies
torch>=1.12.0              # Metal backend detection
torchvision>=0.13.0         # Vision model support
requests>=2.25.0             # HTTP client
huggingface_hub>=0.12.0        # Model downloads
numpy>=1.21.0                # Numerical operations
```

### System Frameworks
- **Metal Framework**
  - GPU abstraction layer
  - Shader runtime
  - Memory management

- **Foundation Framework**
  - macOS system integration
  - File system operations
  - Process management

- **Core Foundation**
  - Low-level system services
  - Memory allocation
  - Threading primitives

## Model Ecosystem

### Model Formats
- **GGUF (GPT-Generated Unified Format)**
  - Primary format for llama.cpp
  - Quantization support
  - Metadata inclusion

- **GGML (Legacy)**
  - Deprecated but supported
  - Older model compatibility

### Quantization Methods
- **Q4_K_M** (Recommended)
  - 4-bit quantization
  - Medium precision
  - Best size/quality balance

- **Q5_K_M** (High Quality)
  - 5-bit quantization
  - Better precision
  - Larger file size

- **Q2_K** (Maximum Compression)
  - 2-bit quantization
  - Maximum compression
  - Quality degradation

## API Technologies

### Server Implementation
- **HTTP/1.1**
  - RESTful API design
  - Standard methods (GET, POST)
  - Status code handling

- **JSON**
  - Request/response format
  - Configuration files
  - Data interchange

- **Server-Sent Events (SSE)**
  - Streaming responses
  - Real-time updates
  - Event-driven communication

### OpenAI Compatibility
```yaml
Endpoints:
  - /v1/chat/completions: Chat completions
  - /v1/models: Model listing
  - /health: Health check

Parameters:
  - model: Model identifier
  - messages: Conversation history
  - temperature: Response randomness
  - max_tokens: Output length limit
  - stream: Streaming flag
```

## Security Technologies

### Authentication
- **API Key Authentication**
  - Token-based validation
  - Bearer token format
  - Configurable requirement

- **Localhost Binding**
  - Secure default configuration
  - Network access control
  - Firewall integration

### Process Security
- **User-level Execution**
  - No root privileges required
  - Isolated process space
  - Restricted file permissions

- **File Permissions**
  - Configuration: 600 (user read/write only)
  - Scripts: 700 (user execute)
  - Logs: 644 (user read/write)

## Performance Technologies

### GPU Acceleration
- **Metal Shaders**
  - GPU program compilation
  - Parallel processing
  - Memory optimization

- **VRAM Management**
  - Layer offloading strategy
  - Overflow to system RAM
  - Dynamic allocation

### Threading
- **POSIX Threads**
  - CPU parallelization
  - Non-GPU operations
  - Configurable thread count

- **Grand Central Dispatch**
  - Task scheduling
  - Asynchronous operations
  - Queue management

## Monitoring and Logging

### System Monitoring
- **powermetrics**
  - GPU utilization
  - Power consumption
  - Thermal data

- **vm_stat**
  - Virtual memory statistics
  - Page usage
  - Swap activity

### Application Logging
- **Structured Logging**
  - Timestamped entries
  - Log levels (INFO, ERROR, DEBUG)
  - File rotation

- **Health Checks**
  - Endpoint availability
  - Service status
  - Performance metrics

## Development Tools

### Code Quality
- **ShellCheck**
  - Bash script linting
  - Best practices enforcement
  - Error detection

- **shfmt**
  - Code formatting
  - Style consistency
  - Automated fixing

### Testing
- **Bats (Bash Automated Testing System)**
  - Unit test framework
  - Integration testing
  - CI/CD integration

### Documentation
- **Markdown**
  - Documentation format
  - GitHub rendering
  - Tool compatibility

## Integration Technologies

### Container Support
- **Docker**
  - Linux containerization
  - Service isolation
  - Deployment standardization

- **Docker Compose**
  - Multi-container orchestration
  - Service dependencies
  - Configuration management

### Reverse Proxy
- **Nginx**
  - Load balancing
  - SSL termination
  - URL rewriting

- **Apache**
  - Module-based architecture
  - .htaccess support
  - Wide adoption

## Hardware Compatibility

### Supported GPUs
```yaml
AMD:
  - Radeon Pro 5500M/560X
  - Radeon Pro 5700/5700 XT
  - Radeon Pro Vega II/II Duo
  - Radeon Pro W5000/W5000/W5000X/W6000/W6000X/W6800X/W6900X

Apple (future):
  - M1 family
  - M2 family
  - M3 family
```

### Memory Requirements
```yaml
Minimum:
  RAM: 8GB
  VRAM: 2GB
  Storage: 10GB

Recommended:
  RAM: 16GB+
  VRAM: 4GB+
  Storage: 20GB+
```

## Network Technologies

### Protocols
- **HTTP/1.1**
  - Primary protocol
  - Wide compatibility
  - Simple implementation

- **WebSocket**
  - Real-time communication
  - Streaming support
  - Bidirectional

### Data Formats
- **JSON API**
  - Request/response format
  - Configuration storage
  - Metadata exchange

- **Server-Sent Events**
  - Streaming format
  - Event streaming
  - Real-time updates

This technology stack provides a comprehensive foundation for AI inference on macOS with Metal acceleration.