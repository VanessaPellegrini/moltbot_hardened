#!/bin/bash

# moltbot-hardened - CLI Installation Script
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_DIR="/usr/local/lib/moltbot-hardened"
BIN_PATH="/usr/local/bin/moltbot-hardened"
PYTHON_BIN="/Library/Developer/CommandLineTools/usr/bin/python3"

if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: This script must be run with sudo${NC}"
  echo "Usage: sudo $0"
  exit 1
fi

echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}  Moltbot Hardened - CLI Install${NC}"
echo -e "${GREEN}=========================================${NC}"
echo ""

echo -e "${YELLOW}Step 1: Installing CLI...${NC}"
mkdir -p "$INSTALL_DIR"
cp "$REPO_DIR/bin/moltbot-hardened" "$INSTALL_DIR/moltbot-hardened"
chmod +x "$INSTALL_DIR/moltbot-hardened"

echo -e "${YELLOW}Step 2: Creating wrapper...${NC}"
cat > "$BIN_PATH" <<'WRAP'
#!/bin/bash
exec /Library/Developer/CommandLineTools/usr/bin/python3 /usr/local/lib/moltbot-hardened/moltbot-hardened "$@"
WRAP
chmod +x "$BIN_PATH"

echo -e "${GREEN}✓${NC} CLI installed"

echo ""
echo -e "${GREEN}Done.${NC}"
echo "Binary: $BIN_PATH"
echo "Script: $INSTALL_DIR/moltbot-hardened"
