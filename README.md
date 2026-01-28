# moltbot-hardened

[![Status](https://img.shields.io/badge/status-alpha-orange)](https://github.com/VanessaPellegrini/moltbot-hardened)
[![Phase](https://img.shields.io/badge/phase-1--Circuit%20Breaker%20Manual-blue)](https://github.com/VanessaPellegrini/moltbot-hardened/blob/main/PHASE1.md)

**Security-first reference architecture for running Moltbot safely on macOS.**

moltbot-hardened is an open-source, security-first reference architecture
for running Moltbot safely on macOS.

## Status & Warnings

**⚠️ This project is ALPHA/EXPERIMENTAL**

- **Not production-ready** - Use for testing and development only
- **No security guarantees** - Security claims are design-level, not audited
- **APIs may change** - Breaking changes without notice in future versions
- **Use at your own risk** - No liability for damages or data loss

**Supported Platform:**

- ✅ macOS (Darwin 24.6.0+ tested)
- ❌ Linux (not supported, may work with modifications)
- ❌ Windows (not supported)

**Before You Use:**

1. Read [THREAT_MODEL.md](THREAT_MODEL.md) to understand security scope
2. Read [INSTALL.md](INSTALL.md) for installation steps
3. Review [PHASE2.md](PHASE2.md) to understand current implementation status
4. Test thoroughly in a non-production environment

## Goal

Prevent real-world security incidents caused by human misconfiguration, such as:

- Exposing control plane to public internet
- Leaking API keys
- Enabling unintended remote code execution

**Philosophy:** This project prioritizes "not exposing you" over "being convenient."

## Architecture

Applies proven architectural patterns to ensure that when something goes wrong,
the system blocks access before it becomes exploitable:

- **Circuit Breaker:** Controls access to control plane
- **Fail-Closed by Default:** Deny unless explicitly allowed
- **Zero Trust Local:** Localhost ≠ secure
- **Bulkhead Isolation:** Compartmentalize control plane, runtime, and host
- **External Guardian Process:** Independent exposure monitoring

## Core Principles

## Core Principles

- Control plane never exposed by default
- Authentication is mandatory
- Unsafe states automatically degrade to locked-down mode
- Misconfigurations are detected and handled explicitly
- Ambiguity always results in denial, not silent exposure

## Why This Exists

Unlike application-level security features, moltbot-hardened focuses on
operational safety and deployment hardening.

It is designed as a **standalone, open-source hardening kit**, independent
from Moltbot's core codebase, so it can:

- Evolve quickly
- Remain auditable
- Serve as a reference implementation for safely operating local AI agents

## Who is this for?

- Developers running Moltbot on macOS
- Anyone deploying local AI agents with system access
- Security reviewers looking for operational hardening patterns

## Status

**Phase 1: Circuit Breaker Manual**

Currently implementing manual control plane blocking before Guardian automation.

See [PHASE1.md](./PHASE1.md) for details and progress.

**Phase 2: Exposure Guardian**

Automatic exposure detection and breaker opening.

See [PHASE2.md](./PHASE2.md) for details and progress.

## What's Included

- **Guardian Daemon:** macOS launchd service that monitors exposure
- **Circuit Breaker:** Nginx-based edge protection
- **State Management:** JSON-based control plane with clear states
- **CLI Control:** Python CLI for manual breaker control
- **Documentation:** Complete threat model, architecture, and operations guide

## Getting Started

### Phase 1: Circuit Breaker Manual

Currently in development.

```bash
# Clone the repo
git clone https://github.com/VanessaPellegrini/moltbot-hardened.git
cd moltbot-hardened

# See Phase 1 implementation guide
cat PHASE1.md
```

## Documentation

- [Architecture](./ARCHITECTURE.md) - System design and patterns
- [Threat Model](./THREAT_MODEL.md) - Security threat analysis
- [PHASE1.md](./PHASE1.md) - Current phase implementation plan
- [PHASE2.md](./PHASE2.md) - Guardian phase implementation plan
- [Circuit Breaker](./circuit-breaker/README.md) - How the breaker works
- [Guardian](./guardian/README.md) - What the guardian monitors
- [Operations](./ops/recovery.md) - Safe recovery procedures
- [CLI](./CLI.md) - Command-line usage
- [KANBAN](./KANBAN.md) - Phase 1 progress

## License

MIT
