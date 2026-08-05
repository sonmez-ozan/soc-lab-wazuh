# 04 — Custom File Integrity Monitoring

Beyond Wazuh's default-monitored paths (`/etc`, `/bin`, `/sbin`, `/boot`,
`/usr/bin`, `/usr/sbin`), a custom path was added on the Kali agent to prove
FIM works end-to-end with a controlled, repeatable demo target rather than
just default coverage.

## Setup

Create a demo directory and file to monitor:

```bash
sudo mkdir -p /etc/wazuh-demo
echo "critical_setting=true" | sudo tee /etc/wazuh-demo/config.conf
```

Edit the agent's real config — **`/var/ossec/etc/ossec.conf`**, not
`/etc/ossec.conf` (see the troubleshooting note below) — and add inside the
existing `<syscheck>...</syscheck>` block:

```xml
<directories check_all="yes" report_changes="yes" realtime="yes">/etc/wazuh-demo</directories>
```

- `check_all="yes"` — monitors permissions, ownership, content hash, everything
- `report_changes="yes"` — shows exactly *what* changed, not just *that*
  something changed
- `realtime="yes"` — inotify-based, near-instant detection

Restart the agent to apply:

```bash
sudo systemctl restart wazuh-agent
```

Full config snippet: `configs/ossec.conf.fim-snippet.xml`

## Verify syscheck picked it up

```bash
sudo grep -i "wazuh-demo" /var/ossec/logs/ossec.log
```

Expected:

```
wazuh-syscheckd: INFO: (6003): Monitoring path: '/etc/wazuh-demo', with options '... report_changes | realtime'.
wazuh-syscheckd: INFO: (6016): Directory set for real time monitoring: '/etc/wazuh-demo'.
```

## Trigger and confirm the alert

```bash
echo "docs_demo_trigger=true" | sudo tee -a /etc/wazuh-demo/config.conf
```

On the manager:

```bash
sudo grep -a -A5 "Integrity checksum" /var/ossec/logs/alerts/alerts.log
```

Result:

```
Rule: 550 (level 7) -> 'Integrity checksum changed.'
File '/etc/wazuh-demo/config.conf' modified
Mode: realtime
Changed attributes: size,mtime,md5,sha1,sha256
Size changed from '203' to '232'
```

See:
- `screenshots/04-file-integrity-monitoring/01-fim-config-and-trigger.png`
- `screenshots/04-file-integrity-monitoring/02-fim-alert-detail.png`

## Why this took several attempts (short version)

The custom directory line was repeatedly added to the *wrong* file
(`/etc/ossec.conf`, which doesn't exist on this system — the real Wazuh agent
config lives at `/var/ossec/etc/ossec.conf`) or to the manager's own config
instead of the agent's. Once edited in the correct file and confirmed via
`grep` before restarting, it worked immediately. Full story in
`docs/08-troubleshooting.md`.
