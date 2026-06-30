#!/bin/bash
# Nextcloud post-upgrade maintenance: repair DB indices, convert bigint columns,
# update mimetypes, restart services, and clear the Nextcloud application log.
# Run as root after a Nextcloud version upgrade.

NEXTCLOUD_DIR="/var/www/html/nextcloud"              # path to Nextcloud installation
LOG_FILE="/var/log/nextcloud_update.log"             # script log file
NEXTCLOUD_LOG="/var/log/nextcloud/nextcloud.log"     # Nextcloud app log to clear after upgrade
SERVICES="apache2 mysql php8.3-fpm redis"            # services to verify after restart

echo "[INFO] Starting Nextcloud post-upgrade maintenance..." | tee -a "$LOG_FILE"

if [ ! -d "$NEXTCLOUD_DIR" ]; then
    echo "[ERROR] Nextcloud directory not found: $NEXTCLOUD_DIR" | tee -a "$LOG_FILE"
    exit 1
fi
cd "$NEXTCLOUD_DIR" || exit 1

sudo -u www-data php occ db:add-missing-primary-keys
sudo -u www-data php occ db:convert-filecache-bigint
sudo -u www-data php occ db:add-missing-indices
sudo -u www-data php occ maintenance:repair --include-expensive
sudo -u www-data php occ maintenance:mimetype:update-db

for svc in apache2 redis; do
    sudo systemctl restart "$svc" || { echo "[ERROR] Failed to restart $svc" | tee -a "$LOG_FILE"; exit 1; }
done

for svc in $SERVICES; do
    systemctl is-active --quiet "$svc" || echo "[WARNING] Service $svc is not active!" | tee -a "$LOG_FILE"
done

if [ -f "$NEXTCLOUD_LOG" ]; then
    > "$NEXTCLOUD_LOG"
    echo "[INFO] Nextcloud log cleared." | tee -a "$LOG_FILE"
else
    echo "[WARNING] Nextcloud log not found at $NEXTCLOUD_LOG" | tee -a "$LOG_FILE"
fi

echo "[SUCCESS] Nextcloud post-upgrade maintenance completed." | tee -a "$LOG_FILE"
