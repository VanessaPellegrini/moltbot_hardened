# Circuit Breaker States

This document defines the operational states for the circuit breaker.

## CLOSED

- Admin panel is accessible through the breaker.
- Auth is enforced.
- Allowlist is active (127.0.0.1 or VPN).

## OPEN

- Admin panel is blocked.
- All requests return 403/503.
- Use this when risk is detected or during maintenance.

## HALF

- Recovery/verification mode.
- Only allowlist traffic is accepted.
- `/health/check` is the only allowed endpoint.

## State Source of Truth

The state is stored in:

`/usr/local/var/moltbot-hardened/state/breaker-state.json`

The CLI updates this file and switches the active Nginx config.
