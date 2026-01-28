# CLI Usage

The CLI is implemented in Python and lives at:

`bin/moltbot-hardened`

## Install

```bash
chmod +x bin/moltbot-hardened
sudo ln -s "$PWD/bin/moltbot-hardened" /usr/local/bin/moltbot-hardened
```

## Prerequisites

- Nginx installed and available on PATH
- lsof available (default on macOS)
- launchctl available (for Guardian management)

## Commands

### status

Display current breaker state.

```bash
moltbot-hardened status
```

**Output example:**
```
STATE: OPEN
REASON: EXPOSURE_DETECTED
DETECTED_AT: 2026-01-27T20:00:32Z
ACTOR: guardian
STATE_FILE: /usr/local/var/moltbot-hardened/state/breaker-state.json
```

**Flags:**
- None (uses default state file location)

---

### block

Manually open circuit (set to OPEN). Blocks all access to control plane.

```bash
moltbot-hardened block
```

**Optional:**
```bash
moltbot-hardened block --reason "SECURITY_EVENT" --actor admin
moltbot-hardened block --no-reload  # Update state without reloading Nginx
```

**Flags:**
- `--reason` - Custom reason for blocking (default: "MANUAL_BLOCK")
- `--actor` - Actor performing the action (default: "user")
- `--no-reload` - Update state file without reloading Nginx

**Output example:**
```
Breaker opened (OPEN)
Reason: SECURITY_EVENT
State saved to: /usr/local/var/moltbot-hardened/state/breaker-state.json
```

---

### recovery

Request half-open state (verification mode). Only allowlist traffic allowed.

```bash
moltbot-hardened recovery
```

**Optional:**
```bash
moltbot-hardened recovery --actor admin
moltbot-hardened recovery --no-reload
```

**Flags:**
- `--actor` - Actor performing the action (default: "user")
- `--no-reload` - Update state file without reloading Nginx

**Output example:**
```
Breaker in HALF
Only allowlist traffic allowed (127.0.0.1)
Run verification tests with: moltbot-hardened verify
State saved to: /usr/local/var/moltbot-hardened/state/breaker-state.json
```

---

### open

Manually close circuit (set to CLOSED). Admin panel becomes accessible.

```bash
moltbot-hardened open
```

**Optional:**
```bash
moltbot-hardened open --reason "FIX_COMPLETE" --actor admin
moltbot-hardened open --no-reload
```

**Flags:**
- `--reason` - Custom reason for opening (default: "MANUAL_OPEN")
- `--actor` - Actor performing the action (default: "user")
- `--no-reload` - Update state file without reloading Nginx

**Output example:**
```
Breaker closed (CLOSED)
Admin panel now accessible
Reason: FIX_COMPLETE
State saved to: /usr/local/var/moltbot-hardened/state/breaker-state.json
```

---

### verify

Run verification checks to ensure the system is safe to close the circuit.

```bash
moltbot-hardened verify
```

**Checks performed:**
1. Auth file exists and is not empty
2. No public ports exposed on breaker
3. Nginx configuration is valid
4. Control plane reachable on 127.0.0.1

**Output examples:**

**All checks passed:**
```
OK Auth configured
OK No public ports exposed on breaker
OK Nginx config valid
OK Control plane reachable on 127.0.0.1
All checks passed. Ready to close circuit.
Run: moltbot-hardened open
```

**Verification failed:**
```
OK Auth configured
FAIL Breaker listen check: public listener(s): 0.0.0.0
OK Nginx config valid
OK Control plane reachable on 127.0.0.1
Verification failed: 1 issue(s)
```

**Exit codes:**
- `0` - All checks passed
- `1` - One or more checks failed

---

### start_guardian

Start Guardian daemon via launchd. Loads and starts the Guardian service.

```bash
moltbot-hardened start_guardian
```

**What it does:**
1. Verifies Guardian plist exists
2. Checks if already running
3. Loads plist into launchd
4. Starts the Guardian daemon
5. Displays log file location

**Output examples:**

**First start:**
```
Loading Guardian daemon from: /Library/LaunchDaemons/io.moltbot.hardened.guardian.plist
Guardian daemon loaded successfully
Guardian daemon started successfully
Log file: /usr/local/var/log/moltbot-hardened/guardian.log
```

**Already running:**
```
Guardian daemon is already running
{
  "PID": 12345,
  "LastExitStatus": 0,
  ...
}
```

**Error (plist not found):**
```
ERROR: Guardian plist not found: /Library/LaunchDaemons/io.moltbot.hardened.guardian.plist
```

**Flags:**
- `--guardian-plist` - Path to Guardian plist (default: `/Library/LaunchDaemons/io.moltbot.hardened.guardian.plist`)
- `--guardian-log` - Path to Guardian log (default: `/usr/local/var/log/moltbot-hardened/guardian.log`)

---

### stop_guardian

Stop Guardian daemon. Stops and unloads the Guardian service from launchd.

```bash
moltbot-hardened stop_guardian
```

**What it does:**
1. Stops the Guardian daemon
2. Unloads plist from launchd

**Output examples:**

**Success:**
```
Stopping Guardian daemon: io.moltbot.hardened.guardian
Guardian daemon stopped successfully
```

**Not running:**
```
Guardian daemon is not running
```

**Flags:**
- `--guardian-plist` - Path to Guardian plist (default: `/Library/LaunchDaemons/io.moltbot.hardened.guardian.plist`)

---

### logs

Show Guardian logs. Displays the last N lines from the Guardian log file.

```bash
moltbot-hardened logs
```

**Optional:**
```bash
moltbot-hardened logs --lines 50
moltbot-hardened logs --lines 100
```

**Output example:**
```
Last 20 lines from /usr/local/var/log/moltbot-hardened/guardian.log:
[2026-01-27T20:00:00Z] INFO guardian started
[2026-01-27T20:00:30Z] INFO check cycle started
[2026-01-27T20:00:31Z] INFO public port detected: 0.0.0.0:8080
[2026-01-27T20:00:32Z] INFO opening circuit
[2026-01-27T20:00:32Z] INFO state saved: OPEN
[2026-01-27T20:00:35Z] INFO check cycle complete
...
```

**Flags:**
- `--lines` - Number of log lines to show (default: 20)
- `--guardian-log` - Path to Guardian log (default: `/usr/local/var/log/moltbot-hardened/guardian.log`)

---

## Overrides

You can override defaults with flags or environment variables.

### Example using flags:

```bash
moltbot-hardened --state-file /tmp/breaker-state.json status
moltbot-hardened --guardian-plist ~/dev/guardian.plist start_guardian
```

### Environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `MBH_STATE_FILE` | Path to breaker state file | `/usr/local/var/moltbot-hardened/state/breaker-state.json` |
| `MBH_NGINX_DIR` | Nginx config directory | `/usr/local/etc/nginx/servers` |
| `MBH_CONF_PREFIX` | Config file prefix | `moltbot-control` |
| `MBH_AUTH_FILE` | Auth file path | `/usr/local/etc/nginx/.htpasswd` |
| `MBH_CONTROL_PORT` | Control plane port | `3000` |
| `MBH_BREAKER_PORT` | Circuit breaker port | `8080` |
| `MBH_GUARDIAN_PLIST` | Guardian plist path | `/Library/LaunchDaemons/io.moltbot.hardened.guardian.plist` |
| `MBH_GUARDIAN_LOG` | Guardian log path | `/usr/local/var/log/moltbot-hardened/guardian.log` |

### Example using environment variables:

```bash
export MBH_STATE_FILE=/tmp/test-state.json
export MBH_GUARDIAN_LOG=/tmp/test-guardian.log
moltbot-hardened status
moltbot-hardened logs
```

---

## Common Workflows

### Manual Recovery After Guardian Block

1. **Investigate:**
   ```bash
   moltbot-hardened status
   moltbot-hardened logs
   ```

2. **Fix the issue** (e.g., change Nginx config to listen on 127.0.0.1)

3. **Verify the fix:**
   ```bash
   moltbot-hardened verify
   ```

4. **Close circuit:**
   ```bash
   moltbot-hardened open
   ```

### Start Guardian for First Time

```bash
# Install Guardian daemon
sudo cp guardian/launchd/io.moltbot.hardened.guardian.plist /Library/LaunchDaemons/

# Start via CLI
moltbot-hardened start_guardian

# Verify running
moltbot-hardened status
launchctl list | grep io.moltbot.hardened.guardian
```

### Emergency Stop Guardian

```bash
# Stop Guardian immediately
moltbot-hardened stop_guardian

# Manually close circuit (now Guardian won't override)
moltbot-hardened open
```

---

## Help

For command-specific help:

```bash
moltbot-hardened --help
moltbot-hardened status --help
moltbot-hardened logs --help
```

---

*Last updated: 27 January 2026*
