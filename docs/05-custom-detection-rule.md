# 05 — Custom Detection Rule: SSH Brute-Force Correlation

Wazuh's default ruleset already logs individual failed SSH logins (rule
`5760`, level 5). That's useful but noisy — a single failed login isn't an
attack. This custom rule correlates *repeated* failures from the *same
source* into a single higher-severity alert, which is what real brute-force
detection looks like.

## The rule

Added to `/var/ossec/etc/rules/local_rules.xml` on the manager, inside the
existing `<group name="local,syslog,sshd,">` block:

```xml
<rule id="100010" level="10" frequency="5" timeframe="120">
  <if_matched_sid>5760</if_matched_sid>
  <same_source_ip />
  <description>SSH brute force attempt detected: multiple failed logins from same source IP</description>
  <mitre>
    <id>T1110</id>
  </mitre>
  <group>authentication_failures,pci_dss_11.4,gdpr_IV_35.7.d,</group>
</rule>
```

Full file: `configs/local_rules.xml`

**What it does:**
- Watches for rule `5760` (SSH auth failed) firing **5+ times within 120
  seconds**
- `same_source_ip` scopes the correlation to a single attacking IP, so
  unrelated failures from different sources don't falsely combine
- Bumped to `level="10"` (vs. the base rule's level 5) — a pattern is more
  severe than one isolated failure
- Tagged with MITRE ATT&CK technique `T1110` (Brute Force)

Custom rule IDs must be `100000` or higher to avoid colliding with Wazuh's
built-in ruleset.

## Apply and verify

```bash
sudo systemctl restart wazuh-manager
sudo systemctl status wazuh-manager
```

Confirm no rule-loading errors in the log:

```bash
sudo tail -n 30 /var/ossec/logs/ossec.log | grep -i "error\|rule"
```

## Confirm it fires

Full attack walkthrough is in `docs/07-attack-simulation.md`, but the
relevant alert output:

```
Rule: 100010 (level 10) -> 'SSH brute force attempt detected: multiple failed logins from same source IP'
Src IP: 10.10.10.150
User: ozzy7
```

See `screenshots/05-custom-detection-rule/`.
