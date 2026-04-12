#!/bin/bash

set -eu

echo "Generating firewall rules..."

# Use a temporary file for iptables-restore
RULES_FILE=$(mktemp)
TMP_ENTRIES=$(mktemp)
trap 'rm -f "$RULES_FILE" "$TMP_ENTRIES"' EXIT

cat <<EOF > "$RULES_FILE"
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]

# Flush existing rules in standard chains
-F INPUT
-F OUTPUT
-X

# Allow loopback
-A INPUT -i lo -j ACCEPT
-A OUTPUT -o lo -j ACCEPT

# Allow established and related connections
-A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Allow DNS (port 53 UDP/TCP)
-A OUTPUT -p udp --dport 53 -j ACCEPT
-A OUTPUT -p tcp --dport 53 -j ACCEPT

# Allow Google Public DNS (8.8.8.8, 8.8.4.4) for 53, 443, 853
-A OUTPUT -p udp -d 8.8.8.8 --dport 53 -j ACCEPT
-A OUTPUT -p tcp -d 8.8.8.8 --dport 53 -j ACCEPT
-A OUTPUT -p tcp -d 8.8.8.8 --dport 443 -j ACCEPT
-A OUTPUT -p tcp -d 8.8.8.8 --dport 853 -j ACCEPT

-A OUTPUT -p udp -d 8.8.4.4 --dport 53 -j ACCEPT
-A OUTPUT -p tcp -d 8.8.4.4 --dport 53 -j ACCEPT
-A OUTPUT -p tcp -d 8.8.4.4 --dport 443 -j ACCEPT
-A OUTPUT -p tcp -d 8.8.4.4 --dport 853 -j ACCEPT
EOF

# Process all entries from allow_hosts.d
run-parts .devcontainer/allow_hosts.d/ > "$TMP_ENTRIES"

# Use awk to handle IP/CIDR entries efficiently
awk '
  /^[0-9.]+(\/[0-9]+)?$/ {
    printf("-A OUTPUT -p tcp -d %s --dport 80 -j ACCEPT\n", $1)
    printf("-A OUTPUT -p tcp -d %s --dport 443 -j ACCEPT\n", $1)
  }
' "$TMP_ENTRIES" >> "$RULES_FILE"

# Now handle domains
grep -vE '^[0-9.]+(\/[0-9]+)?$' "$TMP_ENTRIES" | while read -r domain; do
  [ -z "$domain" ] && continue
  IPS=$(getent ahosts "$domain" | awk '{print $1}' | sort -u | grep -E '^[0-9.]+$')
  for ip in $IPS; do
    printf -- "-A OUTPUT -p tcp -d %s --dport 80 -j ACCEPT\n" "$ip" >> "$RULES_FILE"
    printf -- "-A OUTPUT -p tcp -d %s --dport 443 -j ACCEPT\n" "$ip" >> "$RULES_FILE"
    if [ "$domain" = "github.com" ]; then
      printf -- "-A OUTPUT -p tcp -d %s --dport 22 -j ACCEPT\n" "$ip" >> "$RULES_FILE"
    fi
  done
done

# Reject all other output immediately
# Use tcp-reset for TCP to get immediate Connection Refused
# Use icmp-port-unreachable for others
cat <<EOF >> "$RULES_FILE"
-A OUTPUT -p tcp -j REJECT --reject-with tcp-reset
-A OUTPUT -j REJECT --reject-with icmp-port-unreachable
COMMIT
EOF

echo "Applying firewall rules using iptables-restore..."
iptables-restore -w < "$RULES_FILE"

echo "Firewall rules applied."
