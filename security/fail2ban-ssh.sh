#!/bin/bash
# fail2ban jail for SSH: bans IPs after repeated failed login attempts.

set -e

apt-get install -y fail2ban

cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime  = 1h
findtime = 10m
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
port     = ssh
logpath  = %(sshd_log)s
maxretry = 3
bantime  = 2h
EOF

systemctl enable fail2ban
systemctl restart fail2ban
sleep 2
fail2ban-client status sshd
