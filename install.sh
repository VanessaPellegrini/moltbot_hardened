#!/bin/bash

# moltbot-hardened - Complete Installation Script (Phase 1: Circuit Breaker Manual)
# This script performs all setup steps in a single execution

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Moltbot Hardened - Installation${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# Configuration variables
NGINX_CONF_DIR="/usr/local/etc/nginx"
NGINX_SERVERS_DIR="$NGINX_CONF_DIR/servers"
NGINX_MIME_TYPES="$NGINX_CONF_DIR/mime.types"
NGINX_LOG_DIR="/usr/local/var/log/nginx"
NGINX_PID_DIR="/usr/local/var/run/nginx"
STATE_DIR="/usr/local/var/moltbot-hardened/state"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OWNER_USER="${SUDO_USER:-$(whoami)}"
OWNER_GROUP="staff"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run with sudo privileges${NC}"
    echo "Usage: sudo $0"
    exit 1
fi

echo -e "${YELLOW}Step 1: Installing prerequisites...${NC}"

# Check if nginx is installed
if ! command -v nginx &> /dev/null; then
    echo -e "${RED}Error: nginx is not installed${NC}"
    echo "Install with: brew install nginx"
    exit 1
fi

echo -e "${GREEN}✓${NC} nginx found at $(which nginx)"

# Check if htpasswd is available
if ! command -v htpasswd &> /dev/null; then
    echo -e "${YELLOW}⚠${NC}  htpasswd not found (httpd package)"
    echo "You can install it with: brew install httpd"
    echo "We'll continue without it for now"
fi

echo ""
echo -e "${YELLOW}Step 2: Creating directories...${NC}"

# Create directories with proper permissions
mkdir -p "$NGINX_CONF_DIR"
mkdir -p "$NGINX_SERVERS_DIR"
mkdir -p "$STATE_DIR"
mkdir -p "$NGINX_LOG_DIR"
mkdir -p "$NGINX_PID_DIR"

echo -e "${GREEN}✓${NC} Directories created"
echo "  - $NGINX_CONF_DIR"
echo "  - $NGINX_SERVERS_DIR"
echo "  - $STATE_DIR"
echo "  - $NGINX_LOG_DIR"

echo ""
echo -e "${YELLOW}Step 3: Creating mime.types...${NC}"

# Create mime.types only if it doesn't exist
if [ ! -f "$NGINX_MIME_TYPES" ]; then
    tee "$NGINX_MIME_TYPES" > /dev/null <<'NG'
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
    echo -e "${GREEN}✓${NC} mime.types created"
else
    echo -e "${GREEN}✓${NC} mime.types already exists (skipping)"
fi

echo ""
echo -e "${YELLOW}Step 4: Copying state configs...${NC}"

# Copy state configurations from repo templates
cp "$SCRIPT_DIR/circuit-breaker/nginx/moltbot-control.closed.conf" "$NGINX_SERVERS_DIR/"
cp "$SCRIPT_DIR/circuit-breaker/nginx/moltbot-control.half.conf" "$NGINX_SERVERS_DIR/"
cp "$SCRIPT_DIR/circuit-breaker/nginx/moltbot-control.open.conf" "$NGINX_SERVERS_DIR/"

echo -e "${GREEN}✓${NC} State configs copied"
echo "  - $NGINX_SERVERS_DIR/moltbot-control.closed.conf"
echo "  - $NGINX_SERVERS_DIR/moltbot-control.half.conf"
echo "  - $NGINX_SERVERS_DIR/moltbot-control.open.conf"

echo ""
echo -e "${YELLOW}Step 5: Creating main nginx.conf...${NC}"

# Create main nginx.conf
tee "$NGINX_CONF_DIR/nginx.conf" > /dev/null <<NG
user $OWNER_USER $OWNER_GROUP;
worker_processes auto;
error_log $NGINX_LOG_DIR/error.log info;
pid $NGINX_PID_DIR/nginx.pid;

events {
    worker_connections 1024;
}

http {
    # Rate limiting zones (must be in http context)
    limit_req_zone \$binary_remote_addr zone=moltbot_limit:10m rate=10r/s;
    limit_req_zone \$binary_remote_addr zone=moltbot_recovery:10m rate=5r/s;

    include mime.types;
    default_type application/octet-stream;

    sendfile on;
    keepalive_timeout 65;

    # Log format
    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent"';

    access_log $NGINX_LOG_DIR/access.log main;

    # Include ONLY the active symlink (not *.conf)
    include $NGINX_SERVERS_DIR/moltbot-control.conf;
}
NG

echo -e "${GREEN}✓${NC} nginx.conf created"

echo ""
echo -e "${YELLOW}Step 6: Creating initial state...${NC}"

# Create initial state file (OPEN for safety)
mkdir -p "$STATE_DIR"
echo "{\"state\":\"OPEN\",\"reason\":\"INITIAL_SETUP\",\"detected_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"actor\":\"system\"}" | tee "$STATE_DIR/breaker-state.json" > /dev/null

echo -e "${GREEN}✓${NC} Initial state created: OPEN"

echo ""
echo -e "${YELLOW}Step 7: Setting active symlink to OPEN (safe default)...${NC}"

# Set active symlink to OPEN state (safe default)
ln -sf "$NGINX_SERVERS_DIR/moltbot-control.open.conf" "$NGINX_SERVERS_DIR/moltbot-control.conf"

echo -e "${GREEN}✓${NC} Active symlink set to: moltbot-control.conf.open"

echo ""
echo -e "${YELLOW}Step 8: Fixing log file permissions...${NC}"

# Fix log permissions
chown "$OWNER_USER:$OWNER_GROUP" "$NGINX_LOG_DIR"
chmod 750 "$NGINX_LOG_DIR"

echo -e "${GREEN}✓${NC} Log permissions fixed"

echo ""
echo -e "${YELLOW}Step 9: Testing nginx configuration...${NC}"

# Test nginx configuration
if nginx -t 2>&1; then
    echo -e "${GREEN}✓${NC} nginx configuration is valid"
else
    echo -e "${RED}✗${NC} nginx configuration test FAILED"
    echo ""
    echo "Please check the configuration files:"
    echo "  - $NGINX_CONF_DIR/nginx.conf"
    echo "  - $NGINX_SERVERS_DIR/moltbot-control.conf.*"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 10: Starting nginx...${NC}"

# Start nginx
if nginx 2>&1; then
    echo -e "${GREEN}✓${NC} nginx started successfully"
else
    echo -e "${RED}✗${NC} nginx failed to start"
    echo "Check the error log: $NGINX_LOG_DIR/error.log"
    exit 1
fi

echo ""
echo -e "${YELLOW}Step 11: Verifying installation...${NC}"

# Verify nginx is listening
if lsof -i :8080 | grep -q LISTEN; then
    echo -e "${GREEN}✓${NC} nginx is listening on port 8080"
else
    echo -e "${RED}✗${NC} nginx is NOT listening on port 8080"
    echo "Check: $NGINX_LOG_DIR/error.log"
fi

echo ""
echo -e "${YELLOW}Step 12: Testing states...${NC}"

echo ""
echo "Testing OPEN state (current):"
if curl -s http://127.0.0.1:8080/ | grep -q "OPEN"; then
    echo -e "${GREEN}✓${NC} Returns OPEN state message (403 Forbidden)"
else
    echo -e "${RED}✗${NC} Unexpected response"
fi

echo ""
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Summary:"
echo "  - nginx.conf: $NGINX_CONF_DIR/nginx.conf"
echo "  - State configs: $NGINX_SERVERS_DIR/"
echo "  - Current state: OPEN (safe default)"
echo "  - State file: $STATE_DIR/breaker-state.json"
echo "  - Logs: $NGINX_LOG_DIR/"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "  1. Check current state: cat $STATE_DIR/breaker-state.json"
echo "  2. Test access: curl http://127.0.0.1:8080/"
echo "  3. When you're ready, switch to CLOSED state manually:"
echo "     sudo ln -sf $NGINX_SERVERS_DIR/moltbot-control.conf.closed $NGINX_SERVERS_DIR/moltbot-control.conf"
echo "     sudo nginx -s reload"
echo ""
echo -e "${YELLOW}NOTE:${NC} This script uses OPEN state as the initial safe default."
echo "To start using Moltbot, you must:"
echo "  1. Configure authentication (htpasswd -c $NGINX_CONF_DIR/.htpasswd admin)"
echo "  2. Switch to CLOSED state (see above)"
echo ""
