# Installation Guide - Phase 1 (Circuit Breaker Manual)

## Prerequisites

- macOS
- Homebrew installed
- Root access (sudo)

---

## Step 1: Install Nginx

```bash
# Install Nginx via Homebrew
brew install nginx

# Verify installation
nginx -v
```

---

## Step 2: Create Required Directories

```bash
# Create Nginx config directory
sudo mkdir -p /usr/local/etc/nginx/servers

# Create state directory
sudo mkdir -p /usr/local/var/moltbot-hardened/state

# Create log directory
sudo mkdir -p /usr/local/var/log/nginx

# Fix ownership
sudo chown -R $USER:staff /usr/local/etc/nginx/
sudo chown -R $USER:staff /usr/local/var/moltbot-hardened/
sudo chown -R $USER:staff /usr/local/var/log/nginx/
```

---

## Step 2.5: Install CLI

```bash
sudo ./install-cli.sh
```

---

## Step 3: Create mime.types (if not exists)

```bash
sudo tee /usr/local/etc/nginx/mime.types > /dev/null <<'NG'
types {
    text/plain txt;
    text/html html htm;
    text/css css;
    application/javascript js;
    application/json json;
    image/png png;
    image/jpeg jpeg jpg;
}
NG
```

---

## Step 4: Configure Nginx Main Config

```bash
sudo tee /usr/local/etc/nginx/nginx.conf > /dev/null <<'NG'
user $USER staff;
worker_processes auto;
error_log /usr/local/var/log/nginx/error.log info;
pid /usr/local/var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    # Rate limiting zones (must be in http context)
    limit_req_zone $binary_remote_addr zone=moltbot_limit:10m rate=10r/s;
    limit_req_zone $binary_remote_addr zone=moltbot_recovery:10m rate=5r/s;

    include mime.types;
    default_type application/octet-stream;

    sendfile on;
    keepalive_timeout 65;

    # Log format
    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent"';

    access_log /usr/local/var/log/nginx/access.log main;

    # Include state-specific server config
    include /usr/local/etc/nginx/servers/moltbot-control.conf;
}
NG
```

---

## Step 5: Create Authentication File

```bash
# Install htpasswd tool (if not available)
brew install httpd

# Create admin user
# You'll be prompted for a password
htpasswd -c /usr/local/etc/nginx/.htpasswd admin
```

---

## Step 6: Create Circuit Breaker State Files

See [circuit-breaker/states.md](./circuit-breaker/states.md) for detailed Nginx configurations.

The three state files will be created:
- `moltbot-control.conf.closed` - Normal operation
- `moltbot-control.conf.open` - Blocked state
- `moltbot-control.conf.half` - Recovery/verification mode

Create these files from the examples in `circuit-breaker/states.md`.

---

## Step 7: Create Initial State File

```bash
# Start in OPEN (safe) state
cat <<'EOF' | sudo tee /usr/local/var/moltbot-hardened/state/breaker-state.json > /dev/null
{
  "state": "OPEN",
  "reason": "INITIAL_SETUP",
  "detected_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "actor": "system"
}
EOF
```

---

## Step 8: Set Initial Symlink (OPEN for safety)

```bash
# Link to OPEN config (safe default)
sudo ln -sf /usr/local/etc/nginx/servers/moltbot-control.conf.open \
             /usr/local/etc/nginx/servers/moltbot-control.conf
```

---

## Step 9: Test Nginx Configuration

```bash
# Test configuration syntax
sudo nginx -t

# Expected output: "the configuration file /usr/local/etc/nginx/nginx.conf syntax is ok"
```

---

## Step 10: Start Nginx

```bash
# Start Nginx
sudo nginx

# Verify it's running
lsof -i :8080 | grep LISTEN

# Expected: nginx is listening on 127.0.0.1:8080
```

---

## Step 11: Verify State

```bash
# Check initial state
cat /usr/local/var/moltbot-hardened/state/breaker-state.json

# Expected: OPEN state
```

---

## Step 12: Test States (Manual)

Once you have created the three state configuration files from `circuit-breaker/states.md`:

### Test OPEN state (should return 403):

```bash
# Ensure OPEN config is active
sudo ln -sf /usr/local/etc/nginx/servers/moltbot-control.conf.open \
             /usr/local/etc/nginx/servers/moltbot-control.conf

# Reload Nginx
sudo nginx -s reload

# Test
curl http://127.0.0.1:8080/

# Expected: 403 Forbidden
```

### Test HALF-OPEN state:

```bash
# Switch to HALF-OPEN
sudo ln -sf /usr/local/etc/nginx/servers/moltbot-control.conf.half \
             /usr/local/etc/nginx/servers/moltbot-control.conf

# Reload Nginx
sudo nginx -s reload

# Test normal request (blocked)
curl http://127.0.0.1:8080/

# Test health endpoint (allowed)
curl http://127.0.0.1:8080/health

# Expected: Normal request → 503, Health → 200
```

### Test CLOSED state:

```bash
# Switch to CLOSED (requires auth)
sudo ln -sf /usr/local/etc/nginx/servers/moltbot-control.conf.closed \
             /usr/local/etc/nginx/servers/moltbot-control.conf

# Reload Nginx
sudo nginx -s reload

# Test (will prompt for password)
curl -u admin http://127.0.0.1:8080/

# Expected: 200 (after entering password)
```

---

## Troubleshooting

### Nginx won't start

```bash
# Check error log
tail -20 /usr/local/var/log/nginx/error.log

# Common issues:
# - Port already in use → lsof -i :8080
# - Permission denied → check directory ownership
# - Config syntax error → nginx -t
```

### Permission denied accessing state file

```bash
# Fix state directory permissions
sudo chown -R $USER:staff /usr/local/var/moltbot-hardened/state/
```

### Auth not working

```bash
# Check auth file exists
ls -la /usr/local/etc/nginx/.htpasswd

# Verify config references it
grep auth_basic /usr/local/etc/nginx/servers/moltbot-control.conf.closed
```

---

## Next Steps

After manual Nginx is working, you can:

1. **Install CLI script** - See [CLI.md](./CLI.md)
2. **Automate state switching** with `moltbot-hardened` commands
3. **Enable Guardian** - See [guardian/README.md](./guardian/README.md) (Phase 2)

---

## Uninstall

```bash
# Stop Nginx
sudo nginx -s stop

# Remove directories (optional)
sudo rm -rf /usr/local/etc/nginx/
sudo rm -rf /usr/local/var/moltbot-hardened/

# Uninstall Nginx
brew uninstall nginx
```

---

*Last updated: 27 January 2026*

---

# Installation Guide - Phase 2 (Exposure Guardian)

## Quick install (script)

```bash
sudo ./install-guardian.sh
```

## Manual install (advanced)

```bash
sudo ./install-guardian.sh
```

## Step 2: Install launchd plist (if doing manual steps)

```bash
sudo cp guardian/launchd/io.moltbot.hardened.guardian.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/io.moltbot.hardened.guardian.plist
```

## Step 3: Load the daemon

```bash
sudo launchctl load /Library/LaunchDaemons/io.moltbot.hardened.guardian.plist
```

## Step 4: Verify logs

```bash
tail -f /usr/local/var/log/moltbot-hardened/guardian.log
```
