# Guardian Daemon (Phase 2)

## 🎯 Overview

The Guardian is a **macOS launchd-managed Python daemon** that monitors exposure risks and **opens the Circuit Breaker** when risk is detected.

**Status:** Implemented (Phase 2)

---

## ✅ What the Guardian Observes

The Guardian runs on an interval (default: 30s) and checks:

1. **Public bind on breaker port**
   - Detects `0.0.0.0` / `::` listeners via `lsof`.

2. **Missing or empty auth file**
   - Checks `/usr/local/etc/nginx/.htpasswd` exists and is not empty.

3. **Unauthenticated access**
   - Sends `GET /` to `127.0.0.1:<breaker_port>`.
   - If response is not `401/403/503`, it flags exposure.

---

## ✅ What the Guardian Decides

If **any** exposure signal is detected, Guardian does:

```
moltbot-hardened block --reason EXPOSURE_DETECTED --actor guardian
```

This sets state to **OPEN**, and Nginx is reloaded by the CLI.

---

## 🧩 Files

- Daemon: `guardian/guardian.py`
- Wrapper (local): `bin/moltbot-hardened-guardian`
- launchd plist: `guardian/launchd/io.moltbot.hardened.guardian.plist`

---

## ⚙️ Configuration (Environment Variables)

- `MBH_GUARDIAN_INTERVAL` (seconds)
- `MBH_GUARDIAN_LOG`
- `MBH_CLI` (default: `/usr/local/bin/moltbot-hardened`)
- `MBH_AUTH_FILE`
- `MBH_BREAKER_PORT`
- `MBH_CONTROL_PORT`
- `MBH_STATE_FILE`

---

## 📄 Logging

- Main log: `/usr/local/var/log/moltbot-hardened/guardian.log`
- stderr log: `/usr/local/var/log/moltbot-hardened/guardian.stderr.log`
- stdout log: `/usr/local/var/log/moltbot-hardened/guardian.stdout.log`

---

## 🚀 Install (Recommended)

```bash
sudo ./install-cli.sh
sudo ./install-guardian.sh
```

Then load the daemon:

```bash
sudo launchctl unload /Library/LaunchDaemons/io.moltbot.hardened.guardian.plist
sudo launchctl load /Library/LaunchDaemons/io.moltbot.hardened.guardian.plist
```

---

## 🔧 Run Once (Debug)

```bash
bin/moltbot-hardened-guardian --once --verbose
```

---

## ✅ Manual Verification Steps

1. **Missing auth file**
   - Remove or empty `/usr/local/etc/nginx/.htpasswd`
   - Guardian should open the breaker

2. **Public bind**
   - Temporarily bind breaker to `0.0.0.0:8080`
   - Guardian should open the breaker

3. **Unauthenticated access**
   - Disable auth in CLOSED config
   - Guardian should open the breaker

---

## 🔒 What Guardian Does NOT Do

- Does not auto-close the breaker
- Does not fix configuration automatically
- Does not provide alerts beyond logs

---

## 🔗 Related Docs

- `PHASE2.md`
- `INSTALL.md`
- `CLI.md`
