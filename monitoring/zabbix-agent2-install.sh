#!/bin/bash
# Install Zabbix Agent 2 from local .deb packages and configure it.
#
# Place this script in the same directory as the downloaded .deb files:
#   - zabbix-agent2_<version>_amd64.deb            (main agent, installed last)
#   - zabbix-agent2-plugin-mssql_<version>...deb   (optional plugins)
#   - zabbix-agent2-plugin-postgresql_<version>...deb
#   - zabbix-agent2-plugin-mongodb_<version>...deb
#
# The script installs the plugins first, then the agent, prompts for the Zabbix
# server IP, and updates the agent configuration accordingly.

set -euo pipefail

# --- Configuration -----------------------------------------------------------
# Version/distro suffix of the .deb files, e.g. "6.0.30-1+ubuntu22.04".
DEB_VERSION="6.0.30-1+ubuntu22.04"
CONFIG_FILE="/etc/zabbix/zabbix_agent2.conf"
# -----------------------------------------------------------------------------

packages=(
    "zabbix-agent2-plugin-mssql_${DEB_VERSION}_amd64.deb"
    "zabbix-agent2-plugin-postgresql_${DEB_VERSION}_amd64.deb"
    "zabbix-agent2-plugin-mongodb_${DEB_VERSION}_amd64.deb"
    "zabbix-agent2_${DEB_VERSION}_amd64.deb"
)

# Install each package; fix dependencies if dpkg fails.
for package in "${packages[@]}"; do
    if [[ -f "$package" ]]; then
        sudo dpkg -i "$package" || {
            echo "Error installing $package. Trying to fix dependencies..."
            sudo apt-get install -f -y
        }
    else
        echo "Package $package not found."
        exit 1
    fi
done

# Prompt for the Zabbix server IP.
read -rp "Enter the Zabbix server IP address: " server_ip

hostname=$(hostname)

# Back up the configuration before editing.
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.bak"

# Point the agent at the server and set its hostname.
sudo sed -i "s/^Server=.*/Server=${server_ip}/"       "$CONFIG_FILE"
sudo sed -i "s/^ServerActive=.*/ServerActive=${server_ip}/" "$CONFIG_FILE"
sudo sed -i "s/^Hostname=.*/Hostname=${hostname}/"    "$CONFIG_FILE"

sudo systemctl restart zabbix-agent2

echo "Zabbix Agent 2 installed and configured successfully."
