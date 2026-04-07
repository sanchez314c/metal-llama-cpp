# Version Map

This document tracks all versions of METALlama.cpp, including the active version and archived backups.

## Active Version

| Version | Location | Status | Notes |
|---------|----------|--------|-------|
| **2.8.2** | `/` (root) | ACTIVE | Production-ready METALlama.cpp installer for Intel Macs with AMD GPUs |

## Archived Versions

Located in `archive/` folder (gitignored):

| Folder | Status | Notes |
|--------|--------|-------|
| `archive/20260107_020320_METALlama.cpp_00/` | ARCHIVED | Early version with original installer script name |
| `archive/20260107_020320_METALlama.cpp2_01/` | ARCHIVED | Early v2 iteration |
| `archive/20260107_020324_metal-llama-cpp_00/` | ARCHIVED | Pre-rename version |
| `archive/20260207_184635_metal-llama-cpp/` | ARCHIVED | Last snapshot before current documentation pass |
| `archive/*metal-llama-cpp-set-01/` | ARCHIVED | Bulk backup of prior iteration set |
| `archive/displaced-docs-*/` | ARCHIVED | Docs-level governance duplicates removed during 27-file standardization |

## Version History

### v2.8.2 (Current — Active)
- **Status:** Production-ready
- **Release Date:** 2026-03-14
- **Key Changes:**
  - docs/README.md: documentation index replacing docs/DOCUMENTATION_INDEX.md
  - LICENSE: updated copyright to 2026 Jason Paul Michaels
  - CLAUDE.md: rewritten with accurate installer flags, runtime paths, model details
  - AGENTS.md: rewritten with precise variable names, critical context, CI job breakdown
  - VERSION_MAP.md: corrected active version tracking
  - Full repository compliance audit: tests/ and legacy/ dirs, .gitkeep files, permissions

### v2.8.1
- **Status:** Archived
- **Release Date:** 2026-02-07
- **Key Changes:**
  - GitHub Issue Templates: bug_report.md, feature_request.md
  - ShellCheck config (.shellcheckrc) for consistent linting
  - Enhanced CI/CD: script validation, permissions check, Metal build verification
  - CODE_OF_CONDUCT.md: contact method corrected to GitHub Issues link
  - Repository compliance audit completed

### v2.8.0
- **Release Date:** 2025-05-18
- **Key Features:**
  - Initial public release
  - macOS MPS/Metal acceleration support
  - Automatic model download from Hugging Face
  - launchd service management
  - CLI chat interface (`~/llama-chat.sh`)
  - OpenAI-compatible API server on port 8080
  - Updated model path structure for llama.cpp v2.6+

## Archive Backup Policy

- **Archive Location:** `archive/` (gitignored per .gitignore)
- **Naming Convention:** `YYYYMMDD_HHMMSS_<description>` for new backups
- **Retention:** All backups retained
- **Restoration:** Copy from archive subfolder or extract zip to working directory

## Restoration

```bash
# Copy from archived folder
cp -r archive/20260207_184635_metal-llama-cpp/* ../restored-version/

# Verify installer
bash -n restored-version/install-metallama.sh
```

---

**Last Updated:** 2026-03-14
