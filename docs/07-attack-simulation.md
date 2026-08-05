# 07 — Full Attack Simulation

This is the end-to-end demonstration tying together FIM, the custom
correlation rule, and Active Response: a real SSH brute-force attack,
launched from Kali-Attacker against Ubuntu-Victim, detected and
automatically shut down by Wazuh.

## Setup

- **Attacker:** Kali-Attacker, `10.10.10.150`
- **Target:** Ubuntu-Victim, `10.10.10.151`, `sshd` enabled and running
- **Tool:** Hydra, targeting a real (non-existent-password) account `ozzy7`

Confirm the target is reachable first:

```bash
nc -zv 10.10.10.151 22
```

## The attack

A small wordlist, looped to generate sustained volume rather than a single
short burst:

```bash
echo -e "123456\npassword\nadmin\nletmein\nqwerty" > /tmp/passwords.txt
for i in {1..20}; do hydra -l ozzy7 -P /tmp/passwords.txt ssh://10.10.10.151; done
```

A single 5-password Hydra run only takes ~5 seconds and won't accumulate
enough failures to trip a frequency-based rule — looping it is what
generates a real sustained pattern.

## Step 1 — Individual failures logged (default rule)

```bash
sudo tail -F /var/ossec/logs/alerts/alerts.log
```

```
Rule: 5760 (level 5) -> 'sshd: authentication failed.'
Src IP: 10.10.10.150
Src Port: 46922
User: ozzy7
```

45 individual failed-auth alerts were captured in one test run
(`sudo grep -c "authentication_failed" alerts.log`).

## Step 2 — Pattern detected (custom rule)

Once 5+ failures from the same IP land within 120 seconds:

```
Rule: 100010 (level 10) -> 'SSH brute force attempt detected: multiple failed logins from same source IP'
Src IP: 10.10.10.150
User: ozzy7
```

## Step 3 — Active Response fires automatically

On Ubuntu-Victim's active-response log:

```
active-response/bin/firewall-drop: Starting
{...,"rule":{"level":10,"id":["100010"],"mitre":{"id":["T1110"],
"tactic":["Credential Access"],"technique":["Brute Force"]}}...}
{"module":"active_response","command":"add",
"origin":{"name":"firewall-drop"},"keys":["10.10.10.150"]}
active-response/bin/firewall-drop: Ended
```

## Step 4 — Block verified

```bash
sudo iptables -L -n | grep 10.10.10.150
```
```
DROP  all -- 10.10.10.150  0.0.0.0/0
DROP  all -- 10.10.10.150  0.0.0.0/0
```

From Kali, a follow-up connection attempt:

```bash
ssh ozzy7@10.10.10.151
```

...hangs indefinitely with no response — the packet is being silently
dropped, not rejected. A side effect also observed during the attack itself:
`hydra` began reporting `Socket error: Connection reset by peer` partway
through, likely SSH's own connection throttling kicking in independently of
Wazuh — an authentic detail worth noting, not a bug.

## Full chain, summarized

| Stage | Mechanism | Result |
|---|---|---|
| Attack | Hydra SSH brute-force | 45+ failed logins generated |
| Detect (baseline) | Default rule 5760 | Each failure logged individually |
| Detect (pattern) | Custom rule 100010 | Correlated 5+ fails/120s → level 10 alert, MITRE T1110 |
| Respond | Active Response (`firewall-drop`) | iptables DROP rule added for attacker IP |
| Confirm | `iptables -L -n` + failed SSH retry | Block verified, connection hangs |

See `screenshots/07-attack-simulation/` for the full visual sequence.
