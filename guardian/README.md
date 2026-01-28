# Guardian Daemon (Phase 2)

## 🎯 Guardian Overview

The Guardian is a **macOS launchd-managed Python daemon** that monitors for security risks and automatically opens the Circuit Breaker when exposure is detected.

**Status:** Implemented in Phase 2

---

## 🏗️ Architecture

```
┌─────────────────────────────────┐
│         macOS Host                         │
│                                     │
│  ┌──────────────┐                  │
│  │  Guardian     │ (launchd)       │
│  │  Daemon      │                  │
│  └──────┬───────┘                  │
│         │                            │
│         │ Observes                  │
│         │ Updates state                │
│         │                             │
│  └──────────────────────┘                  │
│                                     │
│  ┌──────────────┐                  │
│  │  Circuit      │ (Nginx)        │
│  │  Breaker      │                  │
│  └──────┬───────┘                  │
│         │                            │
│         │ Updates state                 │
│         │ Watches state file             │
│         │                             │
│  └──────────────────────┘                  │
│                                     │
└─────────────────────────────────┘
```

**Flow:**
1. Guardian checks system state (every 30-60s)
2. If risk detected → updates state file to OPEN
3. Nginx (configured to watch state file) reloads and blocks access
4. User notified (future: desktop notifications)

---

## 📦 Implementation Details

### Guardian Daemon (Python)

**File:** `guardian/guardian.py`

**Features:**
- ✅ Configurable monitoring interval (default: 30s)
- ✅ Multiple security checks (ports, auth, Docker, Nginx)
- ✅ State file management with proper JSON encoding
- ✅ Structured logging (DEBUG/INFO levels)
- ✅ Environment variable support for paths
- ✅ Atomic state updates (no partial writes)

**Security Checks Implemented:**
1. **Public Port Exposure** - Detects binding to `0.0.0.0` or `::`
2. **Missing Authentication** - Checks auth file existence and non-empty
3. **Docker Published Ports** - Scans for Docker containers publishing ports publicly
4. **Nginx Configuration Validation** - Validates main nginx.conf syntax

**State Management:**
- Source of truth: `/usr/local/var/moltbot-hardened/state/breaker-state.json`
- States: CLOSED, OPEN, HALF (aliases for HALF-OPEN)
- Updates include: state, reason, detected_at (UTC), actor

**Logging:**
- Log file: `/usr/local/var/log/moltbot-hardened/guardian.log`
- Error log: `/usr/local/var/log/moltbot-hardened/guardian-error.log`
- Format: ISO 8601 timestamps with level and message
- Rotation: Future (logrotate)

---

### CLI Wrapper (Bash)

**File:** `bin/moltbot-hardened`

**Commands:**
- `status` - Read and display current breaker state
- `block` - Manually open circuit (set to OPEN)
- `recovery` - Request half-open state (verification mode)
- `open` - Manually close circuit (set to CLOSED)
- `verify` - Run all verification checks
- `start_guardian` - Start Guardian daemon via launchd
- `stop_guardian` - Stop Guardian daemon
- `logs` - Show Guardian logs (last 20 lines)
- `status_including_state` - Include state file in status output

**Features:**
- ✅ Colored output (GREEN for success, RED for errors, YELLOW for warnings)
- ✅ JSON pretty-printing with python3 -m json.tool
- ✅ Comprehensive verification checks
- ✅ Status display with Guardian log preview
- ✅ Proper error handling for all commands

---

### Launchd Integration

**File:** `guardian/launchd/io.moltbot.hardened.guardian.plist`

**Configuration:**
- Program: `/usr/local/bin/moltbot-hardened-guardian`
- Arguments: `--interval 30` (configurable)
- RunAtLoad: true (starts on login/boot)
- KeepAlive: true (restarts if it crashes)
- StandardOutPath: `/usr/local/var/log/moltbot-hardened/guardian.stdout.log`
- StandardErrorPath: `/usr/local/var/log/moltbot-hardened/guardian.stderr.log`
- ThrottleInterval: 10 (prevent rapid restarts)

**Environment Variables (via plist):**
- `MBH_GUARDIAN_LOG` - Guardian log file location
- `MBH_STATE_FILE` - Circuit Breaker state file
- `MBH_NGINX_DIR` - Nginx configuration directory
- `MBH_AUTH_FILE` - Auth file location
- `MBH_CONTROL_PORT` - Circuit Breaker control port
- `MBH_BREAKER_PORT` - Circuit Breaker breaker port
- `MBH_GUARDIAN_INTERVAL` - Monitoring interval (seconds)
- `MBH_CLI` - CLI command path (default `/usr/local/bin/moltbot-hardened`)

---

## 🔄 State Transitions

### Guardian-Initiated Transitions

**Guardian Risk Detected → OPEN**
- Guardian writes state file with `state="OPEN"`
- Includes: reason, detected_at, actor="guardian"
- Nginx auto-reloads (watching state file)
- User sees 403 Forbidden page

**Guardian Validates → HALF**
- Guardian writes state file with `state="HALF"`
- Only for recovery after manual fix
- Nginx serves 503 for normal requests, allows /health from 127.0.0.1

### User-Initiated Transitions

**User Manual Block → OPEN**
- CLI writes state file with `state="OPEN"`
- Includes: reason, detected_at, actor="user"
- Nginx auto-reloads

**User Recovery Request → HALF**
- CLI writes state file with `state="HALF"`
- Guardian will validate and potentially open again

**User Open Request → CLOSED**
- CLI writes state file with `state="CLOSED"`
- Guardian accepts this (no longer monitoring for risk)
- Nginx serves normal requests

---

## 🧪 Guardian Checks

See [guardian/checks.md](./checks.md) for detailed documentation of all checks.

**Summary:**

| Check | Detects | Opens Circuit | Priority |
|--------|----------|----------------|----------|
| Public port binding | ✅ | ✅ | 1 (CRITICAL) |
| Missing auth | ✅ | ✅ | 2 (HIGH) |
| Docker public ports | ✅ | ✅ | 3 (HIGH) |
| Nginx config invalid | ✅ | ✅ | 4 (MEDIUM) |
| HTML fingerprinting | ⚠️ | ❌ (Future) | 5 (LOW) |

---

## 🔒 Security Considerations

### What Guardian Protects

✅ Automatic detection of public exposure
✅ Automatic response to misconfiguration
✅ Runs independently of Moltbot code
✅ Survives Moltbot crashes (launchd KeepAlive)
✅ Comprehensive logging for audit trail
✅ User can override Guardian with manual commands

### What Guardian Doesn't Protect

❌ Local attackers (same machine)
❌ User intentionally disabling Guardian
❌ Code-level vulnerabilities in Moltbot
❌ Physical access to device

---

## 🚀 Deployment

### Installing Guardian

```bash
# 1. Install Guardian daemon and CLI wrapper
chmod +x /Users/vanessapellegrini/Documents/dev/moltbot-hardened/guardian/moltbot-hardened-guardian
sudo ln -sf /Users/vanessapellegrini/Documents/dev/moltbot-hardened/guardian/moltbot-hardened-guardian \
         /usr/local/bin/moltbot-hardened-guardian

chmod +x /Users/vanessapellegrini/Documents/dev/moltbot-hardened/guardian/moltbot-hardened-guardian
sudo ln -sf /Users/vanessapellegrini/Documents/dev/moltbot-hardened/guardian/moltbot-hardened-guardian \
         /usr/local/bin/moltbot-hardened

# 2. Install launchd plist
sudo cp /Users/vanessapellegrini/Documents/dev/moltbot-hardened/guardian/launchd/io.moltbot.hardened.guardian.plist \
       /Library/LaunchDaemons/

# 3. Load and start Guardian
launchctl load /Library/LaunchDaemons/io.moltbot.hardened.guardian.plist
launchctl start io.moltbot.hardened.guardian

# 4. Verify running
launchctl list | grep io.moltbot.hardened.guardian

# 5. Check logs
tail -f /usr/local/var/log/moltbot-hardened/guardian.log
```

### Uninstalling Guardian

```bash
# Stop and unload
launchctl stop io.moltbot.hardened.guardian
launchctl unload /Library/LaunchDaemons/io.moltbot.hardened.guardian.plist

# Remove plist
rm /Library/LaunchDaemons/io.moltbot.hardened.guardian.plist

# Remove binaries
sudo rm /usr/local/bin/moltbot-hardened-guardian
sudo rm /usr/local/bin/moltbot-hardened
```

---

## 📊 Observability

### Guardian Logs

**Location:** `/usr/local/var/log/moltbot-hardened/guardian.log`

**Format:**
```
[2026-01-27T20:00:00Z] INFO guardian started
[2026-01-27T20:00:30Z] INFO check cycle started
[2026-01-27T20:00:31Z] INFO public port detected: 0.0.0.0:8080
[2026-01-27T20:00:32Z] INFO opening circuit
[2026-01-27T20:00:32Z] INFO state saved: OPEN
[2026-01-27T20:00:35Z] INFO check cycle complete
```

### Guardian Error Logs

**Location:** `/usr/local/var/log/moltbot-hardened/guardian-error.log`

**What to look for:**
- Permission denied errors
- File system errors
- State file write failures
- Nginx communication errors

---

## 🔧 Troubleshooting

### Guardian Won't Start

**Problem:** `launchctl list` doesn't show Guardian.

**Solution:**
```bash
# Check if plist exists
ls -la /Library/LaunchDaemons/io.moltbot.hardened.guardian.plist

# Check if loaded
launchctl list | grep io.moltbot.hardened.guardian

# Check logs for errors
tail -20 /usr/local/var/log/moltbot-hardened/guardian-error.log

# Reload (if needed)
launchctl unload /Library/LaunchDaemons/io.moltbot.hardened.guardian.plist
launchctl load /Library/LaunchDaemons/io.moltbot.hardened.guardian.plist
launchctl start io.moltbot.hardened.guardian
```

### Guardian Keeps Crashing

**Problem:** Guardian dies repeatedly (KeepAlive restarts it).

**Solution:**
```bash
# Check error logs
tail -20 /usr/local/var/log/moltbot-hardened/guardian-error.log

# Common causes:
# 1. Python not found - fix path in plist
# 2. Permission denied - check file access
# 3. Import errors - check dependencies (http.client)
# 4. JSON errors - validate state file format
```

### Guardian Not Updating State

**Problem:** Guardian runs but state file doesn't update.

**Solution:**
```bash
# Check directory permissions
ls -la /usr/local/var/moltbot-hardened/state/

# Fix permissions (if needed)
sudo chown -R $(whoami):$(whoami) /usr/local/var/moltbot-hardened/state/

# Test write manually
echo '{"test": true}' | sudo tee /usr/local/var/moltbot-hardened/state/breaker-state.json
```

---

## 🔗 Integration with Circuit Breaker

### Guardian → Nginx Communication

**How it works:**
1. Guardian updates `/usr/local/var/moltbot-hardened/state/breaker-state.json`
2. Nginx watches state file (via inotify in future, polling now)
3. When state changes, Nginx reloads configuration
4. Nginx serves appropriate response based on state

**State File as API:**
- Guardian writes state (acts as producer)
- Nginx reads state (acts as consumer)
- State file is single source of truth

### Nginx Auto-Reload (Future)

**Current:** Polling (check every N seconds)

**Future:** Inotify-based instant reload
- Nginx detects file system changes
- Near-instant response to state changes
- Lower system overhead than polling

---

## 🚀 Future Enhancements (Phase 3+)

### Planned Features

1. **Desktop Notifications**
   - macOS notification center integration
   - Tray icon for status display
   - Clickable notifications for actions

2. **Advanced Scanning**
   - Shodan-like external scanning
   - Content analysis in responses
   - Anomaly detection in logs

3. **Automated Recovery**
   - Guardian validates configuration
   - Automatically moves to HALF-OPEN after fix
   - Auto-closes after verification passes

4. **Secret Management**
   - Integration with Vault or Akeyless
   - Secret rotation on detection
   - Secret injection prevention

5. **Docker Support**
   - Containerized deployment
   - Docker-aware security checks
   - Docker network isolation

---

## 📚 References

See [guardian/checks.md](./checks.md) for detailed check documentation.

See [PHASE1.md](../PHASE1.md) for Circuit Breaker implementation.

See [circuit-breaker/README.md](../circuit-breaker/README.md) for how Circuit Breaker works.

See [ops/recovery.md](../ops/recovery.md) for recovery procedures.

---

*Last updated: 27 January 2026*
