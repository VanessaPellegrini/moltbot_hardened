# Recovery Procedures

This document describes safe recovery steps for reopening access after the circuit is OPEN.

## Standard Recovery Flow

1. Fix the misconfiguration (binds, auth, ports).
2. Ensure auth file exists and is not empty:
   ```bash
   ls -la /usr/local/etc/nginx/.htpasswd
   ```
3. Switch to recovery mode (HALF):
   ```bash
   moltbot-hardened recovery
   ```
4. Run verification checks:
   ```bash
   moltbot-hardened verify
   ```
5. If all checks pass, close the circuit:
   ```bash
   moltbot-hardened open
   ```

## Manual Verification (Optional)

Use these checks to confirm the breaker state directly:

```bash
# CLOSED should require auth (401)
curl -I http://127.0.0.1:8080/

# HALF should block normal paths (503)
curl -I http://127.0.0.1:8080/admin

# HALF should allow health check on localhost (200 if your control plane serves /health)
curl -I http://127.0.0.1:8080/health/check
```

## If Guardian Immediately Reopens the Circuit

Guardian will keep opening the circuit if it detects exposure. Common causes:

- Missing or empty auth file
- Breaker bound to `0.0.0.0` or `::`
- Control plane responding without auth

Fix the cause, then repeat the Standard Recovery Flow.

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
