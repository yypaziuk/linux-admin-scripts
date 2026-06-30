#!/bin/bash
# Dell MD Storage: read performance statistics for Zabbix.
# Arg 1: IP address of storage controller (same as used in zabbix-dell-md-stat-runner.sh).
# Returns XML with virtual disk, controller, and physical disk performance data.
# Run zabbix-dell-md-stat-runner.sh first to populate the data file.
# All errors/warnings are logged to syslog (grep zabbix-script).

if [[ -z "$1" ]]; then
    logger -t zabbix-script -p local0.info "$0: missing input argument"
    exit 0
fi

IFS=$'\n'
zabbix_temp="/tmp/temp.zabbix-dell-md_stat_get_$1"
zabbix_lock="/tmp/lock.zabbix-dell-md_stat_get_$1"
conf_file="/tmp/performanceStats_$1"
smcli_lock="/tmp/lock.smcli_$1"

if [[ -e "${smcli_lock}" ]]; then
    logger -t zabbix-script -p local0.info "SMcli is already running, sending cached data"
    if [[ -e "${zabbix_temp}" ]]; then
        cat "${zabbix_temp}" | tr -d '\n '
    else
        echo "<performance></performance>"
    fi
    exit 0
fi

if [[ -e "${zabbix_lock}" ]]; then
    logger -t zabbix-script -p local0.info "$0 is already running"
    exit 0
else
    touch "${zabbix_lock}"
fi

trap "rm -rf ${zabbix_lock}" EXIT HUP INT QUIT PIPE TERM

if [[ ! -f "${conf_file}" ]]; then
    logger -t zabbix-script -p local0.info "$0: ${conf_file} does not exist"
    [[ -e "${zabbix_lock}" ]] && rm -rf "${zabbix_lock}"
    echo "<performance></performance>" > "${zabbix_temp}"
    exit 0
fi

echo "<performance>" > "${zabbix_temp}"

out_type_a=$(cat "${conf_file}" | grep "Storage Arrays" | wc -l)
if [[ ${out_type_a} -eq 0 ]]; then
    out_type_b=$(cat "${conf_file}" | grep "Objects" | wc -l)
else
    out_type_b=0
fi

#### virtual disk begin
echo "<virtual_disks>" >> "${zabbix_temp}"
total_vd=$(cat "${conf_file}" | grep "Virtual Disk" | wc -l)

if [[ ${total_vd} -gt 0 ]]; then
    while [[ ${total_vd} -ge 1 ]]; do
        echo "<vd>" >> "${zabbix_temp}"
        vd_item=$(cat "${conf_file}" | grep "Virtual Disk" | tail -n ${total_vd} | head -n 1 | sed 's/"//g' | sed 's/,/ /g')

        if [[ ${out_type_a} -eq 0 ]] && [[ ${out_type_b} -gt 0 ]]; then
            echo "<name>"           >> "${zabbix_temp}"
            echo "${vd_item}" | awk '{ print $3 }' >> "${zabbix_temp}"
            echo "</name>"          >> "${zabbix_temp}"
            echo "<data_rate>"      >> "${zabbix_temp}"
            echo "${vd_item}" | awk '{ print $8 }' >> "${zabbix_temp}"
            echo "</data_rate>"     >> "${zabbix_temp}"
            echo "<ops_rate>"       >> "${zabbix_temp}"
            echo "${vd_item}" | awk '{ print $10 }' >> "${zabbix_temp}"
            echo "</ops_rate>"      >> "${zabbix_temp}"
            echo "<read_cache_hit>" >> "${zabbix_temp}"
            echo "${vd_item}" | awk '{ print $5 }' >> "${zabbix_temp}"
            echo "</read_cache_hit>" >> "${zabbix_temp}"
            echo "<write_cache_hit>" >> "${zabbix_temp}"
            echo "${vd_item}" | awk '{ print $6 }' >> "${zabbix_temp}"
            echo "</write_cache_hit>" >> "${zabbix_temp}"
        elif [[ ${out_type_a} -gt 0 ]] && [[ ${out_type_b} -eq 0 ]]; then
            echo "<name>"           >> "${zabbix_temp}"
            echo "${vd_item}" | awk '{ print $3 }' >> "${zabbix_temp}"
            echo "</name>"          >> "${zabbix_temp}"
            echo "<data_rate>"      >> "${zabbix_temp}"
            echo "${vd_item}" | awk '{ print $9 }' >> "${zabbix_temp}"
            echo "</data_rate>"     >> "${zabbix_temp}"
            echo "<ops_rate>"       >> "${zabbix_temp}"
            echo "${vd_item}" | awk '{ print $11 }' >> "${zabbix_temp}"
            echo "</ops_rate>"      >> "${zabbix_temp}"
            echo "<read_cache_hit>" >> "${zabbix_temp}"
            echo "${vd_item}" | awk '{ print $6 }' >> "${zabbix_temp}"
            echo "</read_cache_hit>" >> "${zabbix_temp}"
            echo "<write_cache_hit>" >> "${zabbix_temp}"
            echo "${vd_item}" | awk '{ print $7 }' >> "${zabbix_temp}"
            echo "</write_cache_hit>" >> "${zabbix_temp}"
        else
            echo "<name></name><data_rate></data_rate><ops_rate></ops_rate><read_cache_hit></read_cache_hit><write_cache_hit></write_cache_hit>" >> "${zabbix_temp}"
        fi

        echo "</vd>" >> "${zabbix_temp}"
        total_vd=$(expr ${total_vd} - 1)
    done
else
    echo "<vd></vd>" >> "${zabbix_temp}"
fi
echo "</virtual_disks>" >> "${zabbix_temp}"
#### virtual disk end

#### controller begin
echo "<controllers>" >> "${zabbix_temp}"
total_ctl=$(cat "${conf_file}" | grep "CONTROLLER IN SLOT" | wc -l)

if [[ ${total_ctl} -gt 0 ]]; then
    while [[ ${total_ctl} -ge 1 ]]; do
        echo "<ctl>" >> "${zabbix_temp}"
        ctl_item=$(cat "${conf_file}" | grep "CONTROLLER IN SLOT" | tail -n ${total_ctl} | head -n 1 | sed 's/"//g' | sed 's/,/ /g')
        echo "<name>"       >> "${zabbix_temp}"
        echo "${ctl_item}" | awk '{ print $4 }' >> "${zabbix_temp}"
        echo "</name>"      >> "${zabbix_temp}"
        echo "<data_rate>"  >> "${zabbix_temp}"
        echo "${ctl_item}" | awk '{ print $10 }' >> "${zabbix_temp}"
        echo "</data_rate>" >> "${zabbix_temp}"
        echo "<ops_rate>"   >> "${zabbix_temp}"
        echo "${ctl_item}" | awk '{ print $12 }' >> "${zabbix_temp}"
        echo "</ops_rate>"  >> "${zabbix_temp}"
        echo "<read_cache_hit>"  >> "${zabbix_temp}"
        echo "${ctl_item}" | awk '{ print $7 }' >> "${zabbix_temp}"
        echo "</read_cache_hit>" >> "${zabbix_temp}"
        echo "<write_cache_hit>" >> "${zabbix_temp}"
        echo "${ctl_item}" | awk '{ print $8 }' >> "${zabbix_temp}"
        echo "</write_cache_hit>" >> "${zabbix_temp}"
        echo "</ctl>" >> "${zabbix_temp}"
        total_ctl=$(expr ${total_ctl} - 1)
    done
else
    echo "<ctl></ctl>" >> "${zabbix_temp}"
fi
echo "</controllers>" >> "${zabbix_temp}"
#### controller end

#### physical disk begin
echo "<physical_disks>" >> "${zabbix_temp}"
total_pd=$(cat "${conf_file}" | grep "Expansion Enclosure" | wc -l)

if [[ ${total_pd} -gt 0 ]]; then
    while [[ ${total_pd} -ge 1 ]]; do
        echo "<pd>" >> "${zabbix_temp}"
        vd_item=$(cat "${conf_file}" | grep "Expansion Enclosure" | tail -n ${total_pd} | head -n 1 | sed 's/"//g' | sed 's/,/ /g')
        echo "<name>"    >> "${zabbix_temp}"
        echo "${vd_item}" | awk '{ print $5 }' >> "${zabbix_temp}"
        echo "</name>"   >> "${zabbix_temp}"
        echo "<latency>" >> "${zabbix_temp}"
        echo "${vd_item}" | awk '{ print $6 }' >> "${zabbix_temp}"
        echo "</latency>" >> "${zabbix_temp}"
        echo "</pd>" >> "${zabbix_temp}"
        total_pd=$(expr ${total_pd} - 1)
    done
else
    echo "<pd></pd>" >> "${zabbix_temp}"
fi
echo "</physical_disks>" >> "${zabbix_temp}"
#### physical disk end

echo "</performance>" >> "${zabbix_temp}"
cat "${zabbix_temp}" | tr -d '\n '
[[ -e "${zabbix_lock}" ]] && rm -rf "${zabbix_lock}"
exit 0
