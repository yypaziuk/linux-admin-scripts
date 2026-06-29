#!/bin/bash
# WireGuard watchdog: restarts the interface if the VPN peer is unreachable.
# Run via cron every 5-15 minutes:
#   */10 * * * * /usr/local/bin/wg-watchdog.sh

WG_IFACE="wg0"
VPN_PEER="10.0.0.1"    # IP of the WireGuard peer to ping (e.g. server's VPN address)
LOG="/var/log/wg-watchdog.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if ! ip link show "$WG_IFACE" &>/dev/null; then
    echo "[$TIMESTAMP] $WG_IFACE interface missing - starting..." >> "$LOG"
    systemctl start wg-quick@wg0
    exit 0
fi

if ! ping -c 3 -W 5 -I "$WG_IFACE" "$VPN_PEER" &>/dev/null; then
    echo "[$TIMESTAMP] VPN unreachable - restarting wg-quick@$WG_IFACE..." >> "$LOG"
    systemctl restart wg-quick@wg0
    sleep 3
    if ping -c 2 -W 5 -I "$WG_IFACE" "$VPN_PEER" &>/dev/null; then
        echo "[$TIMESTAMP] VPN restored OK" >> "$LOG"
    else
        echo "[$TIMESTAMP] VPN restore FAILED" >> "$LOG"
    fi
else
    echo "[$TIMESTAMP] VPN OK" >> "$LOG"
fi
