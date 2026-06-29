#!/bin/bash
# Basic UFW setup: deny all incoming, allow SSH, enable firewall.
# Run as root on a fresh server before doing anything else.

set -e

ufw allow OpenSSH

ufw default deny incoming
ufw default allow outgoing

ufw --force enable

echo "=== UFW Status ==="
ufw status verbose
