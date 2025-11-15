# Product Requirements Document

## Overview

METALlama.cpp is a prepackaged installation system for running Llama.cpp with Metal Performance Shaders (MPS) acceleration on Intel Macs with AMD GPUs. This document outlines the product requirements, user stories, and technical specifications.

## Problem Statement

Millions of Intel Macs with discrete AMD GPUs are capable of running AI models but lack optimized software. While Apple has transitioned to M-series chips, the installed base of Intel Macs remains significant, especially in:
- Educational institutions
- Creative professional workflows  
- Development environments
- Cost-conscious organizations

These users need a way to:
1. Utilize their existing hardware for AI inference
2. Access modern LLM models without cloud dependencies
3. Integrate with existing AI applications
4. Maintain privacy and data sovereignty

## Product Vision

Enable AI inference on "forgotten" Intel Mac hardware by providing a seamless, optimized installation of llama.cpp with Metal acceleration, transforming these machines into capable AI workstations.

## Target Users

### Primary Users
1. **Educational Institutions**
   - Schools and universities with Intel Mac labs
   - Computer science departments
   - Research organizations

2. **Creative Professionals**
   - Video editors, designers, artists
   - Content creators
   - Small agencies

3. **Developers and Tinkerers**
   - Independent developers
   - AI enthusiasts
   - Hobbyists

4. **Cost-Conscious Organizations**
   - Startups and small businesses
   - Non-profits
   - Government agencies

### User Personas

#### Alex, University IT Administrator
- **Role**: Manages 50+ Intel Macs in computer lab
- **Goals**: Provide AI tools to students without hardware upgrades
- **Pain Points**: Limited budget, complex setup, maintenance overhead
- **Needs**: One-command installation, centralized management, reliable operation

#### Sarah, Creative Professional
- **Role**: Video editor and motion graphics artist
- **Goals**: Use AI for script writing, ideation, and asset generation
- **Pain Points**: Technical complexity, performance issues, integration challenges
- **Needs**: Professional tools, seamless workflow, stable performance

#### David, Independent Developer
- **Role**: Builds AI-powered applications
- **Goals**: Local development environment, API compatibility
- **Pain Points**: Setup complexity, documentation gaps, debugging difficulties
- **Needs**: Development tools, clear APIs, good documentation

## User Stories

### Epic 1: Easy Installation
**As a** Mac user
**I want to** install AI inference capability with a single command
**So that** I can quickly start using AI without technical expertise

**Acceptance Criteria:**
- Single command installation
- Automatic dependency installation
- No manual configuration required for basic use
- Clear success/failure feedback

### Epic 2: Metal Acceleration
**As a** Intel Mac user with AMD GPU
**I want to** leverage my GPU for AI inference
**So that** I can get better performance than CPU-only solutions

**Acceptance Criteria:**
- Detect and utilize AMD GPU via Metal
- Significant performance improvement over CPU
- Automatic GPU memory management
- Thermal throttling protection

### Epic 3: Application Integration
**As a** creative professional
**I want to** use AI models with my existing tools
**So that** I can enhance my workflow without changing applications

**Acceptance Criteria:**
- OpenAI-compatible API server
- Works with major AI applications
- Standard authentication methods
- Reliable network access

### Epic 4: Model Management
**As a** developer
**I want to** easily switch between AI models
**So that** I can optimize for different use cases

**Acceptance Criteria:**
- Support multiple model formats
- Easy model installation
- Automatic model optimization
- Model performance metrics

### Epic 5: Professional Features
**As a** power user
**I want to** monitor and tune performance
**So that** I can optimize for my specific hardware

**Acceptance Criteria:**
- Performance monitoring dashboard
- GPU utilization metrics
- Memory usage tracking
- Configuration tuning interface

## Functional Requirements

### Core Features

#### F1: One-Click Installation
- **F1.1**: Automated dependency detection and installation
- **F1.2**: System requirements validation
- **F1.3**: Silent installation mode
- **F1.4**: Rollback capability

#### F2: Metal GPU Acceleration
- **F2.1**: AMD GPU detection via Metal framework
- **F2.2**: Automatic GPU layer allocation
- **F2.3**: VRAM management and overflow handling
- **F2.4**: Thermal monitoring and throttling

#### F3: OpenAI-Compatible Server
- **F3.1**: RESTful API implementation
- **F3.2**: Chat completions endpoint
- **F3.3**: Streaming response support
- **F3.4**: Model listing endpoint

#### F4: Model Management
- **F4.1**: GGUF format support
- **F4.2**: HuggingFace integration
- **F4.3**: Automatic model downloading
- **F4.4**: Model switching without restart

#### F5: Service Management
- **F5.1**: LaunchAgent integration
- **F5.2**: Automatic startup on login
- **F5.3**: Health monitoring
- **F5.4**: Log management

### Configuration Features

#### C1: Flexible Configuration
- **C1.1**: JSON-based configuration
- **C1.2**: Environment variable overrides
- **C1.3**: Command-line parameter support
- **C1.4**: Configuration validation

#### C2: Performance Tuning
- **C2.1**: GPU layer adjustment
- **C2.2**: Context size configuration
- **C2.3**: Batch size optimization
- **C2.4**: Sampling parameter control

### Security Features

#### S1: Access Control
- **S1.1**: Localhost-only binding option
- **S1.2**: API key authentication
- **S1.3**: Token-based security
- **S1.4**: Firewall integration guidance

#### S2: Process Isolation
- **S2.1**: User-level service execution
- **S2.2**: Restricted file permissions
- **S2.3**: Secure temporary file handling
- **S2.4**: Audit logging capability

## Non-Functional Requirements

### Performance Requirements
- **P1**: 3-5x performance improvement over CPU-only
- **P2**: Support for models up to 8B parameters
- **P3**: Response time under 2 seconds for 512 tokens
- **P4**: Memory usage within 80% of available RAM

### Reliability Requirements
- **R1**: 99%+ uptime for local service
- **R2**: Graceful error handling and recovery
- **R3**: No memory leaks during extended operation
- **R4**: Automatic restart on failure

### Usability Requirements
- **U1**: Installation completes in under 10 minutes
- **U2**: Zero-configuration for basic use
- **U3**: Clear error messages with solutions
- **U4**: Comprehensive documentation

### Compatibility Requirements
- **C1**: macOS 11.0+ support
- **C2**: Intel Macs with AMD GPUs
- **C3**: Major AI application compatibility
- **C4**: OpenAI API client compatibility

## Technical Specifications

### System Requirements
```yaml
Minimum:
  macOS: "11.0 (Big Sur)"
  Architecture: "Intel x86_64"
  GPU: "AMD discrete graphics"
  RAM: "8GB"
  Storage: "10GB free"

Recommended:
  macOS: "12.0+ (Monterey)"
  GPU: "AMD Radeon Pro 5500M or newer"
  RAM: "16GB+"
  Storage: "20GB free"
```

### Supported Models
```yaml
Formats:
  - GGUF (primary)
  - Legacy GGML (deprecated)

Quantization:
  - Q2_K (maximum compression)
  - Q4_K_M (recommended balance)
  - Q5_K_M (better quality)
  - Q8_K (maximum quality)

Model Sizes:
  - 1B parameters: ~2GB RAM
  - 3B parameters: ~6GB RAM
  - 8B parameters: ~12GB RAM
```

### API Endpoints
```yaml
Base URL: "http://127.0.0.1:8080/v1"

Endpoints:
  - "/chat/completions": Chat completions
  - "/models": Model listing
  - "/health": Health check
  - "/": Root information
```

## Success Metrics

### Adoption Metrics
- **M1**: 1000+ installations in first month
- **M2**: 10,000+ installations in first year
- **M3**: 50,000+ installations by year 2

### Performance Metrics
- **P1**: Average 4+ tokens/second on 3B models
- **P2**: 85%+ GPU utilization under load
- **P3**: <5% thermal throttling events
- **P4**: <2 second cold start time

### Quality Metrics
- **Q1**: <1% installation failure rate
- **Q2**: 4.5+ star rating on GitHub
- **Q3**: <24 hour response to issues
- **Q4**: 90%+ user satisfaction in surveys

## Roadmap

### Phase 1: MVP (Months 1-3)
- Core installation functionality
- Basic Metal acceleration
- OpenAI-compatible server
- Model management

### Phase 2: Enhancement (Months 4-6)
- Performance optimization
- Security features
- Advanced configuration
- Documentation expansion

### Phase 3: Scale (Months 7-12)
- Multi-user support
- Web UI
- Container deployment
- Enterprise features

## Dependencies and Assumptions

### External Dependencies
- Apple Metal framework (system)
- llama.cpp project (upstream)
- HuggingFace model repository
- Homebrew package manager
- Conda environment manager

### Key Assumptions
- Users have admin access to their Mac
- Internet connection for model downloads
- Basic familiarity with command line
- AMD GPU supports Metal (2015+ models)

## Risks and Mitigations

### Technical Risks
- **Risk**: Metal driver incompatibility
  **Mitigation**: Comprehensive GPU testing matrix
- **Risk**: Performance not meeting expectations
  **Mitigation**: Transparent benchmarking and optimization
- **Risk**: Memory management issues
  **Mitigation**: Robust testing across configurations

### Market Risks
- **Risk**: Apple discontinues Intel Mac support
  **Mitigation**: Focus on current installed base
- **Risk**: Competing solutions emerge
  **Mitigation**: Superior user experience and integration
- **Risk**: Limited market size
  **Mitigation**: Expand to other platforms long-term

This PRD guides the development and evolution of METALlama.cpp.