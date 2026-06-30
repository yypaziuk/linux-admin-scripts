#!/bin/bash
# Dell MD Storage: Zabbix LLD discovery script.
# Arg 1: IP address of storage controller.
# Arg 2: component type — one of:
#         dp | dg | vd | pd | sfp | ether | sas | fc |
#         battery | sensor | fan | psu | psf | controller | enclosure | drawer
# Returns Zabbix LLD JSON. Run zabbix-dell-md-runner.sh first to populate the data file.
# All errors/warnings are logged to syslog (grep zabbix-script).

if [[ -z "$1" ]]; then
    logger -t zabbix-script -p local0.info "$0: missing input argument (controller IP)"
    exit 0
fi

if [[ -z "$2" ]]; then
    logger -t zabbix-script -p local0.info "$0: missing input argument (component type)"
    exit 0
fi

IFS=$'\n'
zabbix_temp="/tmp/temp.zabbix-dell-md_dis_${1}_${2}"
zabbix_lock="/tmp/lock.zabbix-dell-md_dis_${1}_${2}"
conf_file="/tmp/storageArray_$1"
smcli_lock="/tmp/lock.smcli_$1"

if [[ -e "${smcli_lock}" ]]; then
    logger -t zabbix-script -p local0.info "SMcli is already running"
    if [[ -e "${zabbix_temp}" ]]; then cat "${zabbix_temp}"; else echo '{"data":[{}]}'; fi
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
    echo '{"data":[{}]}'
    exit 0
fi

#### Disk Pools
dp_discovery () {
total_dp=$(cat "${conf_file}" | grep "Total Disk Pools:" | awk '{ print $4 }')
grep_dp="Name *Status *Usable Capacity *Used Capacity *Free Capacity *Preservation Capacity *Physical Disk/Media Type *Virtual Disks *Secure Capable"
if [[ ${total_dp} -gt 0 ]]; then
    output='{"data":['
    while [[ ${total_dp} -ge 1 ]]; do
        dp_name=$(cat "${conf_file}" | grep -A ${total_dp} "${grep_dp}" | tail -n 1 | awk '{ print $1 }')
        output="${output}{\"{#DP_NAME}\": \"${dp_name}\""
        total_dp=$(expr ${total_dp} - 1)
        if [[ ${total_dp} -gt 0 ]]; then output="${output}},"; else output="${output}]}"; fi
    done
    echo "${output}" > "${zabbix_temp}"
else
    echo '{"data":[{}]}' > "${zabbix_temp}"
fi
}

#### Disk Groups
dg_discovery () {
total_dg=$(cat "${conf_file}" | grep "Total Disk Groups:" | awk '{ print $4 }')
grep_dg="Name *Status *Usable *Capacity *Used *Capacity *Free *Capacity *RAID *Level *Physical *Disk/Media *Type *Virtual *Disks *Secure *Capable"
if [[ ${total_dg} -gt 0 ]]; then
    output='{"data":['
    while [[ ${total_dg} -ge 1 ]]; do
        dg_name=$(cat "${conf_file}" | grep -A ${total_dg} "${grep_dg}" | tail -n 1 | awk '{ print $1 }')
        output="${output}{\"{#DG_NAME}\": \"${dg_name}\""
        total_dg=$(expr ${total_dg} - 1)
        if [[ ${total_dg} -gt 0 ]]; then output="${output}},"; else output="${output}]}"; fi
    done
    echo "${output}" > "${zabbix_temp}"
else
    echo '{"data":[{}]}' > "${zabbix_temp}"
fi
}

#### Virtual Disks
vd_discovery () {
total_vd=$(cat "${conf_file}" | grep "Number of standard virtual disks:" | awk '{ print $6 }')
if [[ ${total_vd} -gt 0 ]]; then
    check_grep_vd=$(cat "${conf_file}" | grep "Name *Thin Provisioned *Status *Capacity *Accessible by *Source" | wc -l)
    if [[ ${check_grep_vd} -eq 1 ]]; then
        grep_vd="Name *Thin Provisioned *Status *Capacity *Accessible by *Source"
    else
        check_grep_vd=$(cat "${conf_file}" | grep "Name *Thin Provisioned *SSD Cache *Status *Capacity *Accessible by *Source" | wc -l)
        [[ ${check_grep_vd} -eq 1 ]] && grep_vd="Name *Thin Provisioned *SSD Cache *Status *Capacity *Accessible by *Source"
    fi
    if [[ ${check_grep_vd} -eq 1 ]]; then
        output='{"data":['
        while [[ ${total_vd} -ge 1 ]]; do
            vd_name=$(cat "${conf_file}" | grep -A ${total_vd} "${grep_vd}" | tail -n 1 | awk '{ print $1 }')
            output="${output}{\"{#VD_NAME}\": \"${vd_name}\""
            total_vd=$(expr ${total_vd} - 1)
            if [[ ${total_vd} -gt 0 ]]; then output="${output}},"; else output="${output}]}"; fi
        done
        echo "${output}" > "${zabbix_temp}"
    fi
else
    echo '{"data":[{}]}' > "${zabbix_temp}"
fi
}

#### Physical Disks
pd_discovery () {
total_pd=$(cat "${conf_file}" | grep "Number of physical disks:" | awk '{ print $5 }')
if [[ ${total_pd} -gt 0 ]]; then
    check_grep_pd=$(cat "${conf_file}" | grep "ENCLOSURE, *SLOT *STATUS *CAPACITY *MEDIA TYPE *INTERFACE TYPE *CURRENT DATA RATE *PRODUCT ID *FIRMWARE VERSION *CAPABILITIES" | wc -l)
    if [[ ${check_grep_pd} -eq 1 ]]; then
        grep_pd="ENCLOSURE, *SLOT *STATUS *CAPACITY *MEDIA TYPE *INTERFACE TYPE *CURRENT DATA RATE *PRODUCT ID *FIRMWARE VERSION *CAPABILITIES"
        output='{"data":['
        while [[ ${total_pd} -ge 1 ]]; do
            pd_name=$(cat "${conf_file}" | grep -A ${total_pd} "${grep_pd}" | tail -n 1 | awk '{ print $2 }')
            output="${output}{\"{#PD_NAME}\": \"${pd_name}\""
            total_pd=$(expr ${total_pd} - 1)
            if [[ ${total_pd} -gt 0 ]]; then output="${output}},"; else output="${output}]}"; fi
        done
        echo "${output}" > "${zabbix_temp}"
    else
        check_grep_pd=$(cat "${conf_file}" | grep "ENCLOSURE, *DRAWER, *SLOT *STATUS *CAPACITY *MEDIA TYPE *INTERFACE TYPE *CURRENT DATA RATE *PRODUCT ID *FIRMWARE VERSION *CAPABILITIES" | wc -l)
        if [[ ${check_grep_pd} -eq 1 ]]; then
            grep_pd="ENCLOSURE, *DRAWER, *SLOT *STATUS *CAPACITY *MEDIA TYPE *INTERFACE TYPE *CURRENT DATA RATE *PRODUCT ID *FIRMWARE VERSION *CAPABILITIES"
            output='{"data":['
            while [[ ${total_pd} -ge 1 ]]; do
                pd_enclosure=$(cat "${conf_file}" | grep -A ${total_pd} "${grep_pd}" | tail -n 1 | awk '{ print $1 }')
                pd_drawer=$(cat "${conf_file}" | grep -A ${total_pd} "${grep_pd}" | tail -n 1 | awk '{ print $2 }')
                pd_slot=$(cat "${conf_file}" | grep -A ${total_pd} "${grep_pd}" | tail -n 1 | awk '{ print $3 }')
                pd_name=$(echo "${pd_enclosure}${pd_drawer}${pd_slot}" | tr ',' '-')
                output="${output}{\"{#PD_NAME}\": \"${pd_name}\""
                total_pd=$(expr ${total_pd} - 1)
                if [[ ${total_pd} -gt 0 ]]; then output="${output}},"; else output="${output}]}"; fi
            done
            echo "${output}" > "${zabbix_temp}"
        fi
    fi
else
    echo '{"data":[{}]}' > "${zabbix_temp}"
fi
}

#### Generic counter-based discoveries (SFP, Ethernet, SAS, FC, Battery, Sensor, Fan, PSU, PSF)
counter_discovery () {
local macro="$1" grep_str="$2" field="$3"
local total
total=$(cat "${conf_file}" | grep "${grep_str}" | awk "{ print \$${field} }")
if [[ ${total} -gt 0 ]]; then
    output='{"data":['
    while [[ ${total} -ge 1 ]]; do
        output="${output}{\"{#${macro}}\": \"${total}\""
        total=$(expr ${total} - 1)
        if [[ ${total} -gt 0 ]]; then output="${output}},"; else output="${output}]}"; fi
    done
    echo "${output}" > "${zabbix_temp}"
else
    echo '{"data":[{}]}' > "${zabbix_temp}"
fi
}

#### Controller / Enclosure (0-indexed)
indexed_discovery () {
local macro="$1" grep_str="$2" field="$3"
local total
total=$(cat "${conf_file}" | grep "${grep_str}" | awk "{ print \$${field} }")
if [[ ${total} -gt 0 ]]; then
    output='{"data":['
    while [[ ${total} -ge 1 ]]; do
        name=$(expr ${total} - 1)
        output="${output}{\"{#${macro}}\": \"${name}\""
        total=$(expr ${total} - 1)
        if [[ ${total} -gt 0 ]]; then output="${output}},"; else output="${output}]}"; fi
    done
    echo "${output}" > "${zabbix_temp}"
else
    echo '{"data":[{}]}' > "${zabbix_temp}"
fi
}

#### Drawers
drawer_discovery () {
local check total item_drawer=0
check=$(cat "${conf_file}" | grep "Drawers Detected:" | wc -l)
if [[ ${check} -eq 1 ]]; then
    total=$(cat "${conf_file}" | grep "Drawers Detected:" | awk '{ print $3 }')
    if [[ ${total} -gt 0 ]]; then
        output='{"data":['
        while [[ ${total} -ge 1 ]]; do
            output="${output}{\"{#DRAWER_NAME}\": \"${item_drawer}\""
            total=$(expr ${total} - 1)
            item_drawer=$(expr ${item_drawer} + 1)
            if [[ ${total} -gt 0 ]]; then output="${output}},"; else output="${output}]}"; fi
        done
        echo "${output}" > "${zabbix_temp}"
    else
        echo '{"data":[{}]}' > "${zabbix_temp}"
    fi
else
    echo '{"data":[{}]}' > "${zabbix_temp}"
fi
}

unknown_discovery () {
    logger -t zabbix-script -p local0.info "$0: unknown or missing component type '$2'"
    echo '{"data":[{}]}' > "${zabbix_temp}"
    [[ -e "${zabbix_lock}" ]] && rm -rf "${zabbix_lock}"
    exit 0
}

case $2 in
    dp)         dp_discovery ;;
    dg)         dg_discovery ;;
    vd)         vd_discovery ;;
    pd)         pd_discovery ;;
    sfp)        counter_discovery "SFP_NAME"     "SFPs Detected:"                     3 ;;
    ether)      counter_discovery "ETHER_NAME"   "Ethernet port:"                     0 ; \
                # override: count lines not a field
                total_ether=$(cat "${conf_file}" | grep "Ethernet port:" | wc -l)
                counter_discovery "ETHER_NAME" "Ethernet port:" 0 ;;
    sas)        counter_discovery "SAS_NAME"     "Physical Disk interface:"           0 ;;
    fc)         counter_discovery "FC_NAME"      "Host interface:"                    0 ;;
    battery)    counter_discovery "BATTERY_NAME" "Batteries Detected:"                3 ;;
    sensor)     counter_discovery "SENSOR_NAME"  "Temperature Sensors Detected:"      4 ;;
    fan)        counter_discovery "FAN_NAME"     "Fans Detected:"                     3 ;;
    psu)        counter_discovery "PSU_NAME"     "Power Supplies Detected:"           4 ;;
    psf)        counter_discovery "PSF_NAME"     "Power Supply/Cooling Fan Modules Detected:" 6 ;;
    controller) indexed_discovery "CONTROLLER_NAME" "RAID Controller Modules:"        4 ;;
    enclosure)  indexed_discovery "ENCLOSURE_NAME"  "Enclosures:"                     2 ;;
    drawer)     drawer_discovery ;;
    *)          unknown_discovery ;;
esac

cat "${zabbix_temp}"
[[ -e "${zabbix_lock}" ]] && rm -rf "${zabbix_lock}"
exit 0
