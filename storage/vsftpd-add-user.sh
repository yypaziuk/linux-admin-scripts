#!/bin/bash
# Add a virtual user to vsftpd with an auto-generated password.
# Usage: ./vsftpd-add-user.sh <username>

set -e

USERS_TXT=/etc/vsftpd/virtual_users.txt
USERS_DB=/etc/vsftpd/virtual_users.db
FTP_ROOT=/srv/ftp       # adjust to your vsftpd chroot/user_sub_token root

if [ -z "$1" ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

USER="$1"

if grep -qx "$USER" "$USERS_TXT" 2>/dev/null; then
    echo "User '$USER' already exists in $USERS_TXT"
    exit 1
fi

PASS=$(openssl rand -base64 18)

printf '%s\n%s\n' "$USER" "$PASS" >> "$USERS_TXT"

db_load -T -t hash -f "$USERS_TXT" "$USERS_DB"
chmod 600 "$USERS_TXT" "$USERS_DB"

mkdir -p "$FTP_ROOT/$USER"
chown vftp:vftp "$FTP_ROOT/$USER"

echo "=============================="
echo "User created (no vsftpd restart needed)"
echo "  Login:    $USER"
echo "  Password: $PASS"
echo "=============================="
