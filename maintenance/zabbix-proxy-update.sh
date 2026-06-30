#!/bin/bash
# Upgrade Zabbix Proxy (MySQL backend) to a new major version on Ubuntu.
# Steps: backup DB → replace apt repo → upgrade package → apply DB schema.
# Run as root. The mysqldump and mysql commands will prompt for the DB password.

ZABBIX_VERSION="7.0"                          # target Zabbix major version
UBUNTU_CODENAME="ubuntu22.04"                 # Ubuntu codename for the repo .deb filename
ZABBIX_DB_USER="zabbix"                       # MySQL user for the proxy database
ZABBIX_DB_NAME="zabbix_proxy"                 # proxy database name
BACKUP_FILE="/root/zabbix_proxy_backup.sql"   # backup destination

echo "[INFO] Backing up Zabbix Proxy database to $BACKUP_FILE ..."
mysqldump -u "$ZABBIX_DB_USER" -p "$ZABBIX_DB_NAME" > "$BACKUP_FILE"

echo "[INFO] Removing old Zabbix repository..."
rm -f /etc/apt/sources.list.d/zabbix.list

echo "[INFO] Adding Zabbix $ZABBIX_VERSION repository..."
REPO_DEB="zabbix-release_${ZABBIX_VERSION}-1+${UBUNTU_CODENAME}_all.deb"
wget -q "https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/ubuntu/pool/main/z/zabbix-release/${REPO_DEB}"
dpkg -i "$REPO_DEB" && apt-get update -q

echo "[INFO] Upgrading zabbix-proxy-mysql..."
apt-get install --only-upgrade -y zabbix-proxy-mysql

echo "[INFO] Applying new DB schema..."
systemctl stop zabbix-proxy
sudo -u zabbix zcat /usr/share/doc/zabbix-proxy-mysql*/create.sql.gz \
    | mysql -u "$ZABBIX_DB_USER" -p "$ZABBIX_DB_NAME"
systemctl start zabbix-proxy

systemctl status zabbix-proxy --no-pager
echo "[SUCCESS] Upgrade complete. Check logs: tail -f /var/log/zabbix/zabbix_proxy.log"
