# 03 — Agent Deployment

Two Wazuh agents were deployed: one on **Kali-Attacker** (the offensive VM)
and one on **Ubuntu-Victim** (the SSH brute-force target). The manager also
monitors itself locally by default (agent ID `000`).

## Install steps (same process on both VMs)

Import the Wazuh GPG signing key into a dedicated keyring (not the deprecated
`apt-key`):

```bash
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | sudo gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import
sudo chmod 644 /usr/share/keyrings/wazuh.gpg
```

Add the repo, referencing that exact keyring path:

```bash
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | sudo tee /etc/apt/sources.list.d/wazuh.list
sudo apt update
```

Install, pointing at the manager's IP:

```bash
sudo WAZUH_MANAGER='10.10.10.10' apt install wazuh-agent -y
sudo systemctl daemon-reload
sudo systemctl enable wazuh-agent
sudo systemctl start wazuh-agent
sudo systemctl status wazuh-agent
```

## Verify from the manager

```bash
sudo /var/ossec/bin/agent_control -l
```

Expected output (once both are registered):

```
ID: 000, Name: <manager-hostname> (server), IP: 127.0.0.1, Active/Local
ID: 006, Name: kali, IP: any, Active
ID: 007, Name: ozzy, IP: any, Active
```

Also visible on the dashboard under **Endpoints/Agents**. See
`screenshots/03-agent-deployment/01-both-agents-active.png` (shows both
agents' local status plus the dashboard Agents page together).

## Gotchas hit during this deployment

- **Wrong keyring filename** (`wazuh.png` instead of `wazuh.gpg`) silently
  broke signature verification — always double-check the `signed-by=` path
  matches exactly what was created.
- **Duplicate agent name errors** (`ERROR: Duplicate agent name: kali`) came
  up repeatedly when re-registering after a failed first attempt. Fix:
  remove the stale entry on the **manager** with
  `sudo /var/ossec/bin/manage_agents` → `R` (remove), then re-run
  `agent-auth` on the agent. A `manage_agents` run on the *agent* itself only
  offers Import/Quit — key removal is manager-only.
- See `docs/08-troubleshooting.md` for the full story on both.
