# Edge Cases

This document captures operational edge cases and how the system should behave.

---

## 1) State file missing

**Symptoms:** `moltbot-hardened status` shows `STATE_MISSING`.

**Expected behavior:** System fails closed (OPEN).

**Recovery:**
```bash
sudo moltbot-hardened block
```

---

## 2) State file corrupted / invalid JSON

**Symptoms:** CLI shows `STATE_INVALID`.

**Expected behavior:** System fails closed (OPEN).

**Recovery:**
```bash
sudo moltbot-hardened block
```

---

## 3) Nginx reload fails

**Symptoms:** CLI errors on `nginx -s reload`.

**Expected behavior:** No state change should be assumed safe.

**Recovery:**
```bash
sudo nginx -t
sudo nginx -s reload
```

---

## 4) Breaker bound to public interface

**Symptoms:** Guardian logs exposure, circuit opens repeatedly.

**Expected behavior:** OPEN state enforced.

**Recovery:**
- Fix bind to `127.0.0.1:8080`.
- Re-run recovery flow:
```bash
sudo moltbot-hardened recovery
sudo moltbot-hardened verify
sudo moltbot-hardened open
```

---

## 5) Auth file missing

**Symptoms:** Guardian opens circuit; verify fails.

**Expected behavior:** OPEN enforced until auth exists.

**Recovery:**
```bash
brew install httpd
sudo htpasswd -c /usr/local/etc/nginx/.htpasswd admin
```

---

## 6) Control plane down

**Symptoms:** `verify` fails (control plane not reachable).

**Expected behavior:** Remain in HALF or OPEN until control plane is up.

**Recovery:**
- Start control plane on `127.0.0.1:3000`.
- Re-run `verify`.

---

## 7) Guardian running but CLI missing

**Symptoms:** Guardian logs show failure to open circuit due to missing CLI.

**Expected behavior:** Exposure still logged, but breaker not changed.

**Recovery:**
```bash
sudo ./scripts/install-cli.sh
sudo launchctl unload /Library/LaunchDaemons/io.moltbot.hardened.guardian.plist
sudo launchctl load /Library/LaunchDaemons/io.moltbot.hardened.guardian.plist
```

---

## 8) Launchd blocked by symlinked binaries

**Symptoms:** `Operation not permitted` in guardian stderr.

**Expected behavior:** Guardian fails to start.

**Recovery:**
```bash
sudo ./scripts/install-cli.sh
sudo ./scripts/install-guardian.sh
```

---

*Last updated: 28 January 2026*
