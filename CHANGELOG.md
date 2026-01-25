# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.8.4] - 2026-03-17

### Security
- `install-metallama.sh`: Hugging Face token no longer exposed via `execute_command` verbose logging (`$*` expansion printed the full token 3x to stdout) — fixed by bypassing `execute_command` for HF download and using `HF_TOKEN` env var instead of `--token` CLI flag (also prevents process table exposure via `ps aux`)
- `install-metallama.sh` (generated `llama-chat.sh`): User input sanitized before JSON payload construction — backslashes and double-quotes escaped to prevent JSON injection and request parsing failures
- `install-metallama.sh`: `response` variable in `final_instructions_and_verification` declared `local` to prevent global namespace pollution
- `install-metallama.sh`: EXIT trap cleared with `trap - EXIT` at end of `test_metal_support` to prevent lingering script-wide trap after function returns
- `install-metallama.sh`: Conda env name lookup changed from `grep -qE "^${var}\s"` to `grep -qF "$var"` to prevent regex metacharacter injection in user-supplied env names

## [2.8.3] - 2026-03-14

### Security
- `install-metallama.sh`: Hugging Face token no longer printed in plain text when failing validation check; replaced with a redacted preview (`hf_****`) — fixes CRIT-01
- `install-metallama.sh`: Token length validation range updated from `30–40` to `30–100` to correctly accept all modern HF token formats without false warnings

### Fixed
- `install-metallama.sh`: `server_ok` promoted to script-level global; `final_test()` now correctly reads the value set by `final_instructions_and_verification()` — fixes CRIT-02 (silent skip of final API test)
- `install-metallama.sh`: All three `execute_command cd <path>` calls replaced with direct `cd "<path>" || handle_error` calls — fixes HIGH-02 (cd in subshell never changed the parent shell's working directory)
- `install-metallama.sh`: Dead functions `create_metal_test_script()` and `test_metal_with_llama_cli()` removed — fixes HIGH-01 (unreachable code, potential temp file leak)
- `install-metallama.sh`: EXIT trap added inside `test_metal_support()` for guaranteed temp directory cleanup; all manual `rm -rf "$test_dir"` branches removed — fixes HIGH-04
- `install-metallama.sh`: `git checkout` step added after clone to pin to the latest stable release tag — fixes HIGH-03 / INFO-02
- `install-metallama.sh`: Single-item `for cmd in ninja` loop replaced with direct `if ! command_exists "ninja"` block — fixes MED-05 (SC2043)
- `install-metallama.sh`: `backup_dir` declaration and assignment separated — fixes MED-03 (SC2155, masked return value)
- `install-metallama.sh`: `check_secure_permissions()` now selects `stat` flags based on OS (`-f "%Lp"` for macOS, `-c "%a"` for Linux) — fixes MED-04
- `install-metallama.sh`: Duplicate `local local_ip` declaration removed from `final_instructions_and_verification()` — fixes LOW-03
- `install-metallama.sh`: All unquoted integer variables in `[ ]` tests quoted: `$status`, `$server_ok`, `$curl_status`, `$attempt`, `$valid_choice` — fixes HIGH-05 / SC2086
- `install-metallama.sh`: Magic numbers for GPU layer thresholds replaced with named constants (`GPU_LAYERS_HIGH/MED/LOW/MIN`, `MEM_THRESH_HIGH/MED/LOW`) — fixes LOW-02
- `install-metallama.sh`: Heredoc for generated `run_server.sh` annotated with comments distinguishing installer-time vs runtime variable expansion — fixes LOW-05
- `run-source-macos.sh`: Upgraded from `set -e` to `set -euo pipefail` for full strict mode — fixes MED-06

### Added
- `AUDIT_REPORT.md`: Full forensic code quality audit report documenting all 21 findings across 5 severity levels

## [2.8.2] - 2026-03-14

### Added
- `docs/README.md`: New documentation index replacing docs/DOCUMENTATION_INDEX.md; indexes all 15 docs files with descriptions, runtime path reference table, and role-based navigation
- `docs/README.md` includes repository layout and post-install file map
- `tests/` directory with `.gitkeep` placeholder for future validation scripts
- `legacy/` directory with `.gitkeep` placeholder for superseded script versions
- `.gitignore`: Added `tests/output/`, `tests/*.log`, `*.backup.*` entries

### Changed
- `LICENSE`: Updated copyright from "2025 METALlama.cpp" to "2026 Jason Paul Michaels"
- `CLAUDE.md`: Rewritten with accurate installer flags, runtime file paths, default model details, CI behavior, and project structure tree
- `AGENTS.md`: Rewritten with precise variable names, critical context (strict mode, idempotency), CI job breakdown, and "what not to do" guidance
- `VERSION_MAP.md`: Updated to reflect v2.8.2 as active version; added full compliance audit entry; version history corrected
- `run-source-windows.bat`: Permissions corrected to executable

### Removed (moved to archive)
- `docs/DOCUMENTATION_INDEX.md` → replaced by `docs/README.md`
- `docs/CODE_OF_CONDUCT.md` → root `CODE_OF_CONDUCT.md` is canonical
- `docs/CONTRIBUTING.md` → root `CONTRIBUTING.md` is canonical
- `docs/SECURITY.md` → root `SECURITY.md` is canonical
- `docs/AGENTS.md` → root `AGENTS.md` is canonical
- `docs/INSTALL.md` → `docs/INSTALLATION.md` is canonical

All displaced files moved to `archive/displaced-docs-20260314_104039/`

## [2.8.1] - 2026-02-07

### Added
- GitHub Issue Templates: bug_report.md and feature_request.md
- ShellCheck configuration file (.shellcheckrc) for consistent linting
- Enhanced CI/CD workflow with script validation, permissions check, and Metal build verification

### Fixed
- CODE_OF_CONDUCT.md: Replaced placeholder contact method with actual GitHub Issues link
- CI workflow: Removed ineffective `|| true` from shellcheck step, added meaningful validation jobs

### Changed
- Repository compliance audit performed and all findings addressed

## [2.8.0] - 2025-05-18

### Added
- Initial public release
- Support for macOS MPS/Metal acceleration
- Automatic model download from Hugging Face
- Launchd service management
- CLI chat interface
- Server API compatible with OpenAI endpoints

### Changed
- Updated model path structure to match llama.cpp v2.6+
- Improved error handling and logging
- Enhanced service management scripts

### Fixed
- Various path resolution issues
- Service startup reliability improvements