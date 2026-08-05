#!/bin/bash
# Run on the Kali-Attacker agent (or any agent with the /etc/wazuh-demo
# path configured in syscheck). Appends a timestamped line to the
# monitored file to trigger a real-time FIM alert, then tails the
# agent's own log so you can watch syscheck notice the change locally.
#
# Usage: sudo ./trigger-fim-test.sh

set -e

DEMO_FILE="/etc/wazuh-demo/config.conf"

if [ ! -f "$DEMO_FILE" ]; then
  echo "Demo file not found. Creating it first..."
  mkdir -p "$(dirname "$DEMO_FILE")"
  echo "critical_setting=true" > "$DEMO_FILE"
fi

echo "trigger_$(date +%s)=true" | tee -a "$DEMO_FILE"

echo ""
echo "Change written to $DEMO_FILE."
echo "Check the manager's alert log for a 'Rule: 550' Integrity checksum entry:"
echo "  sudo grep -a -A5 'Integrity checksum' /var/ossec/logs/alerts/alerts.log"
