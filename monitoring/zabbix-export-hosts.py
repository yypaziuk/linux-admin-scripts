#!/usr/bin/env python3
# Export all Zabbix hosts with their IP addresses and tags to an Excel file.
# Configure via environment variables or edit the constants below.
# Requires: pip install requests pandas openpyxl

import os
import requests
import pandas as pd
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

ZABBIX_URL      = os.getenv("ZABBIX_URL",      "https://zabbix.example.com/api_jsonrpc.php")
ZABBIX_USER     = os.getenv("ZABBIX_USER",     "Admin")
ZABBIX_PASSWORD = os.getenv("ZABBIX_PASSWORD", "")
OUTPUT_FILE     = "zabbix_hosts.xlsx"


def zabbix_login():
    payload = {
        "jsonrpc": "2.0", "method": "user.login",
        "params": {"username": ZABBIX_USER, "password": ZABBIX_PASSWORD},
        "id": 1,
    }
    resp = requests.post(ZABBIX_URL, json=payload, verify=False)
    result = resp.json()
    if "result" in result:
        return result["result"]
    raise SystemExit(f"[ERROR] Login failed: {result.get('error')}")


def get_hosts(token):
    payload = {
        "jsonrpc": "2.0", "method": "host.get",
        "params": {
            "output": ["hostid", "host", "name"],
            "selectInterfaces": ["ip"],
            "selectTags": "extend",
        },
        "auth": token, "id": 2,
    }
    return requests.post(ZABBIX_URL, json=payload, verify=False).json()["result"]


def export_to_excel(hosts):
    rows = []
    for host in hosts:
        ips  = ", ".join(i["ip"] for i in host.get("interfaces", [])) or "N/A"
        tags = ", ".join(f"{t['tag']}={t['value']}" for t in host.get("tags", [])) or "N/A"
        rows.append({"Host Name": host["name"], "IP Address": ips, "Tags": tags})
    pd.DataFrame(rows).to_excel(OUTPUT_FILE, index=False)
    print(f"[SUCCESS] {len(rows)} hosts exported to '{OUTPUT_FILE}'.")


def main():
    print(f"[INFO] Connecting to {ZABBIX_URL} as {ZABBIX_USER} ...")
    token = zabbix_login()
    hosts = get_hosts(token)
    export_to_excel(hosts)


if __name__ == "__main__":
    main()
