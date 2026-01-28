# Recovery Procedures

This document describes safe recovery steps when the circuit is OPEN.

## Standard Recovery Flow

1. Fix the misconfiguration (binds, auth, ports).
2. Switch to recovery mode:
   ```bash
   moltbot-hardened recovery
   ```
3. Run verification checks:
   ```bash
   moltbot-hardened verify
   ```
4. If all checks pass, close the circuit:
   ```bash
   moltbot-hardened open
   ```

## If State File Is Corrupted

1. Restore a valid state file:
   ```bash
   echo '{
     "state": "OPEN",
     "reason": "MANUAL_RECOVERY",
     "detected_at": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
     "actor": "system"
   }' | sudo tee /usr/local/var/moltbot-hardened/state/breaker-state.json > /dev/null
   ```
2. Reload Nginx:
   ```bash
   sudo nginx -s reload
   ```
