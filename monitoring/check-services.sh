#!/bin/bash
# Check the active status of one or more systemd services.
# Edit SERVICES to match the services you want to monitor.

SERVICES=("apache2" "zabbix-agent" "zabbix-server" "mysql")

echo "===== Service Status Check ====="
for service in "${SERVICES[@]}"; do
    printf "%-25s " "$service:"
    if systemctl is-active --quiet "$service"; then
        echo "running"
    else
        echo "NOT running"
    fi
done
echo "================================"
