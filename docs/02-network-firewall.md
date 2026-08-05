# 02 — Network & Firewall Scoping

Both the Attacker (Kali) and Victims (Ubuntu) zones sit behind pfSense with
no outbound internet access by default — a deliberate design choice carried
over from Project 1's zone segmentation. Installing the Wazuh agent on each
VM requires internet access to pull the package from `packages.wazuh.com`,
so a **scoped** set of outbound rules was added rather than opening the zones
up wholesale.

## Rules added (per zone)

Three rules were added to each of the `ATTACKER` and `VICTIMS` interface tabs
in pfSense (Firewall → Rules):

| Protocol | Port | Purpose |
|---|---|---|
| UDP | 53 (DNS) | Name resolution |
| TCP | 80 (HTTP) | Package downloads |
| TCP | 443 (HTTPS) | Wazuh repo / package downloads |

Each rule is scoped to `<ZONE> subnets` as the source, destination `any`, and
explicitly describes its purpose (e.g. "Allow outbound HTTPS (package
installs) — scoped, not full internet access").

**Important:** pfSense treats a From/To port pair as a *range*, not two
separate ports. Putting HTTPS (443) in "From" and HTTP (80) in "To" on the
same rule creates a rule that passes every port from 80–443 — including
ports you don't want open. Each port needs its own separate rule.

See:
- `screenshots/02-network-firewall/01-victims-firewall-rules.png`
- `screenshots/02-network-firewall/02-attacker-firewall-rules.png`

## Why not just open outbound entirely?

The Attacker/Victims zones were built with deliberate segmentation in
Project 1. Fully opening outbound internet would undercut that design and
be harder to justify in a security lab context. Scoping to only the ports
needed for package management (80/443/53) keeps the isolation story intact
while still being practical — everything else stays blocked by the existing
"deny all" rule beneath these.

## Existing zone-to-zone rules (unchanged, for context)

Both zones already had explicit rules governing what they could reach inside
the lab (carried over from Project 1), e.g.:

- `Allow Attacker to reach Victims`
- `Allow Victims to reach Management (Attacker explicitly excluded per policy)`

These stayed untouched — only outbound internet access was added, nothing
about internal zone reachability changed.
