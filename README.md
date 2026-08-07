# soc-lab-wazuh

Project 2 of a home SOC lab build: a Wazuh SIEM/HIDS deployment with a working
detection-and-response pipeline, built on top of the segmented network from
[soc-lab-infrastructure](../soc-lab-infrastructure).

This isn't just a default install. It includes a custom File Integrity
Monitoring path, a custom correlation rule for SSH brute-force detection
(MITRE ATT&CK T1110), and an Active Response that automatically blocks the
attacking IP — all demonstrated end-to-end with a real simulated attack.

## Architecture

```
                    ┌──────────────────────┐
                    │   Wazuh-Manager      │
                    │  indexer + dashboard │
                    │      + manager       │
                    │    10.10.10.10       │
                    └──────────▲───────────┘
                               │ agents report events
                 ┌─────────────┴───────────────────┐
                 │                                 │
        ┌────────▼──────────┐             ┌────────▼──────────┐
        │  Kali-Attacker    │             │  Ubuntu-Victim    │
        │  10.10.10.150     │  attack     │  10.10.10.151     │
        │  (Attacker zone)  │ ────────▶   │  (Victims zone)  │
        └───────────────────┘   SSH       └───────────────────┘
```

All traffic between zones is mediated by pfSense (see Project 1). Outbound
internet access for both zones was deliberately scoped to DNS/HTTP/HTTPS only
(package installs), not opened wholesale — see `docs/02-network-firewall.md`.

A rendered version of this architecture, including the full detect →
respond chain, is at
[`diagrams/soc-lab-wazuh-architecture.png`](./diagrams/soc-lab-wazuh-architecture.png).

## The core story: attack → detect → respond

1. **Attack** — Kali runs a Hydra SSH brute-force against Ubuntu-Victim
2. **Detect (default rule)** — Wazuh's built-in rule 5760 logs each failed login
3. **Detect (custom rule)** — a custom correlation rule (`id 100010`) fires when
   5+ failures arrive from the same source IP within 120 seconds, tagged with
   MITRE ATT&CK technique T1110 (Brute Force)
4. **Respond** — an Active Response automatically runs `firewall-drop` on the
   victim, adding an iptables DROP rule for the attacker's IP
5. **Confirm** — a follow-up connection attempt from the attacker hangs/fails,
   verified directly with `iptables -L -n`

Full walkthrough with alert logs and screenshots in
`docs/07-attack-simulation.md`.

## What's in here

| Area | Status | Docs |
|---|---|---|
| Manager (indexer + dashboard + manager) | Done | `docs/01-manager-setup.md` |
| Network/firewall scoping for agent zones | Done | `docs/02-network-firewall.md` |
| Agent deployment (Kali + Ubuntu-Victim) | Done | `docs/03-agent-deployment.md` |
| Custom File Integrity Monitoring | Done | `docs/04-file-integrity-monitoring.md` |
| Custom detection rule (SSH brute-force) | Done | `docs/05-custom-detection-rule.md` |
| Active Response (auto-block) | Done | `docs/06-active-response.md` |
| Full attack simulation | Done | `docs/07-attack-simulation.md` |
| Troubleshooting / lessons learned | Done | `docs/08-troubleshooting.md` |

## Repo structure

```
soc-lab-wazuh/
├── README.md
├── docs/
│   ├── 01-manager-setup.md
│   ├── 02-network-firewall.md
│   ├── 03-agent-deployment.md
│   ├── 04-file-integrity-monitoring.md
│   ├── 05-custom-detection-rule.md
│   ├── 06-active-response.md
│   ├── 07-attack-simulation.md
│   └── 08-troubleshooting.md
├── configs/
│   ├── ossec.conf.fim-snippet.xml
│   ├── local_rules.xml
│   └── ossec.conf.active-response-snippet.xml
├── scripts/
│   └── trigger-fim-test.sh
├── screenshots/
│   ├── 01-manager-setup/
│   ├── 02-network-firewall/
│   ├── 03-agent-deployment/
│   ├── 04-file-integrity-monitoring/
│   ├── 05-custom-detection-rule/
│   ├── 06-active-response/
└── diagrams/
    └── soc-lab-wazuh-architecture.png
```

Screenshots referenced in the docs are numbered per-folder (e.g.
`screenshots/04-file-integrity-monitoring/02-fim-alert-detail.png`) and are
added separately — see each doc for the exact filenames expected.

## Stack

- **Wazuh 4.14.7** — manager, indexer, dashboard
- **pfSense** — firewall/routing between zones (from Project 1)
- **Kali Linux** — attacker VM, Wazuh agent installed
- **Ubuntu Server 26.04** — victim VM, Wazuh agent installed, SSH target
- **Hydra** — brute-force attack tool used for the simulation

## Related

- Project 1: [soc-lab-infrastructure](../soc-lab-infrastructure) — network design, pfSense, VLAN segmentation
- Project 3 (next): Suricata (NIDS)
