#!/bin/bash
# Pre-upgrade checks for a Zabbix server running on Ubuntu.
# Verifies Ubuntu version, Zabbix version, MySQL version, disk space,
# and connectivity to the Zabbix package repository.
# Edit the REQUIRED_* variables below to match your target versions.

REQUIRED_UBUNTU="20.04"
REQUIRED_ZABBIX="6.0.30"
REQUIRED_MYSQL="5.7"
REQUIRED_FREE_KB=1000000   # minimum free disk space on / (in KB, default 1 GB)

echo "[CHECK] Ubuntu version..."
ubuntu_version=$(lsb_release -rs)
if [[ "$ubuntu_version" == "$REQUIRED_UBUNTU" ]]; then
    echo "  OK: Ubuntu $ubuntu_version"
else
    echo "  FAIL: Ubuntu $ubuntu_version (expected $REQUIRED_UBUNTU)"
    exit 1
fi

echo "[CHECK] Zabbix server version..."
zabbix_version=$(zabbix_server -V 2>/dev/null | grep "zabbix_server" | awk '{print $3}')
if [[ "$zabbix_version" == "$REQUIRED_ZABBIX" ]]; then
    echo "  OK: Zabbix $zabbix_version"
else
    echo "  FAIL: Zabbix $zabbix_version (expected $REQUIRED_ZABBIX)"
    exit 1
fi

echo "[CHECK] MySQL version..."
mysql_version=$(mysql --version 2>/dev/null | awk '{print $5}' | awk -F',' '{print $1}')
if dpkg --compare-versions "$mysql_version" "ge" "$REQUIRED_MYSQL"; then
    echo "  OK: MySQL $mysql_version"
else
    echo "  FAIL: MySQL $mysql_version (need >= $REQUIRED_MYSQL)"
    exit 1
fi

echo "[CHECK] Free disk space on /..."
free_space=$(df / | awk 'NR==2 {print $4}')
if [ "$free_space" -ge "$REQUIRED_FREE_KB" ]; then
    echo "  OK: $((free_space / 1024)) MB free"
else
    echo "  FAIL: $((free_space / 1024)) MB free (need >= $((REQUIRED_FREE_KB / 1024)) MB)"
    exit 1
fi

echo "[CHECK] Zabbix repository reachability..."
if curl -s --head http://repo.zabbix.com/ | grep -q "200 OK"; then
    echo "  OK: repo.zabbix.com reachable"
else
    echo "  FAIL: repo.zabbix.com not reachable — check internet/firewall"
    exit 1
fi

echo "[SUCCESS] All pre-upgrade checks passed."
