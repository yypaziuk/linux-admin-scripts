#!/bin/bash
# Temporarily switch a server to a maintenance IP, run apt update/upgrade, then
# restore the original network configuration and reboot.
#
# Useful when the production IP has no direct internet access but a separate
# maintenance network/IP does. The script backs up the netplan file, applies a
# temporary static IP, updates the system, restores the original config, and
# reboots.
#
# WARNING: this script reboots the server at the end. Review the variables below
# before running. Run as root.

set -euo pipefail

# --- Configuration -----------------------------------------------------------
NETPLAN_FILE="/etc/netplan/00-installer-config.yaml"

# Temporary maintenance network settings (edit to match your environment).
TEMP_IP="10.0.0.10/24"
TEMP_GATEWAY="10.0.0.1"
TEMP_DNS=("10.0.0.2" "10.0.0.3")

# Services to stop before changing the IP (leave empty to skip).
STOP_SERVICES=("zabbix-proxy" "zabbix-agent2")
# -----------------------------------------------------------------------------

stop_services() {
    for svc in "${STOP_SERVICES[@]}"; do
        echo "Stopping ${svc}..."
        systemctl stop "$svc" || true
    done
}

backup_config() {
    echo "Backing up current netplan config..."
    cp "$NETPLAN_FILE" "${NETPLAN_FILE}.backup"
    echo "Backup saved to ${NETPLAN_FILE}.backup"
}

update_ip_config() {
    local ip=$1 gateway=$2
    local iface
    iface=$(ls /sys/class/net | grep -E '^e' | head -n 1)
    echo "Applying temporary IP ${ip} via ${iface} (gateway ${gateway})..."

    cat > "$NETPLAN_FILE" <<EOL
network:
  version: 2
  ethernets:
    ${iface}:
      dhcp4: no
      addresses:
        - ${ip}
      routes:
        - to: default
          via: ${gateway}
      nameservers:
        addresses:
          - ${TEMP_DNS[0]}
          - ${TEMP_DNS[1]}
EOL

    netplan apply
    echo "Temporary network configuration applied."
}

main() {
    echo "Starting maintenance update..."
    stop_services
    backup_config
    update_ip_config "$TEMP_IP" "$TEMP_GATEWAY"

    echo "Updating system packages..."
    apt update
    apt upgrade -y
    echo "Update complete."

    echo "Restoring original network configuration..."
    cp "${NETPLAN_FILE}.backup" "$NETPLAN_FILE"
    netplan apply

    echo "Rebooting server..."
    reboot
}

main
