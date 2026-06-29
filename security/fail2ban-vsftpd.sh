#!/bin/bash
# fail2ban jail for vsftpd: bans IPs after repeated failed FTP login attempts.
# Adjust PASSIVE_START/END to match your vsftpd passive port range.

set -e

PASSIVE_START=40000
PASSIVE_END=40100

apt-get install -y fail2ban

cat > /etc/fail2ban/jail.d/vsftpd.local << EOF
[vsftpd]
enabled  = true
port     = ftp,ftp-data,${PASSIVE_START}:${PASSIVE_END}
filter   = vsftpd
logpath  = /var/log/vsftpd.log
maxretry = 5
bantime  = 1h
findtime = 10m
EOF

systemctl enable fail2ban
systemctl restart fail2ban
sleep 2
fail2ban-client status vsftpd
