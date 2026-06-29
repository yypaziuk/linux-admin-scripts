#!/bin/bash
# Zabbix speedtest reader: returns cached XML from zabbix-speedtest-collect.sh.
# Call this from a Zabbix UserParameter to get the last collected result.
# If collect is still running, serves the previous cache to avoid a Zabbix timeout.

TEMP_FILE="/tmp/zabbix-speedtest.temp"
CACHE_FILE="/tmp/zabbix-speedtest.cache"
LOCK_FILE="/tmp/zabbix-speedtest.lock"

if [[ -e "$LOCK_FILE" ]]; then
    if [[ -f "$CACHE_FILE" ]]; then
        cat "$CACHE_FILE"
    else
        echo '<status></status>'
        logger -t zabbix-script -p local0.info "$0: collect running, no cache yet"
    fi
else
    if [[ -f "$TEMP_FILE" ]]; then
        cp "$TEMP_FILE" "$CACHE_FILE"
        cat "$CACHE_FILE"
    elif [[ -f "$CACHE_FILE" ]]; then
        cat "$CACHE_FILE"
    else
        echo '<status></status>'
        logger -t zabbix-script -p local0.info "$0: no data yet, run collect first"
    fi
fi

exit 0
