#!/bin/bash

# moltbot-hardened - Guardian Installation Script (Phase 2)
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
LAUNCHD_PLIST="io.moltbot.hardened.guardian.plist"
LAUNCHD_DEST="/Library/LaunchDaemons/$LAUNCHD_PLIST"
LOG_DIR="/usr/local/var/log/moltbot-hardened"
INSTALL_DIR="/usr/local/lib/moltbot-hardened"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: This script must be run with sudo${NC}"
  echo "Usage: sudo $0"
  exit 1
fi

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Moltbot Hardened - Guardian Install${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""

echo -e "${YELLOW}Step 1: Installing guardian...${NC}"
mkdir -p "$INSTALL_DIR"
cp "$REPO_DIR/guardian/guardian.py" "$INSTALL_DIR/guardian.py"
chmod +x "$INSTALL_DIR/guardian.py"

echo -e "${GREEN}✓${NC} guardian installed to $INSTALL_DIR"

echo -e "${YELLOW}Step 2: Ensuring log dir...${NC}"
mkdir -p "$LOG_DIR"

echo -e "${GREEN}✓${NC} log dir ready: $LOG_DIR"

echo -e "${YELLOW}Step 3: Installing launchd plist...${NC}"
cp "$REPO_DIR/guardian/launchd/$LAUNCHD_PLIST" "$LAUNCHD_DEST"
chown root:wheel "$LAUNCHD_DEST"
chmod 644 "$LAUNCHD_DEST"

echo -e "${GREEN}✓${NC} plist installed"

echo -e "${YELLOW}Step 4: Loading daemon...${NC}"
launchctl load "$LAUNCHD_DEST"

echo -e "${GREEN}✓${NC} guardian loaded"

echo ""
echo -e "${GREEN}Done.${NC}"
echo "Logs: $LOG_DIR/guardian.log"
