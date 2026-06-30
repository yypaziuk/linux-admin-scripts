#!/bin/bash
# Generate a 2048-bit RSA private key and a CSR for a Zabbix server TLS certificate.
# Edit the variables below to match your organisation and server details.
# Output: zabbix.key (private key) and zabbix.csr (certificate signing request).

COUNTRY="UA"
STATE="Your Region"
LOCALITY="Your City"
ORG="Your Organization"
OU="IT"
EMAIL="admin@example.com"
CN="zabbix.example.com"
SAN_DNS1="zabbix.example.com"
SAN_DNS2=""         # optional second DNS SAN; leave empty to omit
SAN_IP1=""          # optional IP SAN (e.g. "10.0.0.1"); leave empty to omit

CSR_FILE="zabbix.csr"
KEY_FILE="zabbix.key"
CONFIG_FILE="$(mktemp /tmp/openssl_zabbix_XXXXXX.cnf)"

alt_names="[ alt_names ]\nDNS.1 = $SAN_DNS1"
[ -n "$SAN_DNS2" ] && alt_names="$alt_names\nDNS.2 = $SAN_DNS2"
[ -n "$SAN_IP1"  ] && alt_names="$alt_names\nIP.1 = $SAN_IP1"

cat > "$CONFIG_FILE" <<EOF
[req]
default_bits       = 2048
prompt             = no
default_md         = sha256
req_extensions     = req_ext
distinguished_name = dn

[ dn ]
C            = $COUNTRY
ST           = $STATE
L            = $LOCALITY
O            = $ORG
OU           = $OU
emailAddress = $EMAIL
CN           = $CN

[ req_ext ]
subjectAltName = @alt_names

$(printf "$alt_names")
EOF

openssl req -new -sha256 -nodes \
    -out "$CSR_FILE" \
    -newkey rsa:2048 \
    -keyout "$KEY_FILE" \
    -config "$CONFIG_FILE"

rm -f "$CONFIG_FILE"
echo "[SUCCESS] Private key : $KEY_FILE"
echo "[SUCCESS] CSR         : $CSR_FILE"
echo "Submit $CSR_FILE to your CA for signing."
