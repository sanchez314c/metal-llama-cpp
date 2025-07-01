#!/bin/bash

# --- Strict Mode ---
set -euo pipefail # Exit on error, unset variable, or pipe failure

# --- Global Variables & Defaults ---
DEFAULT_CONDA_ENV_NAME="METALlama"
DEFAULT_PYTHON_VERSION="3.10"
LLAMA_CPP_DIR_NAME="METALlama.cpp"
LLAMA_CPP_FULL_PATH="$HOME/$LLAMA_CPP_DIR_NAME" 
BUILD_DIR_NAME="build" # Relative to LLAMA_CPP_FULL_PATH

# NEW: Model directory structure from v2.6
MODELS_DIR_SUBPATH="models" # Name of the subdirectory for models, directly under LLAMA_CPP_FULL_PATH
MODELS_INSTALL_FULL_PATH="$LLAMA_CPP_FULL_PATH/$MODELS_DIR_SUBPATH" # e.g., /Users/user/METALlama.cpp/models

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/llama_mps_server"
LOG_DIR="$HOME/Desktop/llama_server_logs"
SERVICE_LABEL="com.llama.mps.server"
SERVICE_PLIST_PATH="$HOME/Library/LaunchAgents/$SERVICE_LABEL.plist"
RUN_SERVER_SCRIPT_PATH="$CONFIG_DIR/run_server.sh"
DIRECT_RUN_SCRIPT_PATH="$HOME/run-llama-direct.sh"
SERVICE_CONTROL_SCRIPT_PATH="$HOME/llama-service.sh"
CLI_CHAT_SCRIPT_PATH="$HOME/llama-chat.sh"

# Default model information
DEFAULT_MODEL_REPO="QuantFactory/Llama-3.2-1B-Instruct-GGUF"
DEFAULT_MODEL_FILE_NAME="Llama-3.2-1B-Instruct.Q4_K_M.gguf"

# Model selection options
RECOMMENDED_MODELS=(
    "QuantFactory/Llama-3.2-1B-Instruct-GGUF|Llama-3.2-1B-Instruct.Q4_K_M.gguf|1B|Smallest/fastest model (~1.1GB), good for testing"
    "QuantFactory/Llama-3.2-8B-Instruct-GGUF|Llama-3.2-8B-Instruct.Q4_K_M.gguf|8B|Balanced performance (~4.5GB), good for general use"
    "QuantFactory/Llama-3.2-3B-Instruct-GGUF|Llama-3.2-3B-Instruct.Q4_K_M.gguf|3B|Fast with decent quality (~2GB)"
    "TheBloke/Mistral-7B-Instruct-v0.2-GGUF|mistral-7b-instruct-v0.2.Q4_K_M.gguf|7B|High quality model (~4GB)"
    "TheBloke/WizardMath-7B-v1.1-GGUF|wizardmath-7b-v1.1.Q4_K_M.gguf|7B|Excellent for math (~4GB)"
    "TheBloke/Llama-2-7B-Chat-GGUF|llama-2-7b-chat.Q4_K_M.gguf|7B|Meta's Llama 2 model (~4GB)"
)

# Initialize with defaults
MODEL_REPO="$DEFAULT_MODEL_REPO"
MODEL_FILE_NAME="$DEFAULT_MODEL_FILE_NAME"
MODEL_SIZE="1B"
MODEL_DESCRIPTION="Default small model"

# Script settings
DRY_RUN=0
VERBOSE=0

# GPU layer count constants (used in check_system_info)
GPU_LAYERS_HIGH=48   # For systems with >24GB RAM
GPU_LAYERS_MED=32    # For systems with 16-24GB RAM
GPU_LAYERS_LOW=24    # For systems with 8-16GB RAM
GPU_LAYERS_MIN=16    # For systems with <8GB RAM

# Memory threshold constants in MB
MEM_THRESH_HIGH=24000
MEM_THRESH_MED=16000
MEM_THRESH_LOW=8000

# Global server health flag — set by final_instructions_and_verification, read by final_test
server_ok=0

# --- Utility Functions ---
log_msg() {
    local msg="$1"; local level="${2:-INFO}"; local color_red="\033[0;31m"; local color_green="\033[0;32m"; local color_yellow="\033[0;33m"; local color_blue="\033[0;34m"; local color_reset="\033[0m"
    local timestamp; timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    case "$level" in INFO) echo -e "${color_blue}[$timestamp INFO]${color_reset} $msg" ;; WARNING) echo -e "${color_yellow}[$timestamp WARNING]${color_reset} $msg" ;; ERROR) echo -e "${color_red}[$timestamp ERROR]${color_reset} $msg" >&2 ;; SUCCESS) echo -e "${color_green}[$timestamp SUCCESS]${color_reset} $msg" ;; *) echo -e "[$timestamp $level] $msg" ;; esac
}
handle_error() { log_msg "$1" "ERROR"; if [ -n "${2:-}" ]; then log_msg "Suggestion: $2" "INFO"; fi; exit 1; }
prompt_yes_no() {
    local prompt_msg="$1"; local response; while true; do read -r -p "$prompt_msg [y/N]: " response; case "$response" in [yY][eE][sS]|[yY]) return 0 ;; [nN][oO]|[nN]|"") return 1 ;; *) log_msg "Invalid input." "WARNING" ;; esac; done
}
command_exists() { command -v "$1" &> /dev/null; }

test_metal_support() {
    log_msg "--- Testing Metal Support ---"

    # Simple Metal capability test using Swift
    log_msg "Testing Metal GPU support on your system..."

    # Create a temporary directory for the test
    local test_dir
    test_dir=$(mktemp -d)
    # Register EXIT trap to guarantee cleanup regardless of how this function returns
    # shellcheck disable=SC2064
    trap "rm -rf '$test_dir'" EXIT

    # Make sure we're in a valid directory to avoid getcwd errors
    cd "$HOME" 2>/dev/null || cd / 2>/dev/null || true
    cd "$test_dir" || return 1

    log_msg "Creating Swift Metal test..."
    # Create a simple Metal test script
    cat > metal_test.swift << 'EOL'
import Metal

guard let device = MTLCreateSystemDefaultDevice() else {
    print("Error: Could not create Metal device")
    exit(1)
}

print("✅ Metal is working!")
print("Device: \(device.name)")
print("Recommended max working set size: \(Double(device.recommendedMaxWorkingSetSize) / (1024.0 * 1024.0)) MB")
print("Has unified memory: \(device.hasUnifiedMemory)")
print("Registry ID: \(device.registryID)")
print("Location: \(device.location)")
print("Is low power: \(device.isLowPower)")
print("Is headless: \(device.isHeadless)")
print("Is removable: \(device.isRemovable)")
print("Max threads per threadgroup: \(device.maxThreadsPerThreadgroup)")
EOL

    log_msg "Running Swift Metal test..."

    # Check if Swift is available
    if ! command_exists "swift"; then
        log_msg "⚠️ Swift is not installed - cannot run direct Metal test" "WARNING"
        log_msg "Metal will be tested using llama-cli later" "INFO"

        # Check system_profiler as a fallback
        if command_exists "system_profiler"; then
            local gpu_info
            gpu_info=$(system_profiler SPDisplaysDataType 2>/dev/null | grep -i "Vendor Name:" || echo "")
            if [[ "$gpu_info" == *"AMD"* ]]; then
                log_msg "✅ Detected AMD GPU: $gpu_info (from system_profiler)" "SUCCESS"
                log_msg "This is compatible with Metal acceleration" "SUCCESS"
            else
                log_msg "⚠️ No AMD GPU detected in system_profiler output" "WARNING"
                log_msg "Output: $gpu_info" "INFO"
                log_msg "Metal acceleration might not work correctly" "WARNING"

                # Ask if user wants to continue anyway
                if ! prompt_yes_no "Continue installation despite potential GPU compatibility issues?"; then
                    cd "$HOME" || cd / || true
                    log_msg "Installation aborted due to potential GPU compatibility issue." "ERROR"
                    return 1
                fi
            fi
        fi

        cd "$HOME" || cd / || true
        return 0
    fi

    # Run the Swift Metal test
    local metal_output
    if metal_output=$(swift metal_test.swift 2>&1); then
        log_msg "✅ Metal test successful!" "SUCCESS"

        # Extract device info
        local device_name
        device_name=$(echo "$metal_output" | grep "Device:" | sed 's/Device: //')

        # Show relevant output
        echo "----------------------------------------"
        echo "$metal_output"
        echo "----------------------------------------"

        log_msg "✅ Detected Metal-compatible GPU: $device_name" "SUCCESS"

        # Check if this is an AMD GPU
        if [[ "$device_name" == *"AMD"* ]]; then
            log_msg "✅ AMD GPU detected - optimal for this script" "SUCCESS"
        else
            log_msg "⚠️ This does not appear to be an AMD GPU. Performance may vary." "WARNING"
            # Ask if user wants to continue
            if ! prompt_yes_no "Continue installation with non-AMD GPU?"; then
                cd "$HOME" || cd / || true
                log_msg "Installation aborted as requested." "INFO"
                return 1
            fi
        fi
    else
        local swift_exit=$?
        log_msg "❌ Metal test failed (exit code: $swift_exit)" "ERROR"
        log_msg "Metal is not working properly on your system" "ERROR"

        echo "Error output:"
        echo "----------------------------------------"
        echo "$metal_output"
        echo "----------------------------------------"

        log_msg "Your system may not support Metal or have proper GPU drivers installed" "WARNING"

        # Ask if user wants to continue anyway
        if ! prompt_yes_no "Continue installation despite Metal test failure?"; then
            cd "$HOME" || cd / || true
            log_msg "Installation aborted due to Metal test failure." "ERROR"
            return 1
        fi
    fi

    # Return to a known good directory (trap handles cleanup)
    cd "$HOME" || cd / || true
    # Clear the EXIT trap — cleanup already done or no longer needed
    trap - EXIT
    return 0
}

check_system_info() {
    log_msg "--- System Information Detection ---"
    
    # Check processor architecture
    local arch; arch=$(uname -m)
    
    # Check processor architecture
    if [[ "$arch" == "arm64" ]]; then
        IS_APPLE_SILICON=1
        PROCESSOR_TYPE="Apple Silicon"
        log_msg "Detected Apple Silicon processor ($arch)" "INFO"
        
        # Detect specific chipset if possible
        if command_exists "system_profiler"; then
            local chip_info; chip_info=$(system_profiler SPHardwareDataType 2>/dev/null | grep "Chip:" | sed 's/.*: //')
            if [[ -n "$chip_info" ]]; then
                log_msg "Chip details: $chip_info" "INFO"
                # Extract chip generation (M1, M2, M3) if available
                if [[ "$chip_info" == *"Apple M1"* ]]; then
                    APPLE_CHIP="M1"
                elif [[ "$chip_info" == *"Apple M2"* ]]; then
                    APPLE_CHIP="M2"
                elif [[ "$chip_info" == *"Apple M3"* ]]; then
                    APPLE_CHIP="M3"
                fi
                
                if [[ -n "$APPLE_CHIP" ]]; then
                    log_msg "Detected $APPLE_CHIP chip" "INFO"
                fi
            fi
        fi
        
        # Hard stop for Apple Silicon users - this script won't work for them
        log_msg "❌ DO NOT INSTALL ON APPLE SILICON MACS ❌" "ERROR"
        log_msg "This script is EXCLUSIVELY for Intel CPU with AMD GPU configurations." "ERROR"
        log_msg "It WILL NOT WORK on Apple Silicon Macs (M1/M2/M3)." "ERROR"
        log_msg "Installation aborted - incompatible hardware detected." "ERROR"
        return 1
    else
        IS_APPLE_SILICON=0
        PROCESSOR_TYPE="Intel"
        log_msg "Detected Intel processor ($arch)" "INFO"
        log_msg "This script is optimized for Intel CPU with AMD GPU configurations." "SUCCESS"
    fi
    
    # Get physical memory size
    MEM_SIZE_MB=$(sysctl -n hw.memsize 2>/dev/null | awk '{print int($1/1024/1024)}' || echo 0)
    log_msg "System memory: $MEM_SIZE_MB MB" "INFO"
    
    # Get macOS version
    if command_exists "sw_vers"; then
        OS_VERSION=$(sw_vers -productVersion)
        log_msg "macOS version: $OS_VERSION" "INFO"
        
        # Check minimum supported version (macOS 11 Big Sur for Metal MPS support)
        local major_version; major_version=$(echo "$OS_VERSION" | cut -d. -f1)
        if [[ $major_version -lt 11 ]]; then
            log_msg "Your macOS version ($OS_VERSION) may not fully support Metal Performance Shaders." "WARNING"
            log_msg "For best results, macOS 11 (Big Sur) or newer is recommended." "INFO"
            if ! prompt_yes_no "Continue anyway?"; then
                log_msg "Installation aborted by user." "WARNING"
                return 1
            fi
        fi
    fi
    
    # Get disk space information
    if command_exists "df"; then
        local home_disk_free; home_disk_free=$(df -h "$HOME" | awk 'NR==2 {print $4}')
        local home_disk_used_percent; home_disk_used_percent=$(df -h "$HOME" | awk 'NR==2 {print $5}' | tr -d '%')
        
        log_msg "Free disk space on $HOME: $home_disk_free" "INFO"
        
        # Warn if disk space is low (more than 90% used)
        if [[ $home_disk_used_percent -gt 90 ]]; then
            log_msg "Disk space is very low (${home_disk_used_percent}% used). This may cause problems when downloading models." "WARNING"
            if ! prompt_yes_no "Continue despite low disk space?"; then
                log_msg "Installation aborted by user." "WARNING"
                return 1
            fi
        fi
    fi
    
    # Check number of CPU cores
    NUM_CORES=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
    log_msg "CPU cores: $NUM_CORES" "INFO"
    
    # Based on the system info, determine optimal defaults
    if [ $IS_APPLE_SILICON -eq 1 ]; then
        # This should never be reached since we block Apple Silicon above, but just in case
        log_msg "❌ ERROR: Script running on Apple Silicon - this is not supported!" "ERROR"
        log_msg "This script WILL NOT WORK on Apple Silicon Macs." "ERROR"
        OPTIMAL_GPU_LAYERS=0
    else
        # Set optimal GPU layers for Intel CPU with AMD GPU based on memory
        if [[ $MEM_SIZE_MB -gt $MEM_THRESH_HIGH ]]; then  # 24GB+
            OPTIMAL_GPU_LAYERS=$GPU_LAYERS_HIGH
        elif [[ $MEM_SIZE_MB -gt $MEM_THRESH_MED ]]; then  # 16-24GB
            OPTIMAL_GPU_LAYERS=$GPU_LAYERS_MED
        elif [[ $MEM_SIZE_MB -gt $MEM_THRESH_LOW ]]; then  # 8-16GB
            OPTIMAL_GPU_LAYERS=$GPU_LAYERS_LOW
        else  # Less than 8GB
            OPTIMAL_GPU_LAYERS=$GPU_LAYERS_MIN
        fi
        
        log_msg "Determined optimal GPU layers for Intel CPU with AMD GPU: $OPTIMAL_GPU_LAYERS" "INFO"
        log_msg "This setting is specifically optimized for Intel CPU with AMD GPU configurations" "INFO"
    fi
    
    log_msg "System information detection completed." "SUCCESS"
    return 0
}

check_dependencies() {
    log_msg "--- Dependency Checks ---"
    local missing_deps=()
    local optional_missing=()
    
    # Essential dependencies
    log_msg "Checking essential dependencies..."
    for cmd in git curl python3 bash sed awk; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
            log_msg "Missing essential dependency: $cmd" "ERROR"
        else
            log_msg "✓ $cmd found: $(command -v "$cmd")" "INFO"
        fi
    done
    
    # Build dependencies
    log_msg "Checking build dependencies..."
    for cmd in cmake make; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
            log_msg "Missing build dependency: $cmd" "ERROR"
        else
            log_msg "✓ $cmd found: $(command -v "$cmd")" "INFO"
        fi
    done
    
    # Optional but recommended
    log_msg "Checking optional dependencies..."
    if ! command_exists "ninja"; then
        optional_missing+=("ninja")
        log_msg "Missing optional dependency: ninja (recommended)" "WARNING"
    else
        log_msg "✓ ninja found: $(command -v "ninja")" "INFO"
    fi
    
    # macOS specific checks
    log_msg "Checking macOS specific tools..."
    if ! command_exists "sw_vers"; then
        log_msg "This script is designed for macOS systems only" "ERROR"
        return 1
    fi
    
    # Check for launchctl (needed for service management)
    if ! command_exists "launchctl"; then
        optional_missing+=("launchctl")
        log_msg "launchctl not found. Service management will be disabled." "WARNING"
        log_msg "You will need to run the server manually using the direct run script." "WARNING"
    else
        log_msg "✓ launchctl found: $(command -v "launchctl")" "INFO"
    fi
    
    # Exit if any essential dependencies are missing
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log_msg "Essential dependencies missing: ${missing_deps[*]}" "ERROR"
        if [[ " ${missing_deps[*]} " == *" git "* ]]; then
            log_msg "To install git: brew install git or download from https://git-scm.com/download/mac" "INFO"
        fi
        if [[ " ${missing_deps[*]} " == *" cmake "* ]]; then
            log_msg "To install cmake: brew install cmake or download from https://cmake.org/download" "INFO"
        fi
        if [[ " ${missing_deps[*]} " == *" make "* ]]; then
            log_msg "To install make: Install Xcode Command Line Tools with: xcode-select --install" "INFO"
        fi
        if [[ " ${missing_deps[*]} " == *" python3 "* ]]; then
            log_msg "To install python3: brew install python or download from https://www.python.org/downloads" "INFO"
        fi
        return 1
    fi
    
    # Warn about optional dependencies
    if [ ${#optional_missing[@]} -gt 0 ]; then
        log_msg "Optional dependencies missing: ${optional_missing[*]}" "WARNING"
        log_msg "For best performance, consider installing them before continuing" "INFO"
        if [[ " ${optional_missing[*]} " == *" ninja "* ]]; then
            log_msg "To install ninja: brew install ninja" "INFO"
        fi
        if ! prompt_yes_no "Continue without optional dependencies?"; then
            log_msg "Installation aborted by user." "WARNING"
            return 1
        fi
    fi
    
    log_msg "All essential dependencies are available." "SUCCESS"
    return 0
}

# ENHANCED VERBOSITY for execute_command
execute_command() {
    log_msg "Preparing to execute: '$*'" "INFO"
    if [ "$DRY_RUN" -eq 1 ]; then log_msg "[DRY RUN] Would execute: '$*'" "INFO"; return 0; fi
    
    echo "----------------------------------------------------------------------"
    log_msg "EXECUTING COMMAND: '$*'" "INFO"
    echo "----------------------------------------------------------------------"
    # For extreme verbosity, uncomment the next line to see shell expansion
    # set -x
    "$@" # Execute the command
    local status=$?
    # set +x # Turn off xtrace if enabled
    echo "----------------------------------------------------------------------"
    log_msg "COMMAND FINISHED: '$*' with status $status" "INFO"
    echo "----------------------------------------------------------------------"
    
    if [ "$status" -ne 0 ]; then handle_error "Command failed: '$*' (status $status)"; fi
    return "$status"
}

# Initialize additional configuration variables
SECURE_MODE=0
VERBOSE=0

# Process command line arguments
for arg in "$@"; do
    case "$arg" in
        --dry-run|-n) DRY_RUN=1; log_msg "Dry run mode enabled." "INFO" ;;
        --verbose|-v) VERBOSE=1; log_msg "Verbose mode enabled." "INFO" ;;
        --secure|-s) SECURE_MODE=1; log_msg "Secure mode enabled (localhost only)." "INFO" ;;
        --help|-h) 
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  --dry-run, -n      Show commands without executing them"
            echo "  --verbose, -v      Enable detailed output for debugging"
            echo "  --secure, -s       Configure server for localhost only (no network access)"
            echo "  --help, -h         Show this help message"
            exit 0
            ;;
    esac
done

get_huggingface_token() {
    log_msg "--- Hugging Face Token Setup ---"
    if [ -n "${HF_TOKEN:-}" ]; then HUGGINGFACE_TOKEN="$HF_TOKEN"; log_msg "Using HF_TOKEN from env."
    elif [ -n "${HUGGINGFACE_TOKEN_READ_ONLY:-}" ]; then HUGGINGFACE_TOKEN="$HUGGINGFACE_TOKEN_READ_ONLY"; log_msg "Using HUGGINGFACE_TOKEN_READ_ONLY from env."
    elif [ -n "${HUGGINGFACE_TOKEN:-}" ]; then log_msg "Using HUGGINGFACE_TOKEN from env."
    elif [ -f "$HOME/.cache/huggingface/token" ]; then HUGGINGFACE_TOKEN=$(cat "$HOME/.cache/huggingface/token"); log_msg "Using token from cache: $HOME/.cache/huggingface/token"
    else
        log_msg "No Hugging Face token found in environment variables or cache."
        echo "A Hugging Face token is required to download the model. You can create one at: https://huggingface.co/settings/tokens"
        read -rs -p "Please enter your Hugging Face token (it won't be displayed): " HUGGINGFACE_TOKEN_INPUT; echo ""
        if [ -z "$HUGGINGFACE_TOKEN_INPUT" ]; then handle_error "No Hugging Face token provided." "Set HF_TOKEN or re-run."; fi
        HUGGINGFACE_TOKEN="$HUGGINGFACE_TOKEN_INPUT"
    fi
    if [[ "$HUGGINGFACE_TOKEN" != hf_* ]] || { [ "${#HUGGINGFACE_TOKEN}" -lt 30 ] || [ "${#HUGGINGFACE_TOKEN}" -gt 100 ]; }; then
        log_msg "Token format or length seems unusual for a Hugging Face token." "WARNING"
        # Redact the token — show only the first 4 characters to avoid leaking the secret
        local token_preview="${HUGGINGFACE_TOKEN:0:4}****"
        if ! prompt_yes_no "Token starts with '${token_preview}' (${#HUGGINGFACE_TOKEN} chars). Proceed with this token anyway?"; then handle_error "Token validation failed by user."; fi
    fi
    log_msg "Hugging Face token configured." "SUCCESS"; export HUGGINGFACE_TOKEN
}

select_model() {
    log_msg "--- Model Selection ---"
    local choice
    
    # Display model options with nice formatting
    echo ""
    echo "Available LLaMA models for MPS/Metal:"
    echo "--------------------------------------"
    echo " #  | Size | Description"
    echo "----+------+-------------"
    
    # Display the models
    local i=1
    for model_info in "${RECOMMENDED_MODELS[@]}"; do
        # Parse the model info string
        IFS='|' read -r repo file size description <<< "$model_info"
        printf " %2d | %4s | %s\n" "$i" "$size" "$description"
        i=$((i+1))
    done
    
    echo "--------------------------------------"
    echo "Models with larger parameter sizes provide better quality but require more RAM and processing time."
    echo "For most Apple Silicon Macs with 16GB RAM, models up to 8B work well."
    echo "For Macs with 8GB RAM, stick to 3B or smaller models."
    echo ""
    
    # Ask for selection
    local valid_choice=0
    while [ "$valid_choice" -eq 0 ]; do
        read -r -p "Select a model by number (1-$((i-1))) or press Enter for default (1): " choice
        
        # Default to the first option
        if [ -z "$choice" ]; then 
            choice=1
            valid_choice=1
        # Check if the choice is a number and within range
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le $((i-1)) ]; then
            valid_choice=1
        else
            log_msg "Invalid selection. Please enter a number between 1 and $((i-1))." "WARNING"
        fi
    done
    
    # Set the selected model
    local selected_model=${RECOMMENDED_MODELS[$((choice-1))]}
    IFS='|' read -r MODEL_REPO MODEL_FILE_NAME MODEL_SIZE MODEL_DESCRIPTION <<< "$selected_model"
    
    log_msg "Selected model: $MODEL_FILE_NAME ($MODEL_SIZE, $MODEL_DESCRIPTION)" "SUCCESS"
    echo "Model repository: $MODEL_REPO"
    echo "Model file name: $MODEL_FILE_NAME"
    echo ""
    
    # Check system compatibility
    check_model_compatibility "$MODEL_SIZE"
    
    return 0
}

check_model_compatibility() {
    local model_size="$1"
    local mem_size_mb
    
    log_msg "Checking system compatibility for $model_size model..."
    
    # Get physical memory size in MB
    mem_size_mb=$(sysctl -n hw.memsize 2>/dev/null | awk '{print int($1/1024/1024)}' || echo 0)
    log_msg "System memory: $mem_size_mb MB" "INFO"
    
    # Check memory compatibility based on model size
    case "$model_size" in
        "1B")
            # 1B models are fine on all systems
            log_msg "Memory check passed: 1B model is compatible with all systems" "SUCCESS"
            ;;
        "3B")
            # 3B models need at least 8GB RAM
            if [ "$mem_size_mb" -lt 8000 ]; then
                log_msg "System has less than 8GB RAM. 3B models might run slowly." "WARNING"
                if ! prompt_yes_no "Continue with this model despite limited RAM?"; then
                    log_msg "Please select a smaller model (1B)" "INFO"
                    select_model
                    return $?
                fi
            else
                log_msg "Memory check passed: 3B model should work well" "SUCCESS"
            fi
            ;;
        "7B"|"8B")
            # 7B/8B models need at least 16GB RAM for good performance
            if [ "$mem_size_mb" -lt 16000 ]; then
                log_msg "System has less than 16GB RAM. $model_size models might be too large for your system." "WARNING"
                if ! prompt_yes_no "Continue with this model despite limited RAM?"; then
                    log_msg "Please select a smaller model (1B or 3B)" "INFO"
                    select_model
                    return $?
                fi
            else
                log_msg "Memory check passed: $model_size model should work well" "SUCCESS"
            fi
            ;;
        *)
            log_msg "Unknown model size. Skipping compatibility check." "WARNING"
            ;;
    esac
    
    return 0
}

setup_conda_env() {
    local conda_env_name="$1"; local python_version="$2"; local conda_path=""
    log_msg "--- Conda Environment Setup ---"
    log_msg "Detecting Conda installation..."
    if [ -n "${CONDA_PREFIX:-}" ] && [ -f "$CONDA_PREFIX/etc/profile.d/conda.sh" ]; then conda_path="$CONDA_PREFIX"; log_msg "Using active CONDA_PREFIX: $conda_path"
    else
        local potential_paths=("$HOME/miniconda3" "$HOME/miniconda" "$HOME/opt/miniconda3" "$HOME/anaconda3" "$HOME/anaconda" "/opt/homebrew/Caskroom/miniconda/base");
        for p in "${potential_paths[@]}"; do if [ -d "$p" ] && [ -f "$p/etc/profile.d/conda.sh" ]; then conda_path="$p"; log_msg "Found Conda at: $conda_path"; break; fi; done
    fi
    if [ -z "$conda_path" ]; then
        log_msg "Conda installation not found in common locations."
        read -r -p "Please enter the full path to your Conda installation, or press Enter to fail: " conda_path
        if [ ! -d "$conda_path" ] || [ ! -f "$conda_path/etc/profile.d/conda.sh" ]; then handle_error "Invalid Conda path provided or no path entered."; fi
        log_msg "Using user-provided Conda path: $conda_path"
    fi
    log_msg "Sourcing Conda profile script: $conda_path/etc/profile.d/conda.sh"
    # shellcheck source=/dev/null
    source "$conda_path/etc/profile.d/conda.sh"; CONDA_PATH_RESOLVED="$conda_path"
    if ! command_exists "conda"; then handle_error "Conda command not found after sourcing profile."; fi
    log_msg "Conda sourced successfully. CONDA_PATH_RESOLVED=$CONDA_PATH_RESOLVED"
    
    export CONDA_MKL_INTERFACE_LAYER_BACKUP=""; export CONDA_MKL_NUM_THREADS_BACKUP=""
    log_msg "Exported CONDA_MKL_INTERFACE_LAYER_BACKUP and CONDA_MKL_NUM_THREADS_BACKUP as empty strings."

    log_msg "Checking for Conda environment: '$conda_env_name_resolved'"
    if ! conda env list | grep -qF "$conda_env_name_resolved"; then
        log_msg "Conda environment '$conda_env_name_resolved' not found."
        if prompt_yes_no "Create conda environment '$conda_env_name_resolved' with Python $python_version_resolved?"; then
            log_msg "Creating Conda environment '$conda_env_name_resolved' with Python $python_version_resolved..."
            execute_command conda create -n "$conda_env_name_resolved" python="$python_version_resolved" -y
            log_msg "Conda environment '$conda_env_name_resolved' created." "SUCCESS"
        else handle_error "Conda environment creation declined by user."; fi
    else log_msg "Using existing Conda environment '$conda_env_name_resolved'."; fi
    
    log_msg "Activating Conda environment: '$conda_env_name_resolved'"
    execute_command conda activate "$conda_env_name_resolved"
    log_msg "Activated Conda environment: $conda_env_name_resolved" "SUCCESS"
    
    export CONDA_MKL_INTERFACE_LAYER_BACKUP="${CONDA_MKL_INTERFACE_LAYER_BACKUP:-}"; export CONDA_MKL_NUM_THREADS_BACKUP="${CONDA_MKL_NUM_THREADS_BACKUP:-}"
    log_msg "Re-exported MKL backup vars to ensure they are set."

    log_msg "Installing core Conda packages into '$conda_env_name_resolved'..."
    execute_command conda install -y -c conda-forge -c pytorch numpy=1.23.5 pandas=1.5.3 matplotlib jupyter pytorch torchvision torchaudio 
    log_msg "Core Conda packages installed." "SUCCESS"
    
    log_msg "Installing core pip packages into '$conda_env_name_resolved'..."
    execute_command pip install tensorflow-macos==2.12.0 tensorflow-metal cmake ninja huggingface_hub==0.26.1
    log_msg "Core pip packages installed." "SUCCESS"
    log_msg "Conda environment setup complete." "SUCCESS"
}

check_secure_permissions() {
    local path="$1"
    local expected_perm="$2"
    local name="$3"
    
    if [ ! -e "$path" ]; then
        log_msg "Path not found for permission check: $path" "WARNING"
        return 1
    fi
    
    # stat flag differs between BSD (macOS) and GNU/Linux
    local current_perm
    if [[ "$(uname)" == "Darwin" ]]; then
        current_perm=$(stat -f "%Lp" "$path")
    else
        current_perm=$(stat -c "%a" "$path")
    fi
    
    if [ "$current_perm" != "$expected_perm" ]; then
        log_msg "Security warning: $name ($path) has permissions $current_perm, expected $expected_perm" "WARNING"
        if prompt_yes_no "Set correct permissions for $name?"; then
            execute_command chmod "$expected_perm" "$path"
            log_msg "Permissions updated for $name" "SUCCESS"
        else
            log_msg "Left $name with permissions $current_perm instead of recommended $expected_perm" "WARNING"
        fi
    else
        log_msg "✓ $name has correct permissions: $expected_perm" "INFO"
    fi
    
    return 0
}

prepare_directories_and_backup() {
    log_msg "--- Directory Preparation and Backup ---"
    log_msg "Ensuring base llama.cpp directory exists: $LLAMA_CPP_FULL_PATH"
    if [ ! -d "$LLAMA_CPP_FULL_PATH" ]; then 
        log_msg "Creating base directory: $LLAMA_CPP_FULL_PATH"
        execute_command mkdir -p "$LLAMA_CPP_FULL_PATH"
        execute_command chmod 750 "$LLAMA_CPP_FULL_PATH"
    else 
        log_msg "Base directory $LLAMA_CPP_FULL_PATH already exists."
        # Check and fix permissions
        check_secure_permissions "$LLAMA_CPP_FULL_PATH" "750" "llama.cpp directory"
    fi
    
    log_msg "Ensuring configuration directory exists: $CONFIG_DIR"
    if [ ! -d "$CONFIG_DIR" ]; then 
        execute_command mkdir -p "$CONFIG_DIR"
        execute_command chmod 700 "$CONFIG_DIR"
    else 
        log_msg "Config directory $CONFIG_DIR already exists."
        # Ensure config directory is secure (700 = owner only)
        check_secure_permissions "$CONFIG_DIR" "700" "config directory"
    fi
    
    log_msg "Ensuring log directory exists: $LOG_DIR"
    if [ ! -d "$LOG_DIR" ]; then 
        execute_command mkdir -p "$LOG_DIR"
        execute_command chmod 700 "$LOG_DIR"
    else 
        log_msg "Log directory $LOG_DIR already exists."
        # Ensure log directory is secure (700 = owner only)
        check_secure_permissions "$LOG_DIR" "700" "log directory"
    fi

    log_msg "Ensuring models directory exists: $MODELS_INSTALL_FULL_PATH"
    if [ ! -d "$MODELS_INSTALL_FULL_PATH" ]; then 
        execute_command mkdir -p "$MODELS_INSTALL_FULL_PATH"
        execute_command chmod 750 "$MODELS_INSTALL_FULL_PATH"
    else 
        log_msg "Models directory $MODELS_INSTALL_FULL_PATH already exists."
        # Ensure models directory has correct permissions (750 = readable by owner and group)
        check_secure_permissions "$MODELS_INSTALL_FULL_PATH" "750" "models directory"
    fi

    local service_debug_log="$LOG_DIR/service_debug.log" 
    log_msg "Initializing service debug log: $service_debug_log"
    if [ "$DRY_RUN" -eq 0 ]; then 
        echo "--- New Script Run $(date) ---" > "$service_debug_log"
        chmod 600 "$service_debug_log"
        # Ensure log files have correct permissions (600 = owner only)
        check_secure_permissions "$service_debug_log" "600" "service debug log"
    else 
        log_msg "[DRY_RUN] Would initialize $service_debug_log"
    fi
    
    local old_llama_config_dir="$HOME/.llama"; 
    if [ -d "$old_llama_config_dir" ]; then 
        local backup_dir
        backup_dir="$HOME/.llama.bak-$(date +"%Y%m%d-%H%M%S")"
        if prompt_yes_no "Old config dir $old_llama_config_dir found. Backup to $backup_dir?"; then 
            execute_command mv "$old_llama_config_dir" "$backup_dir"
            log_msg "Backed up $old_llama_config_dir to $backup_dir" "SUCCESS"
            # Set secure permissions on the backup
            execute_command chmod 700 "$backup_dir"
        else 
            log_msg "Skipped backup of $old_llama_config_dir." "WARNING"
        fi
    else
        log_msg "No old config directory $old_llama_config_dir found to backup."
    fi
    
    log_msg "Directory preparation and backup checks complete." "SUCCESS"
}

install_and_build_llamacpp() {
    log_msg "--- llama.cpp Installation and Build ---"
    
    # FIXED: Check if directory exists AND contains CMakeLists.txt
    if [ -d "$LLAMA_CPP_FULL_PATH" ] && [ -f "$LLAMA_CPP_FULL_PATH/CMakeLists.txt" ]; then
        log_msg "Using existing llama.cpp directory: $LLAMA_CPP_FULL_PATH"
    else
        # Directory doesn't exist or doesn't have repository content
        if [ -d "$LLAMA_CPP_FULL_PATH" ]; then
            log_msg "Directory exists but doesn't contain a valid llama.cpp repository, removing it..."
            execute_command rm -rf "$LLAMA_CPP_FULL_PATH"
        fi
        log_msg "Cloning llama.cpp repository to $LLAMA_CPP_FULL_PATH..."
        # NOTE: Trust model: TLS certificate on github.com. No additional integrity verification.
        # Cloning the default branch (master) for latest Metal support.
        execute_command git clone https://github.com/ggerganov/llama.cpp.git "$LLAMA_CPP_FULL_PATH"

        # Pin to the latest stable release tag to ensure reproducible builds
        log_msg "Fetching tags to pin to latest stable release..."
        local latest_tag
        latest_tag=$(git -C "$LLAMA_CPP_FULL_PATH" describe --tags "$(git -C "$LLAMA_CPP_FULL_PATH" rev-list --tags --max-count=1)" 2>/dev/null || echo "")
        if [ -n "$latest_tag" ]; then
            log_msg "Checking out latest stable tag: $latest_tag"
            git -C "$LLAMA_CPP_FULL_PATH" checkout "$latest_tag"
            log_msg "Pinned to tag: $latest_tag" "SUCCESS"
        else
            log_msg "No tags found in repo — using default branch HEAD." "WARNING"
        fi
    fi
    
    log_msg "Changing directory to $LLAMA_CPP_FULL_PATH"
    cd "$HOME" || cd / || true  # Make sure we're in a valid directory first
    cd "$LLAMA_CPP_FULL_PATH" || handle_error "Failed to change directory to $LLAMA_CPP_FULL_PATH"
    
    local build_path="$LLAMA_CPP_FULL_PATH/$BUILD_DIR_NAME"
    log_msg "Checking build directory: $build_path"
    if [ -d "$build_path" ] && [ "$(ls -A "$build_path")" ]; then 
        log_msg "Build directory $build_path exists and is not empty."
        if prompt_yes_no "Clean existing build directory $build_path before rebuilding?"; then 
            log_msg "Cleaning build directory: $build_path"
            execute_command rm -rf "${build_path:?}"/*; log_msg "Build directory cleaned." "SUCCESS";
        else log_msg "Proceeding with existing non-empty build directory."; fi
    elif [ ! -d "$build_path" ]; then 
        log_msg "Creating build directory: $build_path"
        execute_command mkdir -p "$build_path"; 
    else
        log_msg "Build directory $build_path exists and is empty."
    fi
    
    log_msg "Changing directory to build directory: $build_path"
    # Make sure we're in a valid directory first
    cd "$HOME" || cd / || true
    cd "$build_path" || handle_error "Failed to change directory to build path: $build_path"
    
    log_msg "Configuring llama.cpp build with Metal support using CMake..."
    execute_command cmake .. -DGGML_METAL=ON -DCMAKE_BUILD_TYPE=Release
    log_msg "CMake configuration complete." "SUCCESS"
    
    log_msg "Building llama.cpp using CMake --build..."
    local num_cores; num_cores=$(sysctl -n hw.ncpu 2>/dev/null || echo 4)
    log_msg "Using $num_cores cores for compilation."
    execute_command cmake --build . --config Release -j "$num_cores"
    log_msg "Initial llama.cpp build complete." "SUCCESS"
    
    local server_binary_path="$build_path/bin/llama-server"
    log_msg "Checking for llama-server binary at: $server_binary_path"
    if [ ! -f "$server_binary_path" ]; then 
        log_msg "llama-server binary not found. Attempting to build target 'llama-server' specifically..." "WARNING"
        execute_command cmake --build . --config Release -j "$num_cores" --target llama-server; 
        if [ ! -f "$server_binary_path" ]; then handle_error "Failed to build llama-server executable at $server_binary_path after specific target build."; fi
        log_msg "llama-server binary built successfully after specific target build." "SUCCESS"
    else
        log_msg "llama-server binary found at $server_binary_path." "SUCCESS"
    fi
    log_msg "llama.cpp installation and build process complete." "SUCCESS"
}

download_model() {
    log_msg "--- Model Download ---"
    log_msg "Target model directory: $MODELS_INSTALL_FULL_PATH"
    # This directory should have been created in prepare_directories_and_backup
    if [ ! -d "$MODELS_INSTALL_FULL_PATH" ]; then 
        log_msg "Model directory $MODELS_INSTALL_FULL_PATH not found. This is unexpected." "ERROR"
        handle_error "Model directory $MODELS_INSTALL_FULL_PATH was not created." "Check prepare_directories_and_backup function."
    fi
    
    log_msg "Changing directory to $MODELS_INSTALL_FULL_PATH"
    # Make sure we're in a valid directory first
    cd "$HOME" || cd / || true
    # Change to models directory with error handling
    cd "$MODELS_INSTALL_FULL_PATH" || handle_error "Failed to change directory to models path: $MODELS_INSTALL_FULL_PATH"
    
    local model_file_path="$MODELS_INSTALL_FULL_PATH/$MODEL_FILE_NAME"
    log_msg "Checking for existing model file: $model_file_path"
    if [ -f "$model_file_path" ]; then 
        log_msg "Model file $MODEL_FILE_NAME already exists in $MODELS_INSTALL_FULL_PATH."
        if ! prompt_yes_no "Skip downloading the model?"; then 
            log_msg "Proceeding to re-download model $MODEL_FILE_NAME."
            execute_command rm -f "$model_file_path"; 
        else 
            log_msg "Skipping model download as per user choice."; return 0; 
        fi; 
    fi
    
    if [ -z "${HUGGINGFACE_TOKEN:-}" ]; then 
        log_msg "Hugging Face token not set, attempting to get it now..."
        get_huggingface_token; 
    fi
    
    log_msg "Starting download of $MODEL_FILE_NAME from $MODEL_REPO using huggingface-cli..."
    # Call huggingface-cli directly (not via execute_command) to prevent token from being
    # logged in the verbose command echo. Token passed via HF_TOKEN env var to also
    # avoid exposure in the process table (ps aux).
    if [ "$DRY_RUN" -eq 1 ]; then
        log_msg "[DRY RUN] Would execute: huggingface-cli download [TOKEN REDACTED] $MODEL_REPO $MODEL_FILE_NAME --local-dir . --local-dir-use-symlinks False" "INFO"
    else
        log_msg "EXECUTING COMMAND: huggingface-cli download [TOKEN REDACTED] $MODEL_REPO $MODEL_FILE_NAME --local-dir . --local-dir-use-symlinks False" "INFO"
        HF_TOKEN="$HUGGINGFACE_TOKEN" huggingface-cli download "$MODEL_REPO" "$MODEL_FILE_NAME" \
            --local-dir . --local-dir-use-symlinks False \
            || handle_error "huggingface-cli download failed for $MODEL_FILE_NAME from $MODEL_REPO."
        log_msg "COMMAND FINISHED: huggingface-cli download with status $?" "INFO"
    fi
    
    if [ ! -f "$MODEL_FILE_NAME" ]; then handle_error "Model download failed. File $MODEL_FILE_NAME not found in $MODELS_INSTALL_FULL_PATH after download attempt."; fi
    log_msg "Model $MODEL_FILE_NAME downloaded successfully to $MODELS_INSTALL_FULL_PATH." "SUCCESS"
}

manage_launchd_service() {
    log_msg "--- Launchd Service Management (bootstrap/bootout) ---"
    if ! command_exists "launchctl"; then log_msg "launchctl command not found. Skipping service management." "WARNING"; return 1; fi
    
    local user_uid; user_uid=$(id -u); log_msg "Current User UID: $user_uid"
    local service_domain="gui/$user_uid"; log_msg "Service Domain: $service_domain"
    local service_target_label="$service_domain/$SERVICE_LABEL"; log_msg "Service Target Label: $service_target_label"

    log_msg "Checking for existing service definition: $SERVICE_LABEL in domain $service_domain"
    if launchctl print "$service_target_label" &> /dev/null; then
        log_msg "Service definition for $SERVICE_LABEL found. Attempting to bootout (unload) the service..."
        if ! launchctl bootout "$service_target_label" &> /dev/null; then
            log_msg "launchctl bootout by label '$service_target_label' failed or service was not running. This might be okay." "WARNING"
        else
            log_msg "Successfully unloaded service by label." "SUCCESS"
        fi
        
        if [ -f "$SERVICE_PLIST_PATH" ]; then 
            log_msg "Attempting to bootout by path as a fallback..."
            if ! launchctl bootout "$service_domain" "$SERVICE_PLIST_PATH" &> /dev/null; then
                log_msg "launchctl bootout by path '$SERVICE_PLIST_PATH' also failed or service was not running by that definition. This might be okay." "WARNING"
            else
                log_msg "Successfully unloaded service by path." "SUCCESS"
            fi
        fi
        
        log_msg "Waiting a moment after bootout attempt..."
        sleep 2 
    else
        log_msg "No existing service definition found for $SERVICE_LABEL in domain $service_domain."
    fi

    if [ -f "$SERVICE_PLIST_PATH" ]; then 
        log_msg "Removing existing service plist file: $SERVICE_PLIST_PATH"
        execute_command rm -f "$SERVICE_PLIST_PATH"; 
    fi

    log_msg "Creating server run script: $RUN_SERVER_SCRIPT_PATH"
    if [ -z "${CONDA_PATH_RESOLVED:-}" ]; then handle_error "CONDA_PATH_RESOLVED is not set. Conda setup might have failed."; fi

    local server_binary_full_path="$LLAMA_CPP_FULL_PATH/$BUILD_DIR_NAME/bin/llama-server"
    local absolute_model_path_for_scripts="$MODELS_INSTALL_FULL_PATH/$MODEL_FILE_NAME" 
    local service_debug_log="$LOG_DIR/service_debug.log"
    
    # Make sure OPTIMAL_GPU_LAYERS is defined before using it in the script
    export OPTIMAL_GPU_LAYERS="${OPTIMAL_GPU_LAYERS:-1}"
    log_msg "Using optimal GPU layers: $OPTIMAL_GPU_LAYERS for service configuration"
    
    log_msg "Generating content for $RUN_SERVER_SCRIPT_PATH..."
    execute_command tee "$RUN_SERVER_SCRIPT_PATH" > /dev/null <<EOF
#!/bin/bash
# ---- Variable expansion notes for this heredoc ----
# Variables WITHOUT backslash (e.g. $CONDA_PATH_RESOLVED) expand NOW at installer time.
# Variables WITH backslash (e.g. \$SERVER_BIN) expand at RUNTIME when this script runs.
# -------------------------------------------------------
# Debug log for this script: $service_debug_log
echo "--- run_server.sh started at \$(date) ---" >> "$service_debug_log"
echo "Attempting to set strict mode..." >> "$service_debug_log"
set -euo pipefail || { echo "[\$(date)] Failed to set strict mode" >> "$service_debug_log"; exit 1; }
echo "Strict mode set." >> "$service_debug_log"

echo "CONDA_PATH_RESOLVED=${CONDA_PATH_RESOLVED}" >> "$service_debug_log"
echo "conda_env_name_resolved=${conda_env_name_resolved:-$DEFAULT_CONDA_ENV_NAME}" >> "$service_debug_log"
echo "LOG_DIR=${LOG_DIR}" >> "$service_debug_log"
echo "USER=\$(whoami); UID=\$(id -u); HOME=\$HOME" >> "$service_debug_log"
echo "Initial PATH=\$PATH" >> "$service_debug_log"

if [ -f "${CONDA_PATH_RESOLVED}/etc/profile.d/conda.sh" ]; then
    echo "Sourcing Conda: ${CONDA_PATH_RESOLVED}/etc/profile.d/conda.sh" >> "$service_debug_log"
    # shellcheck source=/dev/null
    source "${CONDA_PATH_RESOLVED}/etc/profile.d/conda.sh"
else
    echo "\$(date): ERROR - Conda profile script not found: ${CONDA_PATH_RESOLVED}/etc/profile.d/conda.sh" >> "${LOG_DIR}/service_error.log"
    echo "[\$(date)] ERROR - Conda profile script not found" >> "$service_debug_log"; exit 1;
fi
echo "Conda sourced." >> "$service_debug_log"

export CONDA_MKL_INTERFACE_LAYER_BACKUP="\${CONDA_MKL_INTERFACE_LAYER_BACKUP:-}"
export CONDA_MKL_NUM_THREADS_BACKUP="\${CONDA_MKL_NUM_THREADS_BACKUP:-}"
export SECURE_MODE="${SECURE_MODE:-0}"
export OPTIMAL_GPU_LAYERS="${OPTIMAL_GPU_LAYERS:-1}"
echo "MKL Vars: \$CONDA_MKL_INTERFACE_LAYER_BACKUP, \$CONDA_MKL_NUM_THREADS_BACKUP" >> "$service_debug_log"
echo "Security Mode: \$SECURE_MODE (1=localhost only, 0=network accessible)" >> "$service_debug_log"
echo "GPU Layers: \$OPTIMAL_GPU_LAYERS" >> "$service_debug_log"

echo "Activating Conda env: ${conda_env_name_resolved:-$DEFAULT_CONDA_ENV_NAME}" >> "$service_debug_log"
conda activate "${conda_env_name_resolved:-$DEFAULT_CONDA_ENV_NAME}" || {
    echo "\$(date): ERROR - Failed to activate Conda env '${conda_env_name_resolved:-$DEFAULT_CONDA_ENV_NAME}'" >> "${LOG_DIR}/service_error.log"
    echo "[\$(date)] ERROR - Failed to activate Conda env" >> "$service_debug_log"; exit 1;
}
echo "Conda env activated. PATH after activate: \$PATH" >> "$service_debug_log"
echo "which python: \$(which python)" >> "$service_debug_log"
echo "python version: \$(python --version)" >> "$service_debug_log"

SERVER_BIN="$server_binary_full_path"
MODEL_PATH_ABS="$absolute_model_path_for_scripts" 
SERVER_LOG_DIR="$LOG_DIR" 

echo "SERVER_BIN=\${SERVER_BIN}" >> "$service_debug_log"
echo "MODEL_PATH_ABS=\${MODEL_PATH_ABS}" >> "$service_debug_log"

if [ ! -f "\$SERVER_BIN" ]; then
    echo "\$(date): ERROR - llama-server executable not found at \$SERVER_BIN" >> "\$SERVER_LOG_DIR/service_error.log"
    echo "[\$(date)] ERROR - llama-server not found at \$SERVER_BIN" >> "$service_debug_log"; exit 1;
fi
if [ ! -f "\$MODEL_PATH_ABS" ]; then
    echo "\$(date): ERROR - Model file not found at \$MODEL_PATH_ABS" >> "\$SERVER_LOG_DIR/service_error.log"
    echo "[\$(date)] ERROR - Model file not found at \$MODEL_PATH_ABS" >> "$service_debug_log"; exit 1;
fi

echo "Current working directory (from run_server.sh): \$(pwd)" >> "$service_debug_log"
echo "Expected working directory (from plist): $(dirname "$server_binary_full_path")" >> "$service_debug_log"

echo "\$(date): Starting llama-server with model \$MODEL_PATH_ABS..." >> "\$SERVER_LOG_DIR/service_output.log"
# Determine hostname based on secure mode
HOST_BINDING="0.0.0.0"
if [ "${SECURE_MODE:-0}" -eq 1 ]; then
    HOST_BINDING="127.0.0.1"
    echo "\$(date): Using secure mode - binding to localhost only" >> "\$SERVER_LOG_DIR/service_output.log"
else
    echo "\$(date): SECURITY WARNING - Server is accessible from the network at \$HOST_BINDING:8080" >> "\$SERVER_LOG_DIR/service_output.log"
fi

# Get optimal GPU layers from environment or use default based on system
GPU_LAYERS="\${OPTIMAL_GPU_LAYERS:-1}"
echo "\$(date): Using GPU layers: \$GPU_LAYERS" >> "\$SERVER_LOG_DIR/service_output.log"

echo "Executing: \$SERVER_BIN -m \"\$MODEL_PATH_ABS\" --port 8080 --host \$HOST_BINDING --n-gpu-layers \$GPU_LAYERS --ctx-size 8192 --repeat-penalty 1.1 --chat-template llama3 --verbose" >> "$service_debug_log"

"\$SERVER_BIN" -m "\$MODEL_PATH_ABS" \\
    --port 8080 \\
    --host "\$HOST_BINDING" \\
    --n-gpu-layers \$GPU_LAYERS \\
    --ctx-size 8192 \\
    --repeat-penalty 1.1 \\
    --chat-template llama3 \\
    --verbose >> "\$SERVER_LOG_DIR/service_output.log" 2>> "\$SERVER_LOG_DIR/service_error.log"

SERVER_EXIT_CODE=\$?
echo "\$(date): Server stopped or crashed. Exit code \$SERVER_EXIT_CODE" >> "\$SERVER_LOG_DIR/service_crash.log"
echo "[\$(date)] Server process finished with exit code \$SERVER_EXIT_CODE." >> "$service_debug_log"
exit \$SERVER_EXIT_CODE 
EOF
    log_msg "Setting $RUN_SERVER_SCRIPT_PATH as executable with secure permissions"
    execute_command chmod 700 "$RUN_SERVER_SCRIPT_PATH"
    check_secure_permissions "$RUN_SERVER_SCRIPT_PATH" "700" "server run script"

    log_msg "Creating launchd plist file: $SERVICE_PLIST_PATH"
    execute_command tee "$SERVICE_PLIST_PATH" > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$SERVICE_LABEL</string>
    <key>ProgramArguments</key>
    <array><string>$RUN_SERVER_SCRIPT_PATH</string></array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><dict><key>SuccessfulExit</key><false/><key>Crashed</key><true/></dict>
    <key>StandardErrorPath</key><string>${LOG_DIR}/launchd_error.log</string>
    <key>StandardOutPath</key><string>${LOG_DIR}/launchd_output.log</string>
    <key>WorkingDirectory</key><string>$(dirname "$server_binary_full_path")</string> 
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key><string>/usr/bin:/bin:/usr/sbin:/sbin:\${CONDA_PATH_RESOLVED}/bin:\${HOME}/.local/bin</string>
        <key>USER</key><string>$(whoami)</string>
        <key>HOME</key><string>$HOME</string>
        <key>CONDA_MKL_INTERFACE_LAYER_BACKUP</key><string></string>
        <key>CONDA_MKL_NUM_THREADS_BACKUP</key><string></string>
        <key>SECURE_MODE</key><string>${SECURE_MODE:-0}</string>
        <key>OPTIMAL_GPU_LAYERS</key><string>${OPTIMAL_GPU_LAYERS:-1}</string>
    </dict>
    <key>ThrottleInterval</key><integer>10</integer> 
</dict>
</plist>
EOF
    log_msg "Launchd plist file $SERVICE_PLIST_PATH created."
    execute_command chmod 644 "$SERVICE_PLIST_PATH"
    check_secure_permissions "$SERVICE_PLIST_PATH" "644" "launchd plist file"

    log_msg "Bootstrapping launchd service: $SERVICE_LABEL into domain $service_domain using plist $SERVICE_PLIST_PATH"
    execute_command launchctl bootstrap "$service_domain" "$SERVICE_PLIST_PATH"
    
    log_msg "launchd service $SERVICE_LABEL bootstrapped. It should attempt to start automatically." "SUCCESS"
    log_msg "Check logs in $LOG_DIR, especially service_debug.log, for startup details."
    return 0
}

create_helper_scripts() {
    log_msg "--- Creating Helper Scripts ---"
    local server_binary_full_path="$LLAMA_CPP_FULL_PATH/$BUILD_DIR_NAME/bin/llama-server"
    local absolute_model_path_for_scripts="$MODELS_INSTALL_FULL_PATH/$MODEL_FILE_NAME" 

    log_msg "Creating direct run script: $DIRECT_RUN_SCRIPT_PATH"
    # Make sure OPTIMAL_GPU_LAYERS is defined 
    export OPTIMAL_GPU_LAYERS="${OPTIMAL_GPU_LAYERS:-1}"
    log_msg "Using optimal GPU layers: $OPTIMAL_GPU_LAYERS for direct run script"
    execute_command tee "$DIRECT_RUN_SCRIPT_PATH" > /dev/null <<EOF
#!/bin/bash
set -euo pipefail
if [ -f "${CONDA_PATH_RESOLVED}/etc/profile.d/conda.sh" ]; then # shellcheck source=/dev/null
    source "${CONDA_PATH_RESOLVED}/etc/profile.d/conda.sh"; else echo "ERROR: Conda profile script not found at ${CONDA_PATH_RESOLVED}/etc/profile.d/conda.sh" >&2; exit 1; fi
export CONDA_MKL_INTERFACE_LAYER_BACKUP="\${CONDA_MKL_INTERFACE_LAYER_BACKUP:-}"
export CONDA_MKL_NUM_THREADS_BACKUP="\${CONDA_MKL_NUM_THREADS_BACKUP:-}"
conda activate "${conda_env_name_resolved:-$DEFAULT_CONDA_ENV_NAME}" || { echo "ERROR: Failed to activate Conda environment '${conda_env_name_resolved:-$DEFAULT_CONDA_ENV_NAME}'" >&2; exit 1; }
# Get security mode from environment or use default
SECURE_MODE="\${SECURE_MODE:-0}"

# Explicitly define HOST_BINDING before conditional
HOST_BINDING="0.0.0.0"
if [ "\$SECURE_MODE" -eq 1 ]; then
    HOST_BINDING="127.0.0.1"
    echo "SECURE MODE: Binding to localhost (\$HOST_BINDING) only."
else
    echo "WARNING: Server will be accessible from your local network at \$HOST_BINDING:8080"
    echo "         Set SECURE_MODE=1 or use --secure flag for localhost-only access."
fi

# Get optimal GPU layers from environment or use default based on system
GPU_LAYERS="\${OPTIMAL_GPU_LAYERS:-1}"
echo "GPU LAYERS: Using \$GPU_LAYERS layers for GPU acceleration"

echo "Starting llama-server directly (foreground)..."
echo "Server binary: $server_binary_full_path"
echo "Model file (absolute): $absolute_model_path_for_scripts"
# CD to server binary's directory, as llama-server might expect to be run from its own directory
# even if model path is absolute.
cd "\$(dirname "$server_binary_full_path")" || { echo "ERROR: Failed to cd to server binary directory: \$(dirname "$server_binary_full_path")" >&2; exit 1; }
echo "Current directory: \$(pwd)"
"$server_binary_full_path" -m "$absolute_model_path_for_scripts" \\
    --port 8080 --host "\$HOST_BINDING" --n-gpu-layers \$GPU_LAYERS \\
    --ctx-size 8192 --repeat-penalty 1.1 --chat-template llama3 --verbose
EOF
    execute_command chmod 700 "$DIRECT_RUN_SCRIPT_PATH"
    check_secure_permissions "$DIRECT_RUN_SCRIPT_PATH" "700" "direct run script"

    log_msg "Creating service control script: $SERVICE_CONTROL_SCRIPT_PATH"
    execute_command tee "$SERVICE_CONTROL_SCRIPT_PATH" > /dev/null <<EOF
#!/bin/bash
set -euo pipefail
SERVICE_LABEL="$SERVICE_LABEL"; PLIST_PATH="$SERVICE_PLIST_PATH"; LOG_DIR_CTL="$LOG_DIR" 
USER_UID=\$(id -u); SERVICE_DOMAIN="gui/\$USER_UID"; SERVICE_TARGET_LABEL="\$SERVICE_DOMAIN/\$SERVICE_LABEL"
log_ctl() { echo "[\$(date +'%Y-%m-%d %H:%M:%S')] \$1"; }
if ! command -v launchctl &> /dev/null; then log_ctl "ERROR: launchctl command not found."; exit 1; fi
get_local_ip() { ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print \$2}' | head -n 1 || echo "N/A"; }

start_service() {
    log_ctl "Attempting to start/kickstart service: \$SERVICE_TARGET_LABEL"
    # If service is defined, kickstart it. Otherwise, bootstrap it.
    if launchctl print "\$SERVICE_TARGET_LABEL" &> /dev/null; then
        log_ctl "Service \$SERVICE_LABEL definition found. Kickstarting..."
        launchctl kickstart -k "\$SERVICE_TARGET_LABEL" || log_ctl "Kickstart for \$SERVICE_TARGET_LABEL failed. It might already be running or there is an issue with the service." "WARNING"
    else
        log_ctl "Service \$SERVICE_LABEL definition not found. Bootstrapping from \$PLIST_PATH into domain \$SERVICE_DOMAIN..."
        launchctl bootstrap "\$SERVICE_DOMAIN" "\$PLIST_PATH"
    fi; sleep 2; status_service
}
stop_service() {
    log_ctl "Attempting to bootout (unload) service: \$SERVICE_TARGET_LABEL using plist \$PLIST_PATH"
    # Try bootout by path first, as it's more specific for removal if plist is known
    launchctl bootout "\$SERVICE_DOMAIN" "\$PLIST_PATH" || log_ctl "Bootout by path \$PLIST_PATH failed. This might be okay if service was already stopped or definition removed." "WARNING"
    # As a fallback, if the label still exists, try to bootout by label.
    if launchctl print "\$SERVICE_TARGET_LABEL" &> /dev/null; then 
        log_ctl "Service label \$SERVICE_TARGET_LABEL still exists after bootout by path. Attempting bootout by label."
        launchctl bootout "\$SERVICE_TARGET_LABEL" || log_ctl "Bootout by label \$SERVICE_TARGET_LABEL also failed. Service might be stubborn or already gone." "WARNING"
    fi
    log_ctl "Service \$SERVICE_LABEL stop/bootout attempt complete."
}
restart_service() { log_ctl "Restarting service \$SERVICE_LABEL..."; stop_service; sleep 1; start_service; }
status_service() {
    log_ctl "--- Service Status: \$SERVICE_LABEL ---"; local service_details; service_details=\$(launchctl print "\$SERVICE_TARGET_LABEL" 2>/dev/null)
    if [ -n "\$service_details" ] && ! echo "\$service_details" | grep -q "No such process"; then
        local pid; pid=\$(echo "\$service_details" | grep "pid = " | awk '{print \$3}' | tr -d ';')
        local last_exit; last_exit=\$(echo "\$service_details" | grep "last exit status" | awk '{print \$NF}' | tr -d ';')
        log_ctl "✅ Service is DEFINED by launchd. PID (if running): \${pid:-N/A}. Last Exit Status: \${last_exit:-N/A}"
        local_ip=\$(get_local_ip)
        log_ctl "Checking server response at http://127.0.0.1:8080/health ..."
        echo "--- curl health check command (from llama-service.sh): curl --fail --show-error -v --max-time 5 http://127.0.0.1:8080/health ---"
        if curl -s --max-time 5 "http://127.0.0.1:8080/health" 2>/dev/null | grep -q "ok"; then
            log_ctl "✅ Server is RESPONDING. API: http://\$local_ip:8080"
        else
            CURL_EXIT_CODE=\$?
            log_ctl "⚠️ Server is DEFINED by launchd but NOT RESPONDING/healthy (curl exit: \$CURL_EXIT_CODE). Check logs in \$LOG_DIR_CTL"
            log_ctl "   Debug log for run_server.sh: tail -f \$LOG_DIR_CTL/service_debug.log"
            log_ctl "   Service output/error: tail -f \$LOG_DIR_CTL/service_output.log \$LOG_DIR_CTL/service_error.log"
            log_ctl "   Launchd output/error: tail -f \$LOG_DIR_CTL/launchd_output.log \$LOG_DIR_CTL/launchd_error.log"
        fi
    else log_ctl "❌ Service \$SERVICE_LABEL is NOT LOADED/bootstrapped in domain \$SERVICE_DOMAIN."; fi
    log_ctl "------------------------------------"
}
logs_service(){ log_ctl "Tailing all logs from \$LOG_DIR_CTL (Ctrl+C to stop):"; echo; tail -f "\$LOG_DIR_CTL/"*.log; }
case "\$1" in start) start_service;; stop) stop_service;; restart) restart_service;; status) status_service;; logs) logs_service;; *) echo "Usage: \$0 {start|stop|restart|status|logs}"; exit 1;; esac
EOF
    execute_command chmod 700 "$SERVICE_CONTROL_SCRIPT_PATH"
    check_secure_permissions "$SERVICE_CONTROL_SCRIPT_PATH" "700" "service control script"

    log_msg "Creating CLI chat script: $CLI_CHAT_SCRIPT_PATH"
    execute_command tee "$CLI_CHAT_SCRIPT_PATH" > /dev/null << 'EOF'
#!/bin/bash
set -euo pipefail
SERVER_URL="http://127.0.0.1:8080"
COMPLETIONS_ENDPOINT="/v1/chat/completions"
HEALTH_ENDPOINT="/health"
MODEL_NAME="Llama-3.2-1B-Instruct.Q4_K_M"

echo "--- llama-chat.sh: Checking server health at $SERVER_URL$HEALTH_ENDPOINT ---"
if ! curl -s --max-time 5 "$SERVER_URL$HEALTH_ENDPOINT" 2>/dev/null | grep -q "ok"; then
  echo "❌ Llama server not responding or not healthy at $SERVER_URL"
  echo "   Ensure server is running: ~/llama-service.sh status OR ~/run-llama-direct.sh"
  exit 1
fi
echo "--- llama-chat.sh: Server healthy. Proceeding with OpenAI-compatible API ---"

send_message() {
    local user_msg="$1"
    # Sanitize user input: escape backslashes then double-quotes to produce valid JSON
    local safe_msg
    safe_msg=$(printf '%s' "$user_msg" | sed 's/\\/\\\\/g; s/"/\\"/g')
    local payload="{\"model\":\"$MODEL_NAME\",\"messages\":[{\"role\":\"user\",\"content\":\"$safe_msg\"}], \"stream\": false}"
    local response_json
    response_json=$(curl -s -X POST "$SERVER_URL$COMPLETIONS_ENDPOINT" -H "Content-Type: application/json" -d "$payload")
    local assistant_response
    assistant_response=$(echo "$response_json" | grep -o '"content":"[^"]*"' | head -n 1 | sed -e 's/"content":"//' -e 's/"$//' -e 's/\\n/\n/g' -e 's/\\"/"/g')
    if [ -z "$assistant_response" ]; then 
        echo "Llama: (No valid response/error)"
        echo "Raw response: $response_json"
    else 
        echo -e "Llama: $assistant_response"
    fi
}

if [ $# -eq 0 ]; then
  echo "🦙 METALlama Chat (Ctrl+D or 'exit'/'quit' to end)"
  echo "----------------------------------------------------"
  while true; do 
    read -r -e -p "You: " USER_INPUT
    if [[ "$USER_INPUT" == "exit" || "$USER_INPUT" == "quit" || (-z "$USER_INPUT" && $? -ne 0) ]]; then break; fi
    if [ -z "$USER_INPUT" ]; then continue; fi
    send_message "$USER_INPUT"
  done
  echo ""; echo "Exiting chat."
else 
  USER_INPUT="$*"
  echo "You: $USER_INPUT"
  send_message "$USER_INPUT"
fi
EOF
    execute_command chmod 700 "$CLI_CHAT_SCRIPT_PATH"
    check_secure_permissions "$CLI_CHAT_SCRIPT_PATH" "700" "CLI chat script"
    log_msg "Helper scripts creation complete." "SUCCESS"
}

final_instructions_and_verification() {
    # Start from a known good directory to avoid getcwd errors
    cd "$HOME" 2>/dev/null || cd / 2>/dev/null || true
    log_msg "--- Final Verification and Instructions ---"
    local max_attempts=12; local delay=5; local attempt=1; local local_ip; local response
    # server_ok is a script-level global — reset it here for this run
    server_ok=0
    local_ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1 || echo "N/A")

    if [ "$DRY_RUN" -eq 1 ]; then log_msg "[DRY RUN] Skipping server verification."
    else
        log_msg "Waiting for server to initialize (this may take up to 60 seconds)..."
        # Initial delay to give server time to start
        sleep 10
        while [ "$attempt" -le "$max_attempts" ]; do
            log_msg "Checking server status (attempt $attempt of $max_attempts)..."
            # Don't use --fail flag and check response contents only
            response=$(curl -s --max-time 5 "http://127.0.0.1:8080/health" 2>/dev/null)
            if echo "$response" | grep -q "ok"; then
                log_msg "✅ Server is up and responding!" "SUCCESS"; server_ok=1; break
            else
                log_msg "⏳ Server not responding or not healthy yet, waiting $delay seconds..." "INFO"
                sleep "$delay"; attempt=$((attempt + 1))
            fi
        done
        if [ "$server_ok" -eq 0 ]; then 
            log_msg "⚠️ Server did not respond as healthy within the expected time." "WARNING"
            log_msg "   Please check the logs in: $LOG_DIR"
            log_msg "   Especially the service debug log: $LOG_DIR/service_debug.log"
            log_msg "   And service error log: $LOG_DIR/service_error.log"
            log_msg "   Also try: $SERVICE_CONTROL_SCRIPT_PATH status"
            log_msg "   And run server directly for more clues: $DIRECT_RUN_SCRIPT_PATH"
        fi
    fi

    echo ""; log_msg "★★★★★★ METALLAMA MPS SERVER INSTALLATION FOR INTEL CPU WITH AMD GPU ONLY (v2.9) ★★★★★★" "SUCCESS"; echo ""
    log_msg "NOTE: This installation is ONLY for Intel CPUs with AMD GPUs - it will NOT work on Apple Silicon" "WARNING";
    echo "Setup is complete. Llama server is configured to run via launchd (using bootstrap)."
    
    # Display appropriate security message
    if [ "${SECURE_MODE:-0}" -eq 1 ]; then
        echo -e "\033[1;32mSECURE MODE ENABLED:\033[0m The server is configured to be accessible only from this computer (bound to 127.0.0.1)."
        echo "This is the recommended setting for most users unless you need network access."
    else
        echo -e "\033[1;33mIMPORTANT SECURITY NOTE:\033[0m The server is currently configured to be accessible from other devices"
        echo "on your local network (bound to 0.0.0.0, port 8080). If your network is not trusted, this can be a security risk."
        echo "To restrict access to localhost only, you have several options:"
        echo "1. Restart the installation with the --secure flag: $0 --secure"
        echo "2. Edit the server run script: nano $RUN_SERVER_SCRIPT_PATH"
        echo "   Then find the HOST_BINDING variable and change it to \"127.0.0.1\""
        echo "3. Restart the service using: $SERVICE_CONTROL_SCRIPT_PATH restart" 
        echo "4. Enable macOS firewall (System Settings > Network > Firewall) to restrict access"
    fi
    
    echo ""
    echo "You can manage the service with these commands:"
    echo "  $SERVICE_CONTROL_SCRIPT_PATH start    - Start the service (bootstraps if not defined, kickstarts if defined)"
    echo "  $SERVICE_CONTROL_SCRIPT_PATH stop     - Stop the service (boots out the definition)"
    echo "  $SERVICE_CONTROL_SCRIPT_PATH restart  - Restart the service"
    echo "  $SERVICE_CONTROL_SCRIPT_PATH status   - Check service status (includes launchd definition and HTTP health)"
    echo "  $SERVICE_CONTROL_SCRIPT_PATH logs     - View live service logs (tails all relevant logs from $LOG_DIR)"
    echo ""
    
    # local_ip already declared earlier in this function; just refresh the value
    local_ip=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1 || echo "N/A")
    
    echo "Server Details:"
    echo "  Local API Endpoint: http://127.0.0.1:8080"
    echo "  Network API Endpoint (if enabled): http://$local_ip:8080 (IP may vary)"
    echo "  Main Installation Directory: $LLAMA_CPP_FULL_PATH"
    echo "  Model File Location: $MODELS_INSTALL_FULL_PATH/$MODEL_FILE_NAME" 
    echo "  Configuration Directory (for run scripts): $CONFIG_DIR"
    echo "  Log Directory (on your Desktop): $LOG_DIR"
    echo ""
    echo "For immediate testing, try the CLI interfaces:"
    echo "  $CLI_CHAT_SCRIPT_PATH             - Start an interactive chat session with the server"
    echo "  $CLI_CHAT_SCRIPT_PATH 'your question here'  - Ask a single question to the server"
    echo ""
    echo "If you encounter issues with the launchd service, you can run the server directly in the foreground for detailed debugging output:"
    echo "  $DIRECT_RUN_SCRIPT_PATH"
    echo ""
    echo "The service is set to start automatically when you log in (RunAtLoad=true in plist)."
    echo ""
    
    if [ "$DRY_RUN" -eq 0 ]; then
        # Check if llama-cli exists before attempting to start interactive mode
        if [ -f "$LLAMA_CPP_FULL_PATH/$BUILD_DIR_NAME/bin/llama-cli" ]; then
            echo "Starting direct model interaction in interactive mode..."
            echo "Press Ctrl+C to exit the model interaction when you're done."
            echo "---------------------------------------------------------"
            sleep 2
            
            # Make sure we start from a valid directory to avoid getcwd errors
            cd "$HOME" 2>/dev/null || cd / 2>/dev/null || true
            
            # Export required environment variables
            export CONDA_MKL_INTERFACE_LAYER_BACKUP="${CONDA_MKL_INTERFACE_LAYER_BACKUP:-}"
            export CONDA_MKL_NUM_THREADS_BACKUP="${CONDA_MKL_NUM_THREADS_BACKUP:-}"
            
            # Directly launch into interactive chat
            echo "Starting interactive chat with Llama using Metal GPU acceleration."
            echo "Using $OPTIMAL_GPU_LAYERS GPU layers for optimal performance with your hardware."
            echo "Model: $MODEL_FILE_NAME"
            echo "Press Ctrl+C to exit when done."
            echo "---------------------------------------------------------"
            echo "Running: \"$LLAMA_CPP_FULL_PATH/$BUILD_DIR_NAME/bin/llama-cli\" \\
  -m \"$MODELS_INSTALL_FULL_PATH/$MODEL_FILE_NAME\" \\
  --n-gpu-layers $OPTIMAL_GPU_LAYERS \\
  --color \\
  --chat-template llama3 \\
  -i"
            
            # Use full path to llama-cli to ensure it works even if directory navigation failed
            "$LLAMA_CPP_FULL_PATH/$BUILD_DIR_NAME/bin/llama-cli" \
              -m "$MODELS_INSTALL_FULL_PATH/$MODEL_FILE_NAME" \
              --n-gpu-layers "$OPTIMAL_GPU_LAYERS" \
              --color \
              --chat-template llama3 \
              -i
        else
            log_msg "llama-cli binary not found at $LLAMA_CPP_FULL_PATH/$BUILD_DIR_NAME/bin/llama-cli" "ERROR"
            log_msg "Cannot start direct model interaction. Please check the build logs for errors." "ERROR"
            log_msg "Try running the script again with the --verbose flag for more details." "INFO"
        fi
    else
        log_msg "[DRY RUN] Would start direct model interaction with: llama-cli -m $MODELS_INSTALL_FULL_PATH/$MODEL_FILE_NAME --n-gpu-layers $OPTIMAL_GPU_LAYERS --color --chat-template llama3 -i" "INFO"
    fi
}

final_test() {
    if [ "$DRY_RUN" -eq 0 ] && [ "$server_ok" -eq 1 ]; then
        log_msg "Attempting final test: Sending a direct POST request to the server's /v1/chat/completions endpoint..."
        local test_payload="{\"model\":\"$MODEL_FILE_NAME\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello from the installer! Briefly confirm you are working.\"}]}"
        echo "You (Installer Test): Hello from the installer! Briefly confirm you are working."
        local test_response
        echo "--- Installer Test Command: curl -s -X POST -H \"Content-Type: application/json\" -d '$test_payload' http://127.0.0.1:8080/v1/chat/completions ---"
        test_response=$(curl -s -X POST -H "Content-Type: application/json" -d "$test_payload" "http://127.0.0.1:8080/v1/chat/completions")
        local curl_status=$?
        echo "--- Test Response (curl exit status: $curl_status) ---"
        echo "$test_response"
        echo "------------------------------------------"
        if [ "$curl_status" -eq 0 ]; then
            # Attempt to parse "content" field from JSON response
            local assistant_reply
            # Using awk for basic JSON parsing to avoid jq dependency
            assistant_reply=$(echo "$test_response" | awk -F'"content":"' '{print $2}' | awk -F'"' '{print $1}' | sed 's/\\n/\n/g; s/\\"/"/g')
            if [ -n "$assistant_reply" ]; then 
                echo -e "Llama (from installer test):\n$assistant_reply"
                log_msg "Final server test successful." "SUCCESS"
            else 
                log_msg "Final server test: Could not parse 'content' from JSON response. Raw response above." "WARNING"
            fi
        else
            log_msg "Final server test curl command failed. Check server logs and ensure it's fully started and responsive." "WARNING"
        fi
    elif [ "$DRY_RUN" -eq 1 ]; then log_msg "[DRY RUN] Would attempt final test curl to /v1/chat/completions endpoint."
    else log_msg "Server not confirmed running, skipping final test curl to /v1/chat/completions endpoint." "WARNING"; fi
    echo ""; log_msg "Installation script finished." "SUCCESS"
}

main() {
    # Start from a known good directory to avoid getcwd errors
    cd "$HOME" 2>/dev/null || cd / 2>/dev/null || true
    
    trap 'handle_error "Script interrupted by user (SIGINT/SIGTERM)." "Logs are in $LOG_DIR"; exit 130' SIGINT SIGTERM
    
    log_msg "--- Starting METALlama MPS Server Installation for Intel CPU with AMD GPU ONLY (v2.9) ---"
    log_msg "❌ WARNING: THIS SCRIPT WILL NOT WORK ON APPLE SILICON MACS (M1/M2/M3) ❌" "WARNING"
    
    # Check dependencies early to avoid starting the process if essential tools are missing
    log_msg "Performing pre-installation dependency checks..."
    if ! check_dependencies; then
        handle_error "Dependency check failed. Please install the required tools and try again." "See specific error messages above."
    fi
    
    # Detect system information (Apple Silicon vs Intel, memory, etc.)
    log_msg "Detecting system information for optimization..."
    if ! check_system_info; then
        handle_error "System information check failed or was aborted by user." "See specific messages above."
    fi
    
    # Initial basic Metal GPU check
    log_msg "Checking for AMD GPU hardware..."
    if ! test_metal_support; then
        handle_error "AMD GPU check failed." "This script is designed for Intel CPU with AMD GPU systems."
    fi
    
    read -r -p "Enter Conda environment name (default: $DEFAULT_CONDA_ENV_NAME): " cn; conda_env_name_resolved="${cn:-$DEFAULT_CONDA_ENV_NAME}"
    read -r -p "Enter Python version for Conda environment (default: $DEFAULT_PYTHON_VERSION): " pv; python_version_resolved="${pv:-$DEFAULT_PYTHON_VERSION}"
    
    log_msg "Conda Env: $conda_env_name_resolved, Python: $python_version_resolved"
    log_msg "Installation Path: $LLAMA_CPP_FULL_PATH"
    log_msg "Models Path: $MODELS_INSTALL_FULL_PATH"
    log_msg "Log Path: $LOG_DIR"
    
    get_huggingface_token
    prepare_directories_and_backup 
    setup_conda_env "$conda_env_name_resolved" "$python_version_resolved"
    install_and_build_llamacpp
    
    # Let the user select a model
    select_model
    
    # Download the selected model
    download_model # Now downloads to $MODELS_INSTALL_FULL_PATH
    
    # We've already tested Metal with Swift, no need for another test
    log_msg "Model downloaded successfully." "SUCCESS"
    
    if command_exists "launchctl"; then 
        if ! manage_launchd_service; then 
            log_msg "launchd service management encountered issues. The server might not run as a service." "WARNING"
        fi
    else
        log_msg "launchctl command not found. Skipping service management. You will need to run the server manually using: $DIRECT_RUN_SCRIPT_PATH" "WARNING"
    fi
    create_helper_scripts 
    final_instructions_and_verification
    
    # Only run the final test if we're not going into direct model interaction
    # This avoids breaking the direct model chat experience
    if [ "$DRY_RUN" -eq 1 ]; then
        log_msg "DRY RUN COMPLETED. No actual changes were made." "SUCCESS"
        final_test
    fi
}

if main; then exit 0; else log_msg "Main script execution failed. Please review output and logs." "ERROR"; exit 1; fi