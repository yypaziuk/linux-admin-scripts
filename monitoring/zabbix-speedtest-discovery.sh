#!/bin/bash
# Zabbix LLD discovery: returns a JSON list of host names from the host_list file.
# Host list format: <ip> <name>  (one entry per line; lines starting with # are skipped)
# Drop into /etc/zabbix/scripts/ and call from a Zabbix UserParameter.

HOST_LIST="/usr/local/etc/host_list"

if [[ ! -f "$HOST_LIST" ]]; then
    echo '{"data":[]}'
    logger -t zabbix-script -p local0.info "$0: $HOST_LIST not found"
    exit 0
fi

IFS=$'\n'
count=0
declare -a names

for line in $(cat "$HOST_LIST"); do
    item=$(echo "$line" | grep -v "^#")
    [[ -z "$item" ]] && continue
    count=$((count + 1))
    names[$count]=$(echo "$item" | awk '{print $2}')
done

if [[ $count -eq 0 ]]; then
    echo '{"data":[]}'
    exit 0
fi

output='{"data":['
for ((i=1; i<=count; i++)); do
    output="${output}{\"{#CLIENT_NAME}\":\"${names[$i]}\"}"
    [[ $i -lt $count ]] && output="${output},"
done
output="${output}]}"

echo "$output"
exit 0
