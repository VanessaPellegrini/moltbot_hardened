# Guardian Checks

## Overview

The Guardian performs a series of security checks every 30-60 seconds to detect misconfigurations that could expose Moltbot.

**Principle:** If anything looks risky, the Circuit Breaker is opened immediately.

---

## Check 1: Public Port Exposure

### What it checks

Scans for services listening on public interfaces (`0.0.0.0`, `::`).

### Why it matters

Binding to `0.0.0.0` instead of `127.0.0.1` exposes the service to the entire network/internet.

### How it works

**Commands:**
```bash
# Check IPv4
lsof -i :8080 -nP | grep LISTEN | awk '{print $5}'

# Check IPv6
lsof -i :8080 -nP | grep LISTEN | awk '{print $5}'

# Alternative with netstat
netstat -an | grep :8080 | grep LISTEN
```

**Logic:**
```bash
if bind_address == "0.0.0.0" || bind_address == "::"; then
    return RISK_DETECTED
fi
```

### Response to risk detected

**State:** OPEN
**Reason:** PUBLIC_PORT_DETECTED
**Details:** Port number, bind address, process name

**Example:**
```json
{
  "state": "OPEN",
  "reason": "PUBLIC_PORT_DETECTED",
  "details": {
    "port": 8080,
    "bind_address": "0.0.0.0",
    "process": "nginx"
  }
}
```

---

## Check 2: Missing Authentication

### What it checks

Verifies that authentication file exists and is not empty.

### Why it matters

Without authentication, anyone who can access the control plane has full access.

### How it works

**Command:**
```bash
# Check if auth file exists
[ -f /usr/local/etc/nginx/.htpasswd ] && return FILE_EXISTS

# Check if file is not empty
[ -s /usr/local/etc/nginx/.htpasswd ] && return FILE_NOT_EMPTY
```

**Logic:**
```bash
if [ ! -f /usr/local/etc/nginx/.htpasswd ]; then
    return RISK_DETECTED
fi

if [ ! -s /usr/local/etc/nginx/.htpasswd ]; then
    return RISK_DETECTED
fi
```

### Response to risk detected

**State:** OPEN
**Reason:** AUTH_MISSING
**Details:** Auth file path, file size

**Example:**
```json
{
  "state": "OPEN",
  "reason": "AUTH_MISSING",
  "details": {
    "auth_file": "/usr/local/etc/nginx/.htpasswd",
    "file_size": 0
  }
}
```

---

## Check 3: Docker Published Ports

### What it checks

Scans Docker containers to ensure they're not publishing ports to all interfaces.

### Why it matters

Docker's `-p 8080:8080` binds to `0.0.0.0` by default, exposing the service publicly.

### How it works

**Command:**
```bash
# List containers with published ports
docker ps --format "{{.Ports}}" | grep "0.0.0.0"

# Or use docker inspect
docker inspect $(docker ps -q) | jq -r '.[].NetworkSettings.Ports[]? | select(.PublishIp) | "\(.PublishIp):\(.PublicPort) -> \(.PrivatePort)"'
```

**Logic:**
```bash
if published_ip == "0.0.0.0" || published_ip == "::"; then
    return RISK_DETECTED
fi
```

### Response to risk detected

**State:** OPEN
**Reason:** DOCKER_PUBLIC_PORT
**Details:** Container name, port mapping

**Example:**
```json
{
  "state": "OPEN",
  "reason": "DOCKER_PUBLIC_PORT",
  "details": {
    "container": "moltbot-control",
    "port_mapping": "0.0.0.0:8080 -> 8080/tcp"
  }
}
```

---

## Check 4: HTML Fingerprinting (Future)

### What it will check

Scan for Moltbot control pages accessible from public internet.

### Why it matters

Even if port is bound correctly, Shodan or similar services can index and fingerprint the service.

### How it will work (future)

**Commands:**
```bash
# HTTP request to localhost
curl -s http://127.0.0.1:8080/ | grep -i "moltbot"

# Or check for specific indicators
curl -s http://127.0.0.1:8080/ | head -20 | grep -i "control\|admin\|dashboard"
```

**Logic:**
```bash
if html_content =~ "Moltbot Control" && not_authenticated; then
    return RISK_DETECTED
fi
```

### Response to risk detected (future)

**State:** OPEN
**Reason:** FINGERPRINT_DETECTED
**Details:** URL, fingerprint match

**Example:**
```json
{
  "state": "OPEN",
  "reason": "FINGERPRINT_DETECTED",
  "details": {
    "url": "http://127.0.0.1:8080/",
    "fingerprint": "Moltbot Control Panel v1.0"
  }
}
```

---

## Check 5: Nginx Configuration Validation

### What it checks

Verifies that Nginx configuration is syntactically valid.

### Why it matters

Invalid Nginx configuration can cause Nginx to fail or load a default (potentially insecure) config.

### How it works

**Command:**
```bash
# Test Nginx configuration
nginx -t -c /usr/local/etc/nginx/nginx.conf
```

**Logic:**
```bash
if nginx -t returns error; then
    # Check if active state file is the fallback (potentially unsafe)
    if state_file == "fallback.conf"; then
        return RISK_DETECTED
    fi
fi
```

### Response to risk detected

**State:** OPEN
**Reason:** NGINX_CONFIG_INVALID
**Details:** Error message

**Example:**
```json
{
  "state": "OPEN",
  "reason": "NGINX_CONFIG_INVALID",
  "details": {
    "error": "nginx: [emerg] invalid number of arguments in \"auth_basic\" directive"
  }
}
```

---

## Check Execution Flow

### Main Loop

```bash
while true; do
    # Run all checks
    for check in all_checks; do
        result = run_check(check)

        if result == RISK_DETECTED; then
            # Log risk
            log_risk(check, result)

            # Update state file
            update_state(OPEN, check.reason)

            # Exit immediately (don't run more checks)
            exit 0
        fi
    done

    # Log: No risks found
    log_ok("All checks passed")

    # Wait before next check
    sleep 30
done
```

### Priority Order

Checks run in this order (first risk detected stops further checks):

1. **Public Port Exposure** (highest priority)
2. **Missing Authentication**
3. **Docker Published Ports**
4. **Nginx Configuration Validation**
5. **HTML Fingerprinting** (future, lower priority)

---

## False Positives and Tuning

### What is a false positive?

A false positive is when the Guardian detects a risk that isn't actually risky.

**Examples:**
- Binding to `0.0.0.0` but firewall blocks it
- Auth file exists but auth is disabled in Nginx config
- Container publishes port but host firewall blocks it

### How to avoid false positives

**Current approach:** Fail-closed
- Better to have a false positive (safe but inconvenient) than a false negative (exposed but undetected)

**Future tuning (Phase 2+):**
- Add firewall awareness (check if firewall blocks the port)
- Add allowlist configuration (known safe bindings)
- Add context awareness (user is actively debugging)

---

## Performance Considerations

### Impact on system

Each check takes:
- Port scan: ~50-100ms
- File checks: ~5-10ms
- Docker inspection: ~100-200ms
- Nginx test: ~20-50ms

**Total per cycle:** ~200-400ms

**At 30s intervals:** Negligible system impact

### Optimization ideas

**Cache results:**
```bash
if port_state == cached_port_state; then
    # Skip this check if nothing changed
    continue
fi
```

**Parallel checks:**
```bash
# Run checks in parallel
check_1 &
check_2 &
check_3 &
wait
```

---

## Testing Checks

### Test: Public Port Detection

**Setup:**
```bash
# Intentionally bind to 0.0.0.0
echo "listen 0.0.0.0:8080;" >> /usr/local/etc/nginx/servers/moltbot-control.conf
nginx -s reload
```

**Run Guardian check:**
```bash
moltbot-hardened-guardian --check

# Expected: State file shows OPEN, PUBLIC_PORT_DETECTED
```

**Cleanup:**
```bash
# Restore to 127.0.0.1
echo "listen 127.0.0.1:8080;" > /usr/local/etc/nginx/servers/moltbot-control.conf
nginx -s reload
```

### Test: Missing Auth

**Setup:**
```bash
# Remove auth file
rm /usr/local/etc/nginx/.htpasswd
```

**Run Guardian check:**
```bash
moltbot-hardened-guardian --check

# Expected: State file shows OPEN, AUTH_MISSING
```

**Cleanup:**
```bash
# Restore auth file
htpasswd -c /usr/local/etc/nginx/.htpasswd admin
```

---

## Next Steps

See [guardian/README.md](./README.md) for Guardian daemon documentation.

See [THREAT_MODEL.md](../THREAT_MODEL.md) for how these checks mitigate threats.

---

*Last updated: 27 January 2026*
