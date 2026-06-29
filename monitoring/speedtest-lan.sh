#!/usr/bin/env bash
# LAN speedtest using iperf3. Configurable target list, lock-file guard, CLI flags.
# Usage:
#   ./speedtest-lan.sh -a          run all configured targets
#   ./speedtest-lan.sh -l <ip>     run single target
#   ./speedtest-lan.sh -g          list configured targets (JSON, for Zabbix LLD)
#   ./speedtest-lan.sh -c [-l ip]  show cached result
#   ./speedtest-lan.sh -d/-u/-p    show download/upload/ping from cache
#   ./speedtest-lan.sh -f          force-remove lock and run all

set -e

# ---- Configuration: add iperf3 server(s) here ----
IPERF_NUMBER=1
IPERF_IP[0]="192.168.1.1"          # iperf3 server IP or hostname
IPERF_NAME[0]="Core Switch"         # display name
IPERF_TR_DL[0]="1000"              # expected download threshold Mbit/s
IPERF_TR_UL[0]="1000"              # expected upload threshold Mbit/s
# ---- End of configuration ----

CACHE_FILE=/tmp/speedtest-lan.log
LOCK_FILE=/tmp/speedtest-lan.lock

run_speedtest() {
    local target="$1"
    if [[ -z "$target" ]]; then exit 2; fi

    if [[ -e "$LOCK_FILE" ]]; then
        echo "A speedtest is already running" >&2; exit 2
    fi
    touch "$LOCK_FILE"
    trap "rm -f $LOCK_FILE" EXIT HUP INT QUIT PIPE TERM

    local download upload ping result_file
    download=$(iperf3 -f m -c "$target" -R | grep sender | awk '{print $7}')
    upload=$(iperf3 -f m -c "$target" | grep sender | awk '{print $7}')
    ping=$(ping -c 4 "$target" | tail -1 | awk '{print $4}' | cut -d'/' -f2)
    result_file="${CACHE_FILE}_${target}"

    { echo "Ping: $ping ms"
      echo "Download: $download Mbit/s"
      echo "Upload: $upload Mbit/s"; } > "$result_file"

    rm -f "$LOCK_FILE"
}

show_help() {
    echo "Usage: $0 [-a|--all] [-l ip] [-g|--get-all] [-c|--cached] [-d] [-u] [-p] [-f|--force] [-h]"
}

case "$1" in
    -f|--force)
        rm -f "$LOCK_FILE"
        for ((c=0; c<IPERF_NUMBER; c++)); do run_speedtest "${IPERF_IP[$c]}"; done ;;
    -a|--all)
        for ((c=0; c<IPERF_NUMBER; c++)); do run_speedtest "${IPERF_IP[$c]}"; done ;;
    -g|--get-all)
        echo '{"data":['
        comma=""
        for ((c=0; c<IPERF_NUMBER; c++)); do
            echo "  $comma{\"{#IPERFID}\":\"${IPERF_IP[$c]}\",\"{#IPERFNAME}\":\"${IPERF_NAME[$c]}\",\"{#IPERF_TR_DL}\":\"${IPERF_TR_DL[$c]}\",\"{#IPERF_TR_UL}\":\"${IPERF_TR_UL[$c]}\"}"
            comma=","
        done
        echo ']}' ;;
    -l)
        run_speedtest "$2" ;;
    -c|--cached)
        target="${3:-}"; f="${CACHE_FILE}${target:+_$target}"
        [[ ! -f "$f" ]] && { echo "No cache yet" >&2; exit 2; }; cat "$f" ;;
    -d|--download)
        target="${3:-}"; f="${CACHE_FILE}${target:+_$target}"
        [[ ! -f "$f" ]] && { echo "No cache yet" >&2; exit 2; }
        awk '/Download/ {print $2}' "$f" ;;
    -u|--upload)
        target="${3:-}"; f="${CACHE_FILE}${target:+_$target}"
        [[ ! -f "$f" ]] && { echo "No cache yet" >&2; exit 2; }
        awk '/Upload/ {print $2}' "$f" ;;
    -p|--ping)
        target="${3:-}"; f="${CACHE_FILE}${target:+_$target}"
        [[ ! -f "$f" ]] && { echo "No cache yet" >&2; exit 2; }
        awk '/Ping/ {print $2}' "$f" ;;
    -h|--help|*)
        show_help ;;
esac
