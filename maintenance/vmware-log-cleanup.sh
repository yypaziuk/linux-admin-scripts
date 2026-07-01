#!/bin/bash
# Delete VMware log files older than N days. Intended for ESXi/vCenter log stores
# that grow without bound. Schedule via cron, e.g. daily at midnight:
#
#   crontab -e
#   0 0 * * * /root/vmware-log-cleanup.sh
#
# Review LOG_DIR and RETENTION_DAYS before use.

set -euo pipefail

# --- Configuration -----------------------------------------------------------
LOG_DIR="/storage/log/vmware"
RETENTION_DAYS=7
# -----------------------------------------------------------------------------

if [[ ! -d "$LOG_DIR" ]]; then
    echo "Directory $LOG_DIR does not exist."
    exit 1
fi

find "$LOG_DIR" -type f -mtime +"$RETENTION_DAYS" -exec rm -f {} \;

echo "Log cleanup completed ($LOG_DIR, older than $RETENTION_DAYS days)."
