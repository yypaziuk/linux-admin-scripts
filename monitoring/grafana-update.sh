#!/bin/bash
# Update Grafana OSS to the latest release on Debian/Ubuntu.
# Compares installed version against GitHub releases API, downloads the .deb
# package from dl.grafana.com and installs it with dpkg.
# Run as root.

GRAFANA_URL="https://dl.grafana.com/oss/release"
TEMP_DIR="/tmp/grafana_update"
ARCH="amd64"        # change to arm64 for ARM systems
PACKAGE_TYPE="deb"

if ! command -v grafana-server >/dev/null; then
    echo "[ERROR] Grafana is not installed."
    exit 1
fi

INSTALLED_VERSION=$(grafana-server -v | awk '{print $2}')
echo "[INFO] Installed Grafana version: $INSTALLED_VERSION"

LATEST_VERSION=$(curl -s https://api.github.com/repos/grafana/grafana/releases/latest \
    | grep tag_name | cut -d '"' -f 4 | sed 's/^v//')

if [ -z "$LATEST_VERSION" ]; then
    echo "[ERROR] Could not retrieve latest Grafana version."
    exit 1
fi

echo "[INFO] Latest available version: $LATEST_VERSION"

if [ "$INSTALLED_VERSION" = "$LATEST_VERSION" ]; then
    echo "[INFO] Already up to date. No update needed."
    exit 0
fi

mkdir -p "$TEMP_DIR"
FILENAME="grafana_${LATEST_VERSION}_${ARCH}.${PACKAGE_TYPE}"
DOWNLOAD_URL="${GRAFANA_URL}/${FILENAME}"
DEST_FILE="${TEMP_DIR}/${FILENAME}"

echo "[INFO] Downloading: $DOWNLOAD_URL"
curl -L -o "$DEST_FILE" "$DOWNLOAD_URL" || { echo "[ERROR] Download failed."; exit 1; }

echo "[INFO] Installing Grafana $LATEST_VERSION ..."
sudo dpkg -i "$DEST_FILE" \
    && echo "[SUCCESS] Grafana updated to $LATEST_VERSION." \
    || { echo "[ERROR] Installation failed."; exit 1; }
