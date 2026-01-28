#!/usr/bin/env python3
import argparse
import http.client
import logging
import os
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

DEFAULT_STATE_FILE = "/usr/local/var/moltbot-hardened/state/breaker-state.json"
DEFAULT_NGINX_DIR = "/usr/local/etc/nginx/servers"
DEFAULT_CONF_PREFIX = "moltbot-control"
DEFAULT_AUTH_FILE = "/usr/local/etc/nginx/.htpasswd"
DEFAULT_CONTROL_PORT = 3000
DEFAULT_BREAKER_PORT = 8080
DEFAULT_INTERVAL = 30
DEFAULT_LOG_FILE = "/usr/local/var/log/moltbot-hardened/guardian.log"
DEFAULT_CLI = "/usr/local/bin/moltbot-hardened"

LOCAL_ADDRS = {"127.0.0.1", "::1"}


def utc_now():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def load_env_int(name, default):
    value = os.environ.get(name)
    if value is None:
        return default
    try:
        return int(value)
    except ValueError:
        return default


def config_from_env():
    return {
        "state_file": os.environ.get("MBH_STATE_FILE", DEFAULT_STATE_FILE),
        "nginx_dir": os.environ.get("MBH_NGINX_DIR", DEFAULT_NGINX_DIR),
        "conf_prefix": os.environ.get("MBH_CONF_PREFIX", DEFAULT_CONF_PREFIX),
        "auth_file": os.environ.get("MBH_AUTH_FILE", DEFAULT_AUTH_FILE),
        "control_port": load_env_int("MBH_CONTROL_PORT", DEFAULT_CONTROL_PORT),
        "breaker_port": load_env_int("MBH_BREAKER_PORT", DEFAULT_BREAKER_PORT),
        "interval": load_env_int("MBH_GUARDIAN_INTERVAL", DEFAULT_INTERVAL),
        "log_file": os.environ.get("MBH_GUARDIAN_LOG", DEFAULT_LOG_FILE),
        "cli": os.environ.get("MBH_CLI", DEFAULT_CLI),
    }


def setup_logging(log_file, verbose):
    handlers = []
    if log_file:
        log_path = Path(log_file)
        log_path.parent.mkdir(parents=True, exist_ok=True)
        handlers.append(logging.FileHandler(log_path))
    handlers.append(logging.StreamHandler(sys.stdout))

    level = logging.DEBUG if verbose else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(asctime)sZ %(levelname)s guardian: %(message)s",
        handlers=handlers,
    )


def run_cmd(cmd):
    result = subprocess.run(cmd, capture_output=True, text=True)
    return result.returncode, result.stdout.strip(), result.stderr.strip()


def check_auth(auth_file):
    path = Path(auth_file)
    return path.exists() and path.is_file() and path.stat().st_size > 0


def check_public_listen(breaker_port):
    cmd = ["lsof", "-nP", f"-iTCP:{breaker_port}", "-sTCP:LISTEN"]
    code, out, err = run_cmd(cmd)
    if code != 0:
        return False, f"lsof failed: {err or out}"
    if not out.strip():
        return False, "no listeners on breaker port"

    bad = []
    for line in out.splitlines()[1:]:
        parts = line.split()
        if not parts:
            continue
        addr = parts[-2] if len(parts) >= 2 else ""
        if ":" in addr:
            addr = addr.split(":")[0]
        addr = addr.strip("[]")
        if addr in LOCAL_ADDRS:
            continue
        bad.append(addr or "unknown")

    if bad:
        return True, f"public listener(s): {', '.join(sorted(set(bad)))}"
    return False, ""


def check_unauth_access(breaker_port):
    try:
        conn = http.client.HTTPConnection("127.0.0.1", breaker_port, timeout=2)
        conn.request("GET", "/")
        resp = conn.getresponse()
        code = resp.status
        resp.read()
        conn.close()
    except Exception as exc:
        return False, f"breaker not reachable: {exc}"

    # 401 = auth challenge, 403/503 = blocked states
    if code in {401, 403, 503}:
        return False, ""
    return True, f"unexpected status {code} without auth"


def open_circuit(cli, reason):
    cmd = [cli, "block", "--reason", "EXPOSURE_DETECTED", "--actor", "guardian"]
    code, out, err = run_cmd(cmd)
    if code != 0:
        return False, err or out
    return True, out


def guardian_cycle(conf):
    issues = []

    auth_ok = check_auth(conf["auth_file"])
    if not auth_ok:
        issues.append(f"auth file missing/empty: {conf['auth_file']}")

    public, public_msg = check_public_listen(conf["breaker_port"])
    if public:
        issues.append(public_msg)

    unauth, unauth_msg = check_unauth_access(conf["breaker_port"])
    if unauth:
        issues.append(unauth_msg)

    if issues:
        logging.warning("exposure detected: %s", "; ".join(issues))
        ok, msg = open_circuit(conf["cli"], "EXPOSURE_DETECTED")
        if ok:
            logging.warning("circuit opened")
        else:
            logging.error("failed to open circuit: %s", msg)
        return False

    logging.info("ok")
    return True


def build_parser():
    conf = config_from_env()
    parser = argparse.ArgumentParser(prog="moltbot-hardened-guardian")
    parser.add_argument("--interval", type=int, default=conf["interval"])
    parser.add_argument("--once", action="store_true")
    parser.add_argument("--log-file", default=conf["log_file"])
    parser.add_argument("--cli", default=conf["cli"])
    parser.add_argument("--state-file", default=conf["state_file"])
    parser.add_argument("--nginx-dir", default=conf["nginx_dir"])
    parser.add_argument("--conf-prefix", default=conf["conf_prefix"])
    parser.add_argument("--auth-file", default=conf["auth_file"])
    parser.add_argument("--control-port", type=int, default=conf["control_port"])
    parser.add_argument("--breaker-port", type=int, default=conf["breaker_port"])
    parser.add_argument("--verbose", action="store_true")
    return parser


def main():
    args = build_parser().parse_args()
    conf = {
        "state_file": args.state_file,
        "nginx_dir": args.nginx_dir,
        "conf_prefix": args.conf_prefix,
        "auth_file": args.auth_file,
        "control_port": args.control_port,
        "breaker_port": args.breaker_port,
        "interval": args.interval,
        "log_file": args.log_file,
        "cli": args.cli,
    }

    setup_logging(args.log_file, args.verbose)
    logging.info("guardian started")

    while True:
        guardian_cycle(conf)
        if args.once:
            break
        time.sleep(conf["interval"])


if __name__ == "__main__":
    main()
