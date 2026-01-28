# Guardian Checks

## Overview

The Guardian runs every 30s (default) and applies **fail‑closed** logic:
if any check signals risk, the circuit is opened immediately.

---

## Implemented Checks (Phase 2)

### 1) Public bind on breaker port

**Detects:** `0.0.0.0` or `::` listeners on the breaker port.

**Why:** Binding to public interfaces exposes the control plane.

**Implementation:** `lsof -nP -iTCP:<port> -sTCP:LISTEN` with address parsing.

**Action:** OPEN with reason `EXPOSURE_DETECTED`.

---

### 2) Missing or empty auth file

**Detects:** `/usr/local/etc/nginx/.htpasswd` missing or empty.

**Why:** Without auth, any access to the breaker is unsafe.

**Implementation:** file existence and non‑zero size checks.

**Action:** OPEN with reason `EXPOSURE_DETECTED`.

---

### 3) Unauthenticated access to breaker

**Detects:** `GET /` to `127.0.0.1:<breaker_port>` returns a status that is **not** 401/403/503.

**Why:** Any “success” response without auth implies exposure.

**Implementation:** HTTP request to localhost and status check.

**Action:** OPEN with reason `EXPOSURE_DETECTED`.

---

## Planned Checks (Future)

These are intentionally **not implemented yet**. They remain documented as the roadmap.

- Docker published ports (detect `0.0.0.0` bindings from `docker ps` / `inspect`)
- Nginx configuration validation (`nginx -t`)
- HTML fingerprinting for Moltbot control pages
- Firewall-aware allowlist logic

---

## Execution Flow

- Runs checks in order
- First risk detected stops evaluation and opens the circuit
- Logs decision to `/usr/local/var/log/moltbot-hardened/guardian.log`

---

## Notes

- The Guardian does **not** auto-close the circuit.
- Recovery remains manual via `moltbot-hardened recovery` and `open`.

---

*Last updated: 28 January 2026*
