# 01 — Manager Setup

The Wazuh Manager VM runs all three core components on a single host:
the **indexer** (OpenSearch-based storage), the **dashboard** (web UI), and
the **manager** (rule engine + agent communication).

## Install

Wazuh's installer generates all service credentials automatically and writes
them to `wazuh-install-files/wazuh-passwords.txt` in the directory the
installer was run from.

To view the generated credentials:

```bash
sudo cat wazuh-install-files/wazuh-passwords.txt
```

> **Note:** this file is plain text — not a script. Running it with `bash`
> (e.g. `sudo bash wazuh-install-files/wazuh-passwords.txt`) will fail with a
> wall of `command not found` errors, since bash tries to interpret each
> `key: value` line as a shell command. Use `cat` or `less` to read it.

The credentials that matter most:
- `indexer_username: admin` / `indexer_password: <generated>` — logs into the
  web dashboard
- `api_username: wazuh-wui` / `api_password: <generated>` — used internally by
  the dashboard to talk to the manager's API

Save these somewhere durable (password manager) — they only exist in this
file on disk and aren't recoverable if lost.

## Verify all three services are running

```bash
sudo systemctl status wazuh-indexer wazuh-dashboard wazuh-manager
```

All three should show `active (running)`. See
`screenshots/01-manager-setup/02-services-active.png`.

## Access the dashboard

```
https://<manager-ip>
```

Self-signed certificate — browser will warn, accept and proceed. Log in with
the `admin` credentials from the passwords file.

See `screenshots/01-manager-setup/01-login-screen.png`.

## Known quirk: dashboard timeouts right after boot/restart

On both fresh boot and after `systemctl restart wazuh-manager`, the dashboard
can briefly show:

```
Something went wrong.
timeout of 20000ms exceeded
```

This happens because the dashboard tries to reach the manager's internal API
before it's fully finished initializing. It self-resolves within 30–60
seconds — a simple refresh is usually enough. See
`docs/08-troubleshooting.md` for the deeper root cause (host resource
contention) that made this worse during development.
