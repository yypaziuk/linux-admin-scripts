#!/bin/bash
# Nextcloud update: enable maintenance mode, update all apps and system packages,
# run the built-in updater, then disable maintenance mode.
# Run as root.

NEXTCLOUD_DIR="/var/www/html/nextcloud"   # path to Nextcloud installation
PHP_MEMORY="512M"                          # memory_limit for occ app:update

cd "$NEXTCLOUD_DIR" || { echo "[ERROR] Directory not found: $NEXTCLOUD_DIR"; exit 1; }

sudo -u www-data php occ maintenance:mode --on || { echo "[ERROR] Could not enable maintenance mode"; exit 1; }

sudo -u www-data php -d memory_limit="$PHP_MEMORY" ./occ app:update --all \
    || echo "[WARNING] App update returned errors"

apt-get update -y && apt-get upgrade -y \
    || echo "[WARNING] System package upgrade returned errors"

sudo -u www-data php "$NEXTCLOUD_DIR/updater/updater.phar" --no-interaction \
    || echo "[WARNING] Nextcloud updater returned errors"

sudo -u www-data php occ maintenance:mode --off || { echo "[ERROR] Could not disable maintenance mode"; exit 1; }

echo "[SUCCESS] Nextcloud update completed."
