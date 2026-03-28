#!/bin/bash
set -euo pipefail

# Create a libvirt network with DNS disabled (avoids port 53 conflicts)
# Only DHCP runs — no dnsmasq DNS listener

NETWORK_NAME="vagrant-dev"

if virsh net-info "$NETWORK_NAME" &>/dev/null; then
  echo "Network '$NETWORK_NAME' already exists."
  virsh net-start "$NETWORK_NAME" 2>/dev/null || true
  exit 0
fi

virsh net-define /dev/stdin <<'EOF'
<network xmlns:dnsmasq='http://libvirt.org/schemas/network/dnsmasq/1.0'>
  <name>vagrant-dev</name>
  <forward mode='nat'/>
  <bridge name='virbr-dev' stp='on' delay='0'/>
  <dnsmasq:options>
    <dnsmasq:option value='port=0'/>
  </dnsmasq:options>
  <ip address='192.168.123.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.123.2' end='192.168.123.254'/>
    </dhcp>
  </ip>
</network>
EOF

virsh net-start "$NETWORK_NAME"
virsh net-autostart "$NETWORK_NAME"
echo "Network '$NETWORK_NAME' created and started."
