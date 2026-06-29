#!/bin/bash
# Zabbix speedtest collector: measures ping/download/upload to each host in host_list
# using iperf3 and writes XML results to a temp file for zabbix-speedtest-read.sh.
# Host list format: <ip> <name>  (one entry per line; # = comment)
# Designed to be triggered by Zabbix and run in the background.

IPERF_BIN="/usr/bin/iperf3"
PING_BIN="/usr/bin/ping"
HOST_LIST="/usr/local/etc/host_list"
TEMP_FILE="/tmp/zabbix-speedtest.temp"
CACHE_FILE="/tmp/zabbix-speedtest.cache"
LOCK_FILE="/tmp/zabbix-speedtest.lock"

log_err() { logger -t zabbix-script -p local0.info "$0: $1"; }

if [[ -e "$LOCK_FILE" ]]; then
    log_err "already running"
    echo 2; exit 0
fi
touch "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT HUP INT QUIT PIPE TERM

for bin in "$IPERF_BIN" "$PING_BIN" "$HOST_LIST"; do
    if [[ ! -f "$bin" ]]; then
        log_err "$bin not found"
        echo 3; exit 0
    fi
done

IFS=$'\n'
count=0
declare -a host_ip host_name ping_val down_val up_val

for line in $(cat "$HOST_LIST"); do
    item=$(echo "$line" | grep -v "^#")
    [[ -z "$item" ]] && continue
    ip=$(echo "$item" | awk '{print $1}')
    name=$(echo "$item" | awk '{print $2}')
    [[ -z "$ip" || -z "$name" ]] && continue
    count=$((count + 1))
    host_ip[$count]=$ip
    host_name[$count]=$name
    ping_val[$count]=$("$PING_BIN" -c 4 "$ip" | tail -1 | awk '{print $4}' | cut -d'/' -f2)
    dl=$("$IPERF_BIN" -f m -c "$ip" -R | grep sender | awk '{print $7}')
    down_val[$count]=$((1048576 * dl))
    ul=$("$IPERF_BIN" -f m -c "$ip" | grep sender | awk '{print $7}')
    up_val[$count]=$((1048576 * ul))
done

if [[ $count -eq 0 ]]; then
    echo '<status></status>' > "$TEMP_FILE"
    chmod 644 "$TEMP_FILE"
    echo 1; exit 0
fi

output='<status>'
for ((i=1; i<=count; i++)); do
    output="${output}<client>"
    output="${output}<name>${host_name[$i]}</name>"
    output="${output}<ip>${host_ip[$i]}</ip>"
    output="${output}<ping_value>${ping_val[$i]}</ping_value>"
    output="${output}<down_value>${down_val[$i]}</down_value>"
    output="${output}<upld_value>${up_val[$i]}</upld_value>"
    output="${output}</client>"
done
output="${output}</status>"

echo "$output" > "$TEMP_FILE"
chmod 644 "$TEMP_FILE"
echo 0
exit 0
