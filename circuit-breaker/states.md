# Circuit Breaker States (Nginx Configurations)

This document contains the **full Nginx configs** for each breaker state.

All templates assume:

- Control plane listens on `127.0.0.1:3000`
- Breaker listens on `127.0.0.1:8080`
- Auth file: `/usr/local/etc/nginx/.htpasswd`
- Active config is symlinked to `/usr/local/etc/nginx/servers/moltbot-control.conf`

---

## CLOSED (Normal Operation)

```nginx
upstream moltbot_control {
    server 127.0.0.1:3000;
}

server {
    listen 127.0.0.1:8080;
    server_name _;

    auth_basic "Restricted";
    auth_basic_user_file /usr/local/etc/nginx/.htpasswd;

    location / {
        proxy_pass http://moltbot_control;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## OPEN (Blocked)

```nginx
server {
    listen 127.0.0.1:8080;
    server_name _;

    default_type application/json;
    location / {
        return 403 '{"state":"OPEN","reason":"MANUAL_BLOCK","detected_at":"0000-00-00T00:00:00Z","next_step":"Fix configuration and run recovery"}';
    }
}
```

---

## HALF (Recovery / Verification)

```nginx
upstream moltbot_control {
    server 127.0.0.1:3000;
}

server {
    listen 127.0.0.1:8080;
    server_name _;

    location /health/check {
        allow 127.0.0.1;
        deny all;
        proxy_pass http://moltbot_control/health;
    }

    default_type application/json;
    location / {
        return 503 '{"state":"HALF","message":"System in recovery mode","allowed":"127.0.0.1 /health/check only"}';
    }
}
```

---

## Activating a State

Copy the templates into `/usr/local/etc/nginx/servers/` and switch the active symlink:

```bash
sudo ln -sf /usr/local/etc/nginx/servers/moltbot-control.open.conf /usr/local/etc/nginx/servers/moltbot-control.conf
sudo nginx -s reload
```

---

## State Source of Truth

The current state lives at:

`/usr/local/var/moltbot-hardened/state/breaker-state.json`

The CLI updates this file and switches the active Nginx config.
