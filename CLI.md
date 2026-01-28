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

## Commands

### status

```bash
moltbot-hardened status
```

### block

```bash
moltbot-hardened block
```

Optional:

```bash
moltbot-hardened block --reason EXPOSURE_DETECTED --actor guardian
```

### recovery

```bash
moltbot-hardened recovery
```

### open

```bash
moltbot-hardened open
```

Optional:

```bash
moltbot-hardened open --reason MANUAL_OPEN --actor user
```

### verify

```bash
moltbot-hardened verify
```

## Overrides

You can override defaults with flags or env vars.

Example flags:

```bash
moltbot-hardened --state-file /tmp/breaker-state.json status
```

Environment variables:

- `MBH_STATE_FILE`
- `MBH_NGINX_DIR`
- `MBH_CONF_PREFIX`
- `MBH_AUTH_FILE`
- `MBH_CONTROL_PORT`
- `MBH_BREAKER_PORT`
