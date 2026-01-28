# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.1.x (alpha) | ⚠️ Experimental - No security support |

**⚠️ IMPORTANT:** This project is in **ALPHA/EXPERIMENTAL** stage. It is **not production-ready** and provides **no security guarantees**.

## Reporting a Vulnerability

If you discover a security vulnerability, please **do not**:

- ❌ Open a public issue
- ❌ Discuss it publicly
- ❌ Exploit the vulnerability

**Instead, please:**

1. **Email us**: security@example.com
2. **Include details**:
   - Vulnerability description
   - Steps to reproduce
   - Impact assessment
   - Suggested fix (if known)

3. **Wait for response**:
   - We will acknowledge within 48 hours
   - We will provide a timeline for fix
   - We will coordinate disclosure

## What Happens Next

1. **Assessment**: We evaluate the vulnerability severity
2. **Fix**: We develop a patch (you can help!)
3. **Testing**: We verify the fix
4. **Release**: We publish a security release
5. **Disclosure**: We announce the vulnerability (with credit)

## Security Best Practices

This project implements several security patterns:

### Circuit Breaker Pattern
- Blocks access when misconfigurations detected
- Fail-closed by default
- Automatic exposure detection

### Guardian Daemon
- Monitors for public port binding
- Detects missing authentication
- Detects unauthenticated access

### Hardening Measures
- Control plane never exposed by default
- Localhost ≠ secure (127.0.0.1 is safest)
- Fail-safe on invalid state

### What We Don't Protect Against

- ❌ Local attackers (same machine access)
- ❌ User intentionally disabling protections
- ❌ Code-level vulnerabilities in Moltbot
- ❌ Physical access to device

## Threat Model (Explicit Summary)

### Primary threats
- Accidental public exposure of the control plane
- Missing authentication on the control plane
- Prompt injection leading to unintended execution
- Secret leakage from logs or configuration

### Assumptions
- macOS is reasonably secure
- The user is cooperative (not intentionally disabling protections)
- Moltbot code is trusted; focus is on deployment safety

### Out of scope
- Local attackers (same machine)
- Physical access to device
- Sophisticated APTs

Full details: [THREAT_MODEL.md](./THREAT_MODEL.md)

## Security Audits

**Status:** None conducted yet

This is a volunteer project without formal audits. Security claims are based on design patterns and best practices, not formal verification.

## Dependencies

We aim to minimize dependencies and keep them updated:

- Python 3.9+ (standard library only)
- Nginx 1.29+ (system package)
- macOS launchd (system component)

## Reaching Out

For general security questions or discussions:
- Open an issue with the `security` label
- Join our community: https://example.com/community

---

**Remember:** This is ALPHA/EXPERIMENTAL. Use at your own risk.
