#!/bin/bash
# Upgrade Zabbix Server (MySQL backend) to a new major version on Ubuntu.
# Also upgrades PHP 7.4 → 8.0.
# Steps: backup DB → upgrade PHP → replace apt repo → upgrade packages → apply DB schema.
# Run as root. The mysqldump and mysql commands will prompt for the DB password.

ZABBIX_VERSION="7.0"                       # target Zabbix major version
UBUNTU_CODENAME="ubuntu22.04"              # Ubuntu codename for the repo .deb filename
ZABBIX_DB_USER="zabbix"                    # MySQL user for the Zabbix database
ZABBIX_DB_NAME="zabbix"                    # Zabbix database name
BACKUP_FILE="/root/zabbix_backup.sql"      # backup destination

echo "[INFO] Backing up Zabbix database to $BACKUP_FILE ..."
mysqldump -u "$ZABBIX_DB_USER" -p "$ZABBIX_DB_NAME" > "$BACKUP_FILE"

echo "[INFO] Upgrading PHP 7.4 -> 8.0..."
apt-get remove -y php7.4 php7.4-*
add-apt-repository -y ppa:ondrej/php
apt-get update -q
apt-get install -y php8.0 php8.0-{fpm,cli,common,mbstring,gd,intl,bz2,xml,zip,curl,mysql}
a2dismod php7.4 && a2enmod php8.0
systemctl restart apache2
php -v

echo "[INFO] Removing old Zabbix repository..."
rm -f /etc/apt/sources.list.d/zabbix.list

echo "[INFO] Adding Zabbix $ZABBIX_VERSION repository..."
REPO_DEB="zabbix-release_${ZABBIX_VERSION}-1+${UBUNTU_CODENAME}_all.deb"
wget -q "https://repo.zabbix.com/zabbix/${ZABBIX_VERSION}/ubuntu/pool/main/z/zabbix-release/${REPO_DEB}"
dpkg -i "$REPO_DEB" && apt-get update -q

echo "[INFO] Upgrading Zabbix Server, frontend, and agent..."
apt-get install --only-upgrade -y \
    zabbix-server-mysql zabbix-frontend-php zabbix-agent zabbix-apache-conf

echo "[INFO] Applying new DB schema..."
systemctl stop zabbix-server
sudo -u zabbix zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz \
    | mysql -u "$ZABBIX_DB_USER" -p "$ZABBIX_DB_NAME"
systemctl start zabbix-server

systemctl status zabbix-server --no-pager
echo "[SUCCESS] Upgrade complete. Verify the web interface in a browser."
