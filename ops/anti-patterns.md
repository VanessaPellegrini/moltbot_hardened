# Ops Anti-Patterns

This document lists **operational anti‑patterns** that lead to exposure or unsafe states.
Avoid these in all phases.

---

## 1) Binding the breaker to `0.0.0.0`

**Why it’s dangerous:** Exposes the control plane to the network/internet.

**Safer pattern:** Bind breaker to `127.0.0.1` or VPN interface only.

---

## 2) Disabling authentication “just for testing”

**Why it’s dangerous:** Any access becomes unauthenticated control.

**Safer pattern:** Keep auth enabled; use local allowlist or temporary credentials.

---

## 3) Leaving OPEN state for convenience

**Why it’s dangerous:** OPEN is a safety lock — leaving it open without reason means bypassing the breaker entirely.

**Safer pattern:** Only open briefly for recovery; move to CLOSED when safe.

---

## 4) Editing live configs without validation

**Why it’s dangerous:** A typo can disable protections or load defaults.

**Safer pattern:** Always run:

```bash
nginx -t
```

before reload.

---

## 5) Running the control plane on public ports

**Why it’s dangerous:** Even if breaker is local, a public control plane can be indexed or attacked.

**Safer pattern:** Bind control plane to `127.0.0.1:3000` and keep it behind the breaker.

---

## 6) Sharing `$HOME` or secrets with the control plane

**Why it’s dangerous:** Any compromise can leak keys or user data.

**Safer pattern:** Use isolated user or restricted paths; do not mount sensitive directories.

---

## 7) Disabling Guardian to “stop alerts”

**Why it’s dangerous:** Removes the only automated fail‑closed guardrail.

**Safer pattern:** Fix the underlying exposure. If you must disable, do it temporarily and document the reason.

---

## 8) Using symlinks from repo paths in launchd

**Why it’s dangerous:** launchd blocks or breaks execution from user paths.

**Safer pattern:** Install scripts into `/usr/local/lib` and use wrappers in `/usr/local/bin`.

---

## 9) Skipping recovery verification

**Why it’s dangerous:** You may reopen while still exposed.

**Safer pattern:** Always run `moltbot-hardened verify` before closing the circuit.

---

## 10) Assuming “localhost = safe”

**Why it’s dangerous:** Localhost access can still be exploited via other local processes.

**Safer pattern:** Treat localhost as untrusted and enforce auth + allowlist.

---

*Last updated: 28 January 2026*
