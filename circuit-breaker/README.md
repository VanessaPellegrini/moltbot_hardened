# Circuit Breaker

## What is the Circuit Breaker?

The Circuit Breaker is a **reverse proxy (Nginx)** that controls access to Moltbot's control plane.

It implements a **fail-closed pattern**: by default, the control plane is blocked, and it must be explicitly opened.

---

## Why Do We Need It?

The primary risk with Moltbot is not "sophisticated hackers" but **human misconfiguration**:

- Accidentally binding to `0.0.0.0` instead of `127.0.0.1`
- Forgetting to configure authentication
- Leaving the panel open "just for a moment"

The Circuit Breaker ensures that **when something is wrong, access is blocked**.

---

## How It Works

### Architecture

```
User Request
     |
     v
[ Nginx Circuit Breaker ]
     |
     | State: CLOSED / OPEN / HALF-OPEN
     |
     +---- CLOSED → Routes to Control Plane
     |---- OPEN → Returns 403/503
     +---- HALF-OPEN → Allows only 127.0.0.1 (allowlist)
     |
     v
[ Moltbot Control Plane ]
```

### Key Principles

1. **Fail-Closed**: When in doubt, block access
2. **Explicit Control**: States are changed only by user or Guardian
3. **Observable**: State is visible via CLI and file
4. **Auditable**: All state changes are logged

---

## States

### CLOSED (Normal Operation)

- **What happens**: Admin panel is accessible
- **Who can access**: Authenticated users on allowlist (127.0.0.1 or VPN)
- **Nginx behavior**: Routes traffic to control plane
- **User sees**: Normal admin interface

**When to use:**
- When you want to use the admin panel
- After configuration is verified as safe
- Normal day-to-day operation

**How to set:**
```bash
moltbot-hardened open
```

---

### OPEN (Blocked / Safe Mode)

- **What happens**: Admin panel is inaccessible
- **Who can access**: Nobody
- **Nginx behavior**: Returns 403 (Forbidden) or 503 (Service Unavailable)
- **User sees**: Clear error explaining why it's blocked

**When to use:**
- When you detect a security issue
- When Guardian opens it automatically
- When you're doing sensitive maintenance

**How to set:**
```bash
moltbot-hardened block
```

**Error message example:**
```html
<h1>Access Blocked</h1>
<p>State: OPEN</p>
<p>Reason: PUBLIC_PORT_DETECTED</p>
<p>Detected: 2026-01-27T19:40:00Z</p>
<p>Action: Fix configuration and run <code>moltbot-hardened recovery</code></p>
```

---

### HALF-OPEN (Recovery / Verification Mode)

- **What happens**: Admin panel is partially accessible
- **Who can access**: Only 127.0.0.1 (localhost) for verification
- **Nginx behavior**: Returns 503 for normal requests, allows /health/check from 127.0.0.1
- **User sees**: "System in recovery mode"

**When to use:**
- When you fixed a misconfiguration
- When you want to verify the fix
- Before returning to normal operation

**How to set:**
```bash
moltbot-hardened recovery
```

**Allowlist in HALF-OPEN:**
- `127.0.0.1` → Allowed (verification tests)
- `/health/check` → Allowed (health endpoint)
- Everything else → Blocked (503)

---

## Configuration

### Nginx Configuration Files

**Location:** `/usr/local/etc/nginx/servers/moltbot-control.conf` (active symlink)

See [circuit-breaker/states.md](./states.md) for complete Nginx configurations for each state (CLOSED, OPEN, HALF-OPEN).
Templates are included in the repo at `circuit-breaker/nginx/`.

**File structure:**
```
/usr/local/etc/nginx/servers/
├── moltbot-control.conf           (Active symlink)
├── moltbot-control.closed.conf    (Normal operation)
├── moltbot-control.open.conf      (Blocked state)
└── moltbot-control.half.conf      (Recovery/verification mode)
```

**State switching:** The CLI script symlinks the appropriate config file to `moltbot-control.conf` and reloads Nginx.

**Rate limiting:** If you add `limit_req_zone`, place it in the `http` context (e.g., `nginx.conf`), not inside a `server` block.

---

## State Management

### State File

**Location:** `/usr/local/var/moltbot-hardened/state/breaker-state.json`

**Content:**
```json
{
  "state": "CLOSED|OPEN|HALF",
  "reason": "MANUAL_BLOCK|EXPOSURE_DETECTED|RECOVERY",
  "detected_at": "2026-01-27T19:30:00Z",
  "actor": "guardian|user|system"
}
```

**Validation:**
- `state` must be one of: CLOSED, OPEN, HALF
- `reason` is optional but recommended
- `detected_at` is ISO 8601 timestamp
- `actor` indicates who initiated the change

---

## Switching States

### How State Changes Work

1. User runs CLI command (`block`, `recovery`, `open`)
2. CLI validates the request
3. CLI updates `/usr/local/var/moltbot-hardened/state/breaker-state.json`
4. CLI symlinks the appropriate Nginx configuration:
   - `moltbot-control.closed.conf` → `moltbot-control.conf`
   - `moltbot-control.open.conf` → `moltbot-control.conf`
   - `moltbot-control.half.conf` → `moltbot-control.conf`
5. CLI reloads Nginx: `nginx -s reload`
6. Nginx applies the new configuration

**No magic:** Every state change is explicit, logged, and reversible.

See [circuit-breaker/states.md](./states.md) for detailed Nginx configurations.

---

## Monitoring and Logs

### Nginx Access Logs

**Location:** `/usr/local/var/log/nginx/access.log`

**Format:**
```
127.0.0.1 - - [27/Jan/2026:19:40:00 +0000] "GET /admin HTTP/1.1" 403 123 "-" "-"
```

### Nginx Error Logs

**Location:** `/usr/local/var/log/nginx/error.log`

**What to look for:**
- Failed auth attempts
- Rate limit exceeded
- Configuration errors
- State change failures

---

## Troubleshooting

### Nginx Won't Reload

**Problem:** `nginx -s reload` fails

**Possible causes:**
1. Configuration syntax error
2. Port already in use
3. Permission denied

**Solution:**
```bash
# Test configuration
nginx -t

# Check what's using the port
lsof -i :8080

# Check permissions
ls -la /usr/local/var/moltbot-hardened/state/
```

---

### State File Corrupted

**Problem:** `breaker-state.json` is invalid JSON

**Symptom:** CLI refuses to change state

**Fail-closed behavior:**
- If JSON is invalid, system assumes `OPEN` (safest state)
- CLI shows error but still blocks access

**Recovery:**
```bash
# Manually restore to CLOSED
echo '{
  "state": "CLOSED",
  "reason": "MANUAL_RECOVERY",
  "detected_at": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'",
  "actor": "system"
}' > /usr/local/var/moltbot-hardened/state/breaker-state.json

# Reload Nginx
nginx -s reload
```

---

### Auth Not Working

**Problem:** 403 even when state is CLOSED

**Possible causes:**
1. `.htpasswd` file is empty or missing
2. Auth module not loaded in Nginx
3. Wrong path to auth file

**Solution:**
```bash
# Verify auth file exists
ls -la /etc/nginx/.htpasswd

# Create auth user (if needed)
htpasswd -c /etc/nginx/.htpasswd admin

# Check Nginx config
grep -n "auth_basic" /usr/local/etc/nginx/servers/moltbot-control.conf
```

---

## Security Considerations

### What This Protects

✅ Prevents accidental public exposure
✅ Blocks when misconfiguration is detected
✅ Enforces authentication at the edge
✅ Limits rate of requests
✅ Makes state changes explicit and auditable

### What This Doesn't Protect

❌ Doesn't protect against local attackers (same machine)
❌ Doesn't prevent code-level vulnerabilities in Moltbot
❌ Doesn't protect against physical access
❌ Doesn't protect if user intentionally opens the circuit

---

## Next Steps

See [circuit-breaker/states.md](./states.md) for detailed state documentation.

See [PHASE1.md](../PHASE1.md) for implementation progress.
