#!/bin/bash
# UFW rules for an FTPS server (vsftpd with TLS + passive mode).
# Adjust PASSIVE_START/END to match your vsftpd pasv_min_port/pasv_max_port.

set -e

PASSIVE_START=40000
PASSIVE_END=40100

apt-get install -y ufw

ufw allow 22/tcp                                    # SSH
ufw allow 21/tcp                                    # FTP control channel
ufw allow ${PASSIVE_START}:${PASSIVE_END}/tcp       # passive data range

ufw --force enable

echo "=== UFW Status ==="
ufw status verbose
