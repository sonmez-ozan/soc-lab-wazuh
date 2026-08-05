# 06 — Active Response: Automated IP Block

Detection alone tells you an attack happened. Active Response closes the
loop by automatically reacting to it — in this case, blocking the attacking
IP at the firewall level on the targeted host the moment the custom
brute-force rule (`100010`) fires.

## How it works

The **manager** decides when to trigger a response based on rule matches.
The actual blocking action runs **on the agent** (the targeted machine)
via a script bundled with every Wazuh agent install: `firewall-drop`, which
manipulates `iptables`.

## Configuration

Added to the manager's `/var/ossec/etc/ossec.conf`, at the top level inside
`<ossec_config>`:

```xml
<command>
  <name>firewall-drop</name>
  <executable>firewall-drop</executable>
  <timeout_allowed>yes</timeout_allowed>
</command>

<active-response>
  <disabled>no</disabled>
  <command>firewall-drop</command>
  <location>local</location>
  <rules_id>100010</rules_id>
  <timeout>300</timeout>
</active-response>
```

Full snippet: `configs/ossec.conf.active-response-snippet.xml`

- `<rules_id>100010</rules_id>` — only triggers for the custom brute-force
  correlation rule, not every SSH failure
- `<location>local</location>` — the response runs on the agent where the
  triggering event originated (the victim), not the manager
- `<timeout>300</timeout>` — the block auto-expires after 5 minutes, so the
  demo is repeatable without manual firewall cleanup between test runs

Apply:

```bash
sudo systemctl restart wazuh-manager
```

## Verified in practice

When rule `100010` fired during testing, the agent's active-response log
confirmed the block was actually executed:

```
active-response/bin/firewall-drop: Starting
{"...,"rule":{"level":10,"description":"SSH brute force attempt de[tected]...
"id":["100010"],"mitre":{"id":["T1110"],"tactic":["Credential Access"],
"technique":["Brute Force"]}}...}
{"module":"active_response","command":"add",
"origin":{"name":"firewall-drop"},"keys":["10.10.10.150"]}
active-response/bin/firewall-drop: Ended
```

And directly on the victim:

```bash
sudo iptables -L -n | grep 10.10.10.150
```

```
DROP  all -- 10.10.10.150  0.0.0.0/0
DROP  all -- 10.10.10.150  0.0.0.0/0
```

A follow-up SSH attempt from the attacker's IP hung indefinitely rather than
even reaching a password prompt — confirming the connection is dropped at
the firewall, not just failing authentication.

See `screenshots/06-active-response/`.
