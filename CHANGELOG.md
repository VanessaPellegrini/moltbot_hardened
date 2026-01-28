# Changelog

## v0.1.0-alpha — Phase 1 + Phase 2 (2026-01-28)

### Added
- Circuit Breaker templates for CLOSED/OPEN/HALF (`circuit-breaker/nginx/`).
- Phase 1 CLI in Python with `status/block/recovery/open/verify`.
- Phase 2 Guardian daemon (`guardian/guardian.py`) with exposure checks.
- launchd plist for Guardian (`guardian/launchd/io.moltbot.hardened.guardian.plist`).
- Installers: `scripts/install.sh`, `scripts/install-cli.sh`, `scripts/install-guardian.sh`.
- Documentation for Phase 1 and Phase 2 (`PHASE1.md`, `PHASE2.md`).

### Changed
- Nginx auth file path standardized to `/usr/local/etc/nginx/.htpasswd`.
- Install flow updated to place system binaries under `/usr/local/lib` with wrappers in `/usr/local/bin`.

### Notes
- **⚠️ ALPHA/EXPERIMENTAL:** This release is for testing and development only, not production use
- Phase 1 and Phase 2 are functional but require local auth setup (`htpasswd`) for full verification
- Guardian runs under launchd and will open the circuit if auth is missing or exposure is detected
- Installation steps may change significantly in future versions
- APIs and configurations are not stable yet
