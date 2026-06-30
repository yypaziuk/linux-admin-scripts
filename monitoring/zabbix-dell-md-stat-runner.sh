#!/bin/bash
# Dell MD Storage: SMcli performance stats runner for Zabbix.
# Arg 1: IP address of storage controller A
# Arg 2: IP address of storage controller B
# Collects virtual/physical disk performance stats to a temp file used by
# zabbix-dell-md-stat-get.sh.
# All errors/warnings are logged to syslog (grep zabbix-script).

smcli_bin="/opt/dell/mdstoragemanager/client/SMcli"
zabbix_lock="/tmp/lock.smcli_$1"
conf_file="/tmp/performanceStats_$1"

if [[ -z "$1" ]]; then
    logger -t zabbix-script -p local0.info "$0: missing the first input argument (controller A IP)"
    exit 0
fi

if [[ -z "$2" ]]; then
    logger -t zabbix-script -p local0.info "$0: missing the second input argument (controller B IP)"
    exit 0
fi

if [[ ! -f "${smcli_bin}" ]]; then
    logger -t zabbix-script -p local0.info "$0: ${smcli_bin} is not installed"
    exit 0
fi

if [[ -e "${zabbix_lock}" ]]; then
    logger -t zabbix-script -p local0.info "$0: SMcli is already running"
    exit 0
else
    touch "${zabbix_lock}"
    [[ -f "${conf_file}" ]] && rm -rf "${conf_file}"
    start_time=$(date '+%s')
    "${smcli_bin}" "$1" "$2" -c "show allVirtualDisks performanceStats;"  -o "${conf_file}"
    "${smcli_bin}" "$1" "$2" -c "show allPhysicalDisks performanceStats;" >> "${conf_file}"
    finish_time=$(date '+%s')
    echo $(( finish_time - start_time ))
fi

trap "rm -rf ${zabbix_lock}" EXIT HUP INT QUIT PIPE TERM
chmod 644 "${conf_file}"
[[ -e "${zabbix_lock}" ]] && rm -rf "${zabbix_lock}"
exit 0
