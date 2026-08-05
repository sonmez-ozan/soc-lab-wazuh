# 08 — Troubleshooting & Lessons Learned

Real issues hit during this build, kept here rather than smoothed over —
this is arguably more useful to a reader than a clean first-try would be.

## 1. Reading the passwords file as a script

Running `sudo bash wazuh-install-files/wazuh-passwords.txt` instead of
`sudo cat ...` caused a wall of `command not found` errors, since bash tried
to interpret every `key: value` line as a shell command. The file is plain
text, not executable.

## 2. Dashboard "Something went wrong / timeout of 20000ms exceeded"

Happened repeatedly, especially right after boot or a manager restart. Root
cause: the dashboard's first request reaches the manager's internal API
before it's fully initialized. Usually self-resolves within 30–60 seconds;
a refresh is often enough.

Recurred intermittently even outside of startup — see item 6 below for the
deeper cause.

## 3. `apt update` hanging / "Network is unreachable" on agent VMs

Both Kali and Ubuntu-Victim sit in isolated pfSense zones with no outbound
internet by default (by design, from Project 1's segmentation). Installing
the Wazuh agent needs internet access to reach `packages.wazuh.com`. Fixed
by adding scoped outbound rules (DNS/HTTP/HTTPS only) per zone — see
`docs/02-network-firewall.md`. Two sub-issues along the way:

- Putting two different ports in one pfSense rule's From/To fields creates a
  *range* covering everything between them, not two separate allowed ports.
  Needs one rule per port.
- The GPG key file was referenced with the wrong extension in one attempt
  (`wazuh.png` instead of `wazuh.gpg`), silently breaking signature
  verification with `NO_PUBKEY` errors that looked network-related but
  weren't.

## 4. Editing the wrong `ossec.conf`

The FIM custom directory was added successfully in nano, restarted, and
still didn't show up in syscheck's monitored paths. Root cause:
`/etc/ossec.conf` **does not exist** on Wazuh agents/manager — the real
config lives at `/var/ossec/etc/ossec.conf`. Editing the nonexistent path
silently created a new file nano was happy to save, but Wazuh never read it.

Separately, the same mistake happened in reverse — editing the *manager's*
`ossec.conf` when the intent was to edit the *agent's* (Kali's) config,
since both files have an identical-looking `<syscheck>` block and the
terminal windows looked visually similar side by side. The one universal
tell: check the shell prompt (`kali@kali` vs. the manager's hostname
prompt) before running anything, not just the window layout.

## 5. Duplicate agent name during re-registration

After removing/reinstalling an agent, `agent-auth` failed repeatedly with:

```
ERROR: Duplicate agent name: kali. Unable to add agent (from manager)
```

`manage_agents` run on the **agent itself** only offers Import/Quit —
"Key removal only available on a master." The removal has to happen on the
**manager**:

```bash
sudo /var/ossec/bin/manage_agents
# → R (remove), enter the agent ID
```

A `systemctl restart wazuh-manager` afterward was also necessary in
practice — the running `wazuh-authd` process didn't always pick up the
keys-file change immediately.

## 6. Soft lockups / host resource starvation

```
watchdog: BUG: soft lockup - CPU#0 stuck for 1854s! [swapper/0:0]
```

Appeared repeatedly on the manager and later on Ubuntu-Victim. Root cause:
running too many VirtualBox VMs simultaneously (pfSense + Kali + Manager +
Ubuntu-Victim, alongside background host apps) starved individual VMs of
consistent CPU scheduling, which the guest kernel's watchdog interpreted as
a lockup. This was the underlying cause of most of the intermittent
dashboard timeouts and flaky agent registrations throughout the build.

Mitigation: closing unnecessary host applications (Discord, Spotify, Steam)
and keeping only the VMs actively in use running at once. A 32GB+ host with
4 VMs running concurrently was generally stable; less headroom made these
symptoms reappear.

## 7. Hydra wordlist disappearing between sessions

`/tmp/passwords.txt` didn't persist across a VM reboot/sleep — `/tmp` is
cleared on boot on this distro. Simple fix: recreate it each session before
re-running the attack.

## 8. Rootcheck false positive

```
Rule: 510 (level 7) -> 'Host-based anomaly detection event (rootcheck).'
Trojaned version of file '/usr/bin/md5sum' detected.
```

Wazuh's rootcheck compares binary signatures against a known-rootkit
database and occasionally flags legitimate system binaries after routine OS
updates change them slightly. Unrelated to the attack simulation work;
noted here so it isn't mistaken for a real compromise if it recurs.
