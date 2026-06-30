#!/bin/bash
# Dell MD Storage: read full status and capacity data for Zabbix.
# Arg 1: IP address of storage controller.
# Returns XML with storage info, disk pools, disk groups, virtual/physical disks,
# SFPs, Ethernet ports, SAS/FC interfaces, batteries, sensors, fans, PSUs,
# RAID controllers, and enclosures.
# Run zabbix-dell-md-runner.sh first to populate the data file.
# All errors/warnings are logged to syslog (grep zabbix-script).

if [[ -z "$1" ]]; then
    logger -t zabbix-script -p local0.info "$0: missing input argument (controller IP)"
    exit 0
fi

IFS=$'\n'
zabbix_temp="/tmp/temp.zabbix-dell-md_get_$1"
zabbix_lock="/tmp/lock.zabbix-dell-md_get_$1"
conf_file="/tmp/storageArray_$1"
smcli_lock="/tmp/lock.smcli_$1"

if [[ -e "${smcli_lock}" ]]; then
    logger -t zabbix-script -p local0.info "SMcli is already running, sending cached data"
    if [[ -e "${zabbix_temp}" ]]; then cat "${zabbix_temp}" | tr -d '\n '; else echo "<data></data>"; fi
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
    echo "<data></data>" > "${zabbix_temp}"
    exit 0
fi

echo "<data>" > "${zabbix_temp}"

#### Storage general information
echo "<storage>" >> "${zabbix_temp}"
echo "<serial>" >> "${zabbix_temp}"
serial_check=$(cat "${conf_file}" | grep "Service tag:" | wc -l)
if [[ ${serial_check} -eq 1 ]]; then
    cat "${conf_file}" | grep "Service tag:" | awk '{ print $3 }' >> "${zabbix_temp}"
else
    serial_check=$(cat "${conf_file}" | grep "Chassis Serial Number:" | wc -l)
    if [[ ${serial_check} -eq 1 ]]; then
        cat "${conf_file}" | grep "Chassis Serial Number:" | awk '{ print $5 }' >> "${zabbix_temp}"
    else
        echo "was not detected" >> "${zabbix_temp}"
    fi
fi
echo "</serial>" >> "${zabbix_temp}"
echo "<name>" >> "${zabbix_temp}"
cat "${conf_file}" | grep "Storage Array Name:" | awk '{ print $4 }' >> "${zabbix_temp}"
echo "</name>" >> "${zabbix_temp}"
echo "<firmware>" >> "${zabbix_temp}"
cat "${conf_file}" | grep "Current Package Version:" | head -n 1 | awk '{ print $4 }' >> "${zabbix_temp}"
echo "</firmware>" >> "${zabbix_temp}"
echo "<hardware>" >> "${zabbix_temp}"
cat "${conf_file}" | grep "Current NVSRAM Version:" | head -n 1 | awk '{ print $4 }' >> "${zabbix_temp}"
echo "</hardware>" >> "${zabbix_temp}"
echo "<wwn>" >> "${zabbix_temp}"
cat "${conf_file}" | grep "Storage array world-wide identifier (ID):" | awk '{ print $6 }' >> "${zabbix_temp}"
echo "</wwn>" >> "${zabbix_temp}"
echo "</storage>" >> "${zabbix_temp}"

# Helper: convert capacity value+unit to KB
capacity_to_kb () {
    local val="$1" unit="$2"
    val=$(echo "${val}" | sed 's/\.//' | sed 's/,//')
    case "${unit}" in
        TB) echo $(( 1073741824 * val )) ;;
        GB) echo $(( 1048576 * val )) ;;
        MB) echo $(( 1024 * val )) ;;
        KB) echo $(( 1 * val )) ;;
        *)  echo $(( val / 1024 )) ;;
    esac
}

#### Disk Pools
total_dp=$(cat "${conf_file}" | grep "Total Disk Pools:" | awk '{ print $4 }')
grep_dp="Name *Status *Usable Capacity *Used Capacity *Free Capacity *Preservation Capacity *Physical Disk/Media Type *Virtual Disks *Secure Capable"
if [[ ${total_dp} -gt 0 ]]; then
    while [[ ${total_dp} -ge 1 ]]; do
        echo "<disk_pool>" >> "${zabbix_temp}"
        echo "<name>"   >> "${zabbix_temp}"
        cat "${conf_file}" | grep -A ${total_dp} "${grep_dp}" | tail -n 1 | awk '{ print $1 }' >> "${zabbix_temp}"
        echo "</name>"  >> "${zabbix_temp}"
        echo "<status>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep -A ${total_dp} "${grep_dp}" | tail -n 1 | awk '{ print $2 }' >> "${zabbix_temp}"
        echo "</status>" >> "${zabbix_temp}"
        total_val=$(cat "${conf_file}" | grep -A ${total_dp} "${grep_dp}" | tail -n 1 | awk '{ print $3 }')
        total_idx=$(cat "${conf_file}" | grep -A ${total_dp} "${grep_dp}" | tail -n 1 | awk '{ print $4 }')
        used_val=$(cat "${conf_file}" | grep -A ${total_dp} "${grep_dp}" | tail -n 1 | awk '{ print $5 }')
        used_idx=$(cat "${conf_file}" | grep -A ${total_dp} "${grep_dp}" | tail -n 1 | awk '{ print $6 }')
        total=$(capacity_to_kb "${total_val}" "${total_idx}")
        used=$(capacity_to_kb "${used_val}" "${used_idx}")
        echo "<total>$(echo ${total})</total>" >> "${zabbix_temp}"
        echo "<used>$(echo ${used})</used>"    >> "${zabbix_temp}"
        [[ ${total} -gt 0 ]] && echo "<util>$(( 100 * used / total ))</util>" >> "${zabbix_temp}" || echo "<util>0</util>" >> "${zabbix_temp}"
        echo "</disk_pool>" >> "${zabbix_temp}"
        total_dp=$(expr ${total_dp} - 1)
    done
else
    echo "<disk_pool></disk_pool>" >> "${zabbix_temp}"
fi

#### Disk Groups
total_dg=$(cat "${conf_file}" | grep "Total Disk Groups:" | awk '{ print $4 }')
grep_dg="Name *Status *Usable Capacity *Used Capacity *Free Capacity *RAID Level *Physical Disk/Media Type *Virtual Disks *Secure Capable"
if [[ ${total_dg} -gt 0 ]]; then
    while [[ ${total_dg} -ge 1 ]]; do
        echo "<disk_group>" >> "${zabbix_temp}"
        echo "<name>"   >> "${zabbix_temp}"
        cat "${conf_file}" | grep -A ${total_dg} "${grep_dg}" | tail -n 1 | awk '{ print $1 }' >> "${zabbix_temp}"
        echo "</name>"  >> "${zabbix_temp}"
        echo "<status>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep -A ${total_dg} "${grep_dg}" | tail -n 1 | awk '{ print $2 }' >> "${zabbix_temp}"
        echo "</status>" >> "${zabbix_temp}"
        echo "<raid>"   >> "${zabbix_temp}"
        cat "${conf_file}" | grep -A ${total_dg} "${grep_dg}" | tail -n 1 | awk '{ print $9 }' >> "${zabbix_temp}"
        echo "</raid>"  >> "${zabbix_temp}"
        total_val=$(cat "${conf_file}" | grep -A ${total_dg} "${grep_dg}" | tail -n 1 | awk '{ print $3 }')
        total_idx=$(cat "${conf_file}" | grep -A ${total_dg} "${grep_dg}" | tail -n 1 | awk '{ print $4 }')
        used_val=$(cat "${conf_file}" | grep -A ${total_dg} "${grep_dg}" | tail -n 1 | awk '{ print $5 }')
        used_idx=$(cat "${conf_file}" | grep -A ${total_dg} "${grep_dg}" | tail -n 1 | awk '{ print $6 }')
        total=$(capacity_to_kb "${total_val}" "${total_idx}")
        used=$(capacity_to_kb "${used_val}" "${used_idx}")
        echo "<total>$(echo ${total})</total>" >> "${zabbix_temp}"
        echo "<used>$(echo ${used})</used>"    >> "${zabbix_temp}"
        [[ ${total} -gt 0 ]] && echo "<util>$(( 100 * used / total ))</util>" >> "${zabbix_temp}" || echo "<util>0</util>" >> "${zabbix_temp}"
        echo "</disk_group>" >> "${zabbix_temp}"
        total_dg=$(expr ${total_dg} - 1)
    done
else
    echo "<disk_group></disk_group>" >> "${zabbix_temp}"
fi

#### Virtual Disks
total_vd=$(cat "${conf_file}" | grep "Number of standard virtual disks:" | awk '{ print $6 }')
if [[ ${total_vd} -gt 0 ]]; then
    check_grep_vd=$(cat "${conf_file}" | grep "Name *Thin Provisioned *Status *Capacity *Accessible by *Source" | wc -l)
    if [[ ${check_grep_vd} -eq 1 ]]; then
        grep_vd="Name *Thin Provisioned *Status *Capacity *Accessible by *Source"
        status_col=3; cap_col=4; cap_idx_col=5
    else
        check_grep_vd=$(cat "${conf_file}" | grep "Name *Thin Provisioned *SSD Cache *Status *Capacity *Accessible by *Source" | wc -l)
        [[ ${check_grep_vd} -eq 1 ]] && grep_vd="Name *Thin Provisioned *SSD Cache *Status *Capacity *Accessible by *Source" && status_col=4 && cap_col=5 && cap_idx_col=6
    fi
    if [[ ${check_grep_vd} -eq 1 ]]; then
        while [[ ${total_vd} -ge 1 ]]; do
            echo "<virtual_disk>" >> "${zabbix_temp}"
            echo "<name>"   >> "${zabbix_temp}"
            cat "${conf_file}" | grep -A ${total_vd} "${grep_vd}" | tail -n 1 | awk '{ print $1 }' >> "${zabbix_temp}"
            echo "</name>"  >> "${zabbix_temp}"
            echo "<status>" >> "${zabbix_temp}"
            cat "${conf_file}" | grep -A ${total_vd} "${grep_vd}" | tail -n 1 | awk "{ print \$${status_col} }" >> "${zabbix_temp}"
            echo "</status>" >> "${zabbix_temp}"
            total_val=$(cat "${conf_file}" | grep -A ${total_vd} "${grep_vd}" | tail -n 1 | awk "{ print \$${cap_col} }")
            total_idx=$(cat "${conf_file}" | grep -A ${total_vd} "${grep_vd}" | tail -n 1 | awk "{ print \$${cap_idx_col} }")
            echo "<total>$(capacity_to_kb "${total_val}" "${total_idx}")</total>" >> "${zabbix_temp}"
            echo "</virtual_disk>" >> "${zabbix_temp}"
            total_vd=$(expr ${total_vd} - 1)
        done
    fi
else
    echo "<virtual_disk></virtual_disk>" >> "${zabbix_temp}"
fi

#### Physical Disks
total_pd=$(cat "${conf_file}" | grep "Number of physical disks:" | awk '{ print $5 }')
if [[ ${total_pd} -gt 0 ]]; then
    check_grep_pd=$(cat "${conf_file}" | grep "ENCLOSURE, *SLOT *STATUS *CAPACITY *MEDIA TYPE *INTERFACE TYPE *CURRENT DATA RATE *PRODUCT ID *FIRMWARE VERSION *CAPABILITIES" | wc -l)
    if [[ ${check_grep_pd} -eq 1 ]]; then
        grep_pd="ENCLOSURE, *SLOT *STATUS *CAPACITY *MEDIA TYPE *INTERFACE TYPE *CURRENT DATA RATE *PRODUCT ID *FIRMWARE VERSION *CAPABILITIES"
        while [[ ${total_pd} -ge 1 ]]; do
            echo "<physical_disk>" >> "${zabbix_temp}"
            line=$(cat "${conf_file}" | grep -A ${total_pd} "${grep_pd}" | tail -n 1)
            echo "<name>$(echo ${line} | awk '{ print $2 }')</name>"             >> "${zabbix_temp}"
            echo "<location>$(echo ${line} | awk '{ print $1$2 }')</location>"   >> "${zabbix_temp}"
            echo "<status>$(echo ${line} | awk '{ print $3 }')</status>"         >> "${zabbix_temp}"
            total_val=$(echo ${line} | awk '{ print $4 }'); total_idx=$(echo ${line} | awk '{ print $5 }')
            echo "<total>$(capacity_to_kb "${total_val}" "${total_idx}")</total>" >> "${zabbix_temp}"
            echo "<type>$(echo ${line} | awk '{ print $6" "$7 }')</type>"        >> "${zabbix_temp}"
            echo "<interface>$(echo ${line} | awk '{ print $8 }')</interface>"   >> "${zabbix_temp}"
            echo "<data_rate>$(echo ${line} | awk '{ print $9" "$10 }')</data_rate>" >> "${zabbix_temp}"
            echo "<model>$(echo ${line} | awk '{ print $11 }')</model>"          >> "${zabbix_temp}"
            echo "<firmware>$(echo ${line} | awk '{ print $12 }')</firmware>"    >> "${zabbix_temp}"
            echo "</physical_disk>" >> "${zabbix_temp}"
            total_pd=$(expr ${total_pd} - 1)
        done
    else
        check_grep_pd=$(cat "${conf_file}" | grep "ENCLOSURE, *DRAWER, *SLOT *STATUS *CAPACITY *MEDIA TYPE *INTERFACE TYPE *CURRENT DATA RATE *PRODUCT ID *FIRMWARE VERSION *CAPABILITIES" | wc -l)
        if [[ ${check_grep_pd} -eq 1 ]]; then
            grep_pd="ENCLOSURE, *DRAWER, *SLOT *STATUS *CAPACITY *MEDIA TYPE *INTERFACE TYPE *CURRENT DATA RATE *PRODUCT ID *FIRMWARE VERSION *CAPABILITIES"
            while [[ ${total_pd} -ge 1 ]]; do
                echo "<physical_disk>" >> "${zabbix_temp}"
                line=$(cat "${conf_file}" | grep -A ${total_pd} "${grep_pd}" | tail -n 1)
                pd_name=$(echo ${line} | awk '{ print $1$2$3 }' | tr ',' '-')
                echo "<name>${pd_name}</name>"                                            >> "${zabbix_temp}"
                echo "<location>$(echo ${line} | awk '{ print $1$2$3 }')</location>"     >> "${zabbix_temp}"
                echo "<status>$(echo ${line} | awk '{ print $4 }')</status>"             >> "${zabbix_temp}"
                total_val=$(echo ${line} | awk '{ print $5 }'); total_idx=$(echo ${line} | awk '{ print $6 }')
                echo "<total>$(capacity_to_kb "${total_val}" "${total_idx}")</total>"     >> "${zabbix_temp}"
                echo "<type>$(echo ${line} | awk '{ print $7" "$8 }')</type>"            >> "${zabbix_temp}"
                echo "<interface>$(echo ${line} | awk '{ print $9 }')</interface>"       >> "${zabbix_temp}"
                echo "<data_rate>$(echo ${line} | awk '{ print $10" "$11 }')</data_rate>" >> "${zabbix_temp}"
                echo "<model>$(echo ${line} | awk '{ print $12 }')</model>"              >> "${zabbix_temp}"
                echo "<firmware>$(echo ${line} | awk '{ print $13 }')</firmware>"        >> "${zabbix_temp}"
                echo "</physical_disk>" >> "${zabbix_temp}"
                total_pd=$(expr ${total_pd} - 1)
            done
        fi
    fi
else
    echo "<physical_disk></physical_disk>" >> "${zabbix_temp}"
fi

#### SFP modules
total_sfp=$(cat "${conf_file}" | grep "SFPs Detected:" | awk '{ print $3 }')
if [[ ${total_sfp} -gt 0 ]]; then
    while [[ ${total_sfp} -ge 1 ]]; do
        echo "<sfp>" >> "${zabbix_temp}"
        echo "<name>${total_sfp}</name>" >> "${zabbix_temp}"
        echo "<location>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep -A 14 "SFP status:" | grep "Location:" | awk '{ print $2" "$3" "$4" "$5" "$6 }' | tail -n ${total_sfp} | head -n 1 >> "${zabbix_temp}"
        echo "</location>" >> "${zabbix_temp}"
        echo "<status>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep "SFP status:" | awk '{ print $3" "$4" "$5 }' | tail -n ${total_sfp} | head -n 1 >> "${zabbix_temp}"
        echo "</status>" >> "${zabbix_temp}"
        echo "</sfp>" >> "${zabbix_temp}"
        total_sfp=$(expr ${total_sfp} - 1)
    done
else
    echo "<sfp></sfp>" >> "${zabbix_temp}"
fi

#### Ethernet ports
total_ether=$(cat "${conf_file}" | grep "Ethernet port:" | wc -l)
if [[ ${total_ether} -gt 0 ]]; then
    while [[ ${total_ether} -ge 1 ]]; do
        echo "<ether>" >> "${zabbix_temp}"
        echo "<name>${total_ether}</name>" >> "${zabbix_temp}"
        echo "<status>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep -A 2 "Ethernet port:" | grep "Link status:" | awk '{ print $3 }' | tail -n ${total_ether} | head -n 1 >> "${zabbix_temp}"
        echo "</status>" >> "${zabbix_temp}"
        echo "</ether>" >> "${zabbix_temp}"
        total_ether=$(expr ${total_ether} - 1)
    done
else
    echo "<ether></ether>" >> "${zabbix_temp}"
fi

#### SAS (Physical Disk interface)
total_sas=$(cat "${conf_file}" | grep "Physical Disk interface:" | wc -l)
if [[ ${total_sas} -gt 0 ]]; then
    while [[ ${total_sas} -ge 1 ]]; do
        echo "<sas>" >> "${zabbix_temp}"
        echo "<name>${total_sas}</name>" >> "${zabbix_temp}"
        echo "<status>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep -A 5 "Physical Disk interface:" | grep "Status:" | awk '{ print $2 }' | tail -n ${total_sas} | head -n 1 >> "${zabbix_temp}"
        echo "</status>" >> "${zabbix_temp}"
        echo "</sas>" >> "${zabbix_temp}"
        total_sas=$(expr ${total_sas} - 1)
    done
else
    echo "<sas></sas>" >> "${zabbix_temp}"
fi

#### FC (Host interface)
total_fc=$(cat "${conf_file}" | grep "Host interface:" | wc -l)
if [[ ${total_fc} -gt 0 ]]; then
    while [[ ${total_fc} -ge 1 ]]; do
        echo "<fc>" >> "${zabbix_temp}"
        echo "<name>${total_fc}</name>" >> "${zabbix_temp}"
        echo "<status>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep -A 15 "Host interface:" | grep "Link status:" | awk '{ print $3 }' | tail -n ${total_fc} | head -n 1 >> "${zabbix_temp}"
        echo "</status>" >> "${zabbix_temp}"
        echo "</fc>" >> "${zabbix_temp}"
        total_fc=$(expr ${total_fc} - 1)
    done
else
    echo "<fc></fc>" >> "${zabbix_temp}"
fi

#### Batteries
total_bat=$(cat "${conf_file}" | grep "Batteries Detected:" | awk '{ print $3 }')
if [[ ${total_bat} -gt 0 ]]; then
    while [[ ${total_bat} -ge 1 ]]; do
        echo "<battery>" >> "${zabbix_temp}"
        echo "<name>${total_bat}</name>" >> "${zabbix_temp}"
        echo "<status>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep "Battery status:" | awk '{ print $3" "$4" "$5 }' | tail -n ${total_bat} | head -n 1 >> "${zabbix_temp}"
        echo "</status>" >> "${zabbix_temp}"
        echo "<location>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep -A 2 "Battery status:" | grep "Location:" | awk '{ print $2" "$3" "$4" "$5" "$6 }' | tail -n ${total_bat} | head -n 1 >> "${zabbix_temp}"
        echo "</location>" >> "${zabbix_temp}"
        echo "</battery>" >> "${zabbix_temp}"
        total_bat=$(expr ${total_bat} - 1)
    done
else
    echo "<battery></battery>" >> "${zabbix_temp}"
fi

#### Temperature Sensors
total_sens=$(cat "${conf_file}" | grep "Temperature Sensors Detected:" | awk '{ print $4 }')
if [[ ${total_sens} -gt 0 ]]; then
    while [[ ${total_sens} -ge 1 ]]; do
        echo "<sensor>" >> "${zabbix_temp}"
        echo "<name>${total_sens}</name>" >> "${zabbix_temp}"
        echo "<status>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep "Temperature sensor status:" | awk '{ print $4" "$5" "$6 }' | tail -n ${total_sens} | head -n 1 >> "${zabbix_temp}"
        echo "</status>" >> "${zabbix_temp}"
        echo "<location>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep -A 2 "Temperature sensor status:" | grep "Location:" | awk '{ print $2" "$3" "$4" "$5" "$6" "$7 }' | tail -n ${total_sens} | head -n 1 >> "${zabbix_temp}"
        echo "</location>" >> "${zabbix_temp}"
        echo "</sensor>" >> "${zabbix_temp}"
        total_sens=$(expr ${total_sens} - 1)
    done
else
    echo "<sensor></sensor>" >> "${zabbix_temp}"
fi

#### Fans
total_fan=$(cat "${conf_file}" | grep "Fans Detected:" | awk '{ print $3 }')
if [[ ${total_fan} -gt 0 ]]; then
    while [[ ${total_fan} -ge 1 ]]; do
        echo "<fan>" >> "${zabbix_temp}"
        echo "<name>${total_fan}</name>" >> "${zabbix_temp}"
        echo "<status>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep "Fan Status:" | awk '{ print $3" "$4" "$5 }' | tail -n ${total_fan} | head -n 1 >> "${zabbix_temp}"
        echo "</status>" >> "${zabbix_temp}"
        echo "<location>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep -A 2 "Fan Status:" | grep "Location:" | awk '{ print $2" "$3" "$4 }' | tail -n ${total_fan} | head -n 1 >> "${zabbix_temp}"
        echo "</location>" >> "${zabbix_temp}"
        echo "</fan>" >> "${zabbix_temp}"
        total_fan=$(expr ${total_fan} - 1)
    done
else
    echo "<fan></fan>" >> "${zabbix_temp}"
fi

#### Drawers
check_drawer=$(cat "${conf_file}" | grep "Drawers Detected:" | wc -l)
if [[ ${check_drawer} -eq 1 ]]; then
    total_drawer=$(cat "${conf_file}" | grep "Drawers Detected:" | awk '{ print $3 }')
    item_drawer=0
    if [[ ${total_drawer} -gt 0 ]]; then
        while [[ ${total_drawer} -ge 1 ]]; do
            echo "<drawer>" >> "${zabbix_temp}"
            echo "<name>${item_drawer}</name>" >> "${zabbix_temp}"
            total_drawer=$(expr ${total_drawer} - 1)
            item_drawer=$(expr ${item_drawer} + 1)
            echo "<status>" >> "${zabbix_temp}"
            cat "${conf_file}" | grep "Drawer status:" | awk '{ print $3 }' | head -n ${item_drawer} | tail -n 1 >> "${zabbix_temp}"
            echo "</status>" >> "${zabbix_temp}"
            echo "<serial>" >> "${zabbix_temp}"
            cat "${conf_file}" | grep -A 4 "Drawer status:" | grep "Serial number:" | awk '{ print $4 }' | head -n ${item_drawer} | tail -n 1 >> "${zabbix_temp}"
            echo "</serial>" >> "${zabbix_temp}"
            echo "</drawer>" >> "${zabbix_temp}"
        done
    else
        echo "<drawer></drawer>" >> "${zabbix_temp}"
    fi
else
    echo "<drawer></drawer>" >> "${zabbix_temp}"
fi

#### Power Supplies
total_psu=$(cat "${conf_file}" | grep "Power Supplies Detected:" | awk '{ print $4 }')
if [[ ${total_psu} -gt 0 ]]; then
    while [[ ${total_psu} -ge 1 ]]; do
        echo "<psu>" >> "${zabbix_temp}"
        echo "<name>${total_psu}</name>" >> "${zabbix_temp}"
        echo "<status>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep "Power supply status:" | awk '{ print $4" "$5" "$6 }' | tail -n ${total_psu} | head -n 1 >> "${zabbix_temp}"
        echo "</status>" >> "${zabbix_temp}"
        echo "<location>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep -A 2 "Power supply status:" | grep "Location:" | awk '{ print $2" "$3" "$4 }' | tail -n ${total_psu} | head -n 1 >> "${zabbix_temp}"
        echo "</location>" >> "${zabbix_temp}"
        echo "</psu>" >> "${zabbix_temp}"
        total_psu=$(expr ${total_psu} - 1)
    done
else
    echo "<psu></psu>" >> "${zabbix_temp}"
fi

#### Power Supply/Cooling Fan Modules
total_psf=$(cat "${conf_file}" | grep "Power Supply/Cooling Fan Modules Detected:" | awk '{ print $6 }')
if [[ ${total_psf} -gt 0 ]]; then
    while [[ ${total_psf} -ge 1 ]]; do
        echo "<psf>" >> "${zabbix_temp}"
        echo "<name>${total_psf}</name>" >> "${zabbix_temp}"
        echo "<status>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep "Power Supply/Cooling Fan module" | awk '{ print $7" "$8" "$9 }' | tail -n ${total_psf} | head -n 1 >> "${zabbix_temp}"
        echo "</status>" >> "${zabbix_temp}"
        echo "</psf>" >> "${zabbix_temp}"
        total_psf=$(expr ${total_psf} - 1)
    done
else
    echo "<psf></psf>" >> "${zabbix_temp}"
fi

#### RAID Controller Modules
total_con=$(cat "${conf_file}" | grep "RAID Controller Modules:" | awk '{ print $4 }')
if [[ ${total_con} -gt 0 ]]; then
    while [[ ${total_con} -ge 1 ]]; do
        con_name=$(expr ${total_con} - 1)
        echo "<controller>" >> "${zabbix_temp}"
        echo "<name>${con_name}</name>" >> "${zabbix_temp}"
        echo "<status>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep -A 5 "RAID Controller Module in Enclosure" | grep "Status:" | awk '{ print $2" "$3" "$4 }' | tail -n ${total_con} | head -n 1 >> "${zabbix_temp}"
        echo "</status>" >> "${zabbix_temp}"
        echo "<location>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep -A 12 "RAID Controller Modules" | grep "Location:" | awk '{ print $2" "$3" "$4" "$5" "$6 }' | tail -n ${total_con} | head -n 1 >> "${zabbix_temp}"
        echo "</location>" >> "${zabbix_temp}"
        echo "</controller>" >> "${zabbix_temp}"
        total_con=$(expr ${total_con} - 1)
    done
else
    echo "<controller></controller>" >> "${zabbix_temp}"
fi

#### Enclosures
total_enc=$(cat "${conf_file}" | grep "Enclosures:" | awk '{ print $2 }')
if [[ ${total_enc} -gt 0 ]]; then
    while [[ ${total_enc} -ge 1 ]]; do
        enc_name=$(expr ${total_enc} - 1)
        echo "<enclosure>" >> "${zabbix_temp}"
        echo "<name>${enc_name}</name>" >> "${zabbix_temp}"
        echo "<status>" >> "${zabbix_temp}"
        cat "${conf_file}" | grep "Enclosure path consistency:" | awk '{ print $4" "$5" "$6 }' | tail -n ${total_enc} | head -n 1 >> "${zabbix_temp}"
        echo "</status>" >> "${zabbix_temp}"
        echo "</enclosure>" >> "${zabbix_temp}"
        total_enc=$(expr ${total_enc} - 1)
    done
else
    echo "<enclosure></enclosure>" >> "${zabbix_temp}"
fi

echo "</data>" >> "${zabbix_temp}"
cat "${zabbix_temp}" | tr -d '\n '
[[ -e "${zabbix_lock}" ]] && rm -rf "${zabbix_lock}"
exit 0
