#!/bin/bash
# SSH hardening: disable password auth and root login, enforce key-only access.
# Make sure your SSH key is already in ~/.ssh/authorized_keys before running.

set -e

SSHD=/etc/ssh/sshd_config

cp "$SSHD" "${SSHD}.bak"

sed -i 's/^#*PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD"
sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' "$SSHD"
sed -i 's/^#*PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD"
sed -i 's/^#*AuthorizedKeysFile.*/AuthorizedKeysFile .ssh\/authorized_keys/' "$SSHD"

echo "=== Applied settings ==="
grep -E "^(PasswordAuthentication|PermitRootLogin|PubkeyAuthentication)" "$SSHD"

sshd -t && echo "Config OK" && systemctl reload ssh
echo "SSH hardening done."
