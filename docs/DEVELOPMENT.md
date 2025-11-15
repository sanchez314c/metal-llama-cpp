# Development Guide

This document provides comprehensive information for developing and contributing to METALlama.cpp.

## Development Environment Setup

### Prerequisites
- **macOS 11.0+** with Metal support
- **Git** for version control
- **Homebrew** for package management
- **Conda/Miniconda** for Python environment
- **Xcode Command Line Tools** for compilation

### Initial Setup
```bash
# Clone repository
git clone https://github.com/sanchez314c/METALlama.cpp.git
cd METALlama.cpp

# Install development dependencies
brew install shellcheck shfmt cmake ninja

# Create development environment
conda create -n metallama-dev python=3.10
conda activate metallama-dev

# Install Python dependencies
pip install -r requirements-dev.txt
```

## Project Structure

### Repository Layout
```
METALlama.cpp/
├── install-metallama.sh           # Main installer script
├── run.sh                        # Quick launch script
├── setup.py                      # Python utilities
├── tests/                         # Test suite
│   ├── test_installer.sh
│   ├── test_service.sh
│   └── test_api.sh
├── docs/                          # Documentation
│   ├── API.md
│   ├── BENCHMARKS.md
│   ├── FAQ.md
│   └── ...
├── scripts/                        # Helper scripts
│   ├── build_helpers.sh
│   ├── model_manager.sh
│   └── service_utils.sh
├── .github/                       # GitHub configuration
│   ├── workflows/
│   └── PULL_REQUEST_TEMPLATE.md
├── CHANGELOG.md                    # Version history
├── LICENSE                         # MIT license
└── README.md                       # Project overview
```

### Code Organization
```bash
install-metallama.sh (1482 lines)
├── Configuration Section (lines 1-100)
│   ├── Global variables
│   ├── Default values
│   └── Help functions
├── Validation Section (lines 101-200)
│   ├── System checks
│   ├── Dependency verification
│   └── Hardware detection
├── Installation Section (lines 201-800)
│   ├── Environment setup
│   ├── Build process
│   ├── Model download
│   └── Service configuration
├── Testing Section (lines 801-1200)
│   ├── Metal support test
│   ├── Server functionality test
│   └── Performance benchmark
└── Utility Section (lines 1201-1482)
    ├── Helper functions
    ├── Logging utilities
    └── Error handling
```

## Development Workflow

### 1. Feature Development
```bash
# Create feature branch
git checkout -b feature/new-feature

# Make changes
vim install-metallama.sh

# Test changes
./tests/test_installer.sh

# Commit changes
git add .
git commit -m "feat: add new feature description"
```

### 2. Testing
```bash
# Run all tests
./tests/run_all_tests.sh

# Specific test categories
./tests/test_installer.sh      # Installation tests
./tests/test_service.sh        # Service management tests
./tests/test_api.sh           # API functionality tests

# Manual testing
./install-metallama.sh --dry-run --verbose
```

### 3. Code Review
```bash
# Self-review
shellcheck install-metallama.sh
shfmt -d install-metallama.sh

# Create pull request
git push origin feature/new-feature
# Open PR on GitHub
```

## Coding Standards

### Bash Scripting Guidelines
```bash
# Use strict mode
set -euo pipefail

# Use local variables
local variable_name="value"

# Use functions for reusable code
function_name() {
    local param1="$1"
    local param2="$2"
    # Function body
}

# Error handling
if [[ $? -ne 0 ]]; then
    echo "Error: Operation failed"
    exit 1
fi

# Logging
log_info() {
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}
```

### Naming Conventions
```bash
# Variables: snake_case
local gpu_layers_count=32
local model_file_path="path/to/model"

# Functions: snake_case
function install_dependencies() { ... }
function validate_system() { ... }

# Constants: UPPER_SNAKE_CASE
readonly DEFAULT_PORT=8080
readonly MIN_MACOS_VERSION="11.0"
```

### Documentation Standards
```bash
# Function documentation
##
# Downloads model from HuggingFace
# Arguments:
#   $1 - Model repository
#   $2 - Model file
#   $3 - Destination directory
# Returns:
#   0 - Success
#   1 - Failure
##
download_model() {
    # Implementation
}
```

## Testing Framework

### Test Structure
```bash
#!/bin/bash
# tests/test_installer.sh

set -euo pipefail

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"

# Test utilities
assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="$3"
    
    if [[ "$expected" == "$actual" ]]; then
        echo "✓ PASS: $message"
        return 0
    else
        echo "✗ FAIL: $message (expected: $expected, actual: $actual)"
        return 1
    fi
}

# Test cases
test_system_validation() {
    echo "Testing system validation..."
    
    # Test macOS version check
    assert_equals "11.0" "$(./install-metallama.sh --check-macos-version)" "macOS version validation"
    
    # Test GPU detection
    assert_equals "AMD" "$(./install-metallama.sh --check-gpu)" "GPU detection"
}

# Run tests
main() {
    test_system_validation
    # More test functions...
}

main "$@"
```

### Test Categories
```bash
# Unit tests
test_function_isolation() { ... }
test_error_handling() { ... }
test_logging() { ... }

# Integration tests
test_full_installation() { ... }
test_service_startup() { ... }
test_api_connectivity() { ... }

# Performance tests
test_installation_speed() { ... }
test_memory_usage() { ... }
test_inference_speed() { ... }
```

## Debugging

### Debug Mode
```bash
# Enable debug output
./install-metallama.sh --debug
export METALLAMA_DEBUG=1

# Verbose mode
./install-metallama.sh --verbose
export METALLAMA_VERBOSE=1

# Step-by-step mode
./install-metallama.sh --step-by-step
```

### Common Debugging Techniques
```bash
# Add debug prints
echo "DEBUG: Variable value: $variable_name" >&2

# Check command exit codes
if [[ $? -ne 0 ]]; then
    echo "DEBUG: Command failed with exit code $?" >&2
fi

# Trace execution
bash -x install-metallama.sh

# Use debugger
bashdb install-metallama.sh
```

## Performance Profiling

### Installation Performance
```bash
# Time installation
time ./install-metallama.sh

# Profile with bash builtins
PS4='+ $(date "+%s.%N") $(basename "$0"):${LINENO}: '
set -x
./install-metallama.sh
set +x

# Use external profiler
perf record ./install-metallama.sh
perf report
```

### Runtime Performance
```bash
# GPU utilization
sudo powermetrics --samplers gpu_power -n 10 -i 1000

# Memory usage
vm_stat | head -5

# Process monitoring
top -pid $(pgrep metallama) -l 1
```

## Release Process

### Version Management
```bash
# Update version in script
sed -i '' 's/VERSION="2.8.0"/VERSION="2.8.1"/' install-metallama.sh

# Update CHANGELOG.md
vim CHANGELOG.md

# Create release tag
git tag -a v2.8.1 -m "Release version 2.8.1"
git push origin v2.8.1
```

### Release Checklist
```bash
# Pre-release
[ ] All tests passing
[ ] Documentation updated
[ ] CHANGELOG updated
[ ] Version bumped
[ ] Security review completed

# Release
[ ] Tag created
[ ] Release notes published
[ ] GitHub release created
[ ] Homebrew formula updated (if applicable)
```

## Contributing Guidelines

### Before Contributing
1. **Read the documentation** - Understand the project structure
2. **Search existing issues** - Avoid duplicate work
3. **Create an issue** - Discuss major changes first
4. **Follow coding standards** - Maintain consistency
5. **Write tests** - Ensure quality
6. **Document changes** - Help future maintainers

### Pull Request Process
```bash
# 1. Fork and clone
git clone https://github.com/yourusername/METALlama.cpp.git
cd METALlama.cpp

# 2. Create branch
git checkout -b fix/issue-description

# 3. Make changes
# Edit files following coding standards

# 4. Test thoroughly
./tests/run_all_tests.sh

# 5. Commit
git add .
git commit -m "fix: resolve issue description"

# 6. Push and PR
git push origin fix/issue-description
# Open PR on GitHub
```

### Code Review Checklist
- [ ] Code follows project style
- [ ] Tests are included
- [ ] Documentation is updated
- [ ] No hardcoded paths
- [ ] Error handling is proper
- [ ] Security considerations addressed
- [ ] Performance impact considered

## Development Tools

### Recommended Tools
```bash
# Shell script linting
brew install shellcheck
shellcheck install-metallama.sh

# Code formatting
brew install shfmt
shfmt -w install-metallama.sh

# Testing framework
brew install bats
bats tests/test_installer.bats

# Documentation
brew install markdownlint
markdownlint *.md

# Git hooks
brew install pre-commit
pre-commit install
```

### IDE Configuration
```json
// .vscode/settings.json
{
    "bashIde.shellcheckArguments": [
        "-x",
        "-o", "pipefail"
    ],
    "bashIde.sourceScript": true,
    "files.associations": {
        "*.sh": "shellscript"
    },
    "editor.formatOnSave": true,
    "editor.codeActionsOnSave": {
        "source.fixAll.shellcheck": true
    }
}
```

This development guide provides comprehensive information for contributing effectively to METALlama.cpp.