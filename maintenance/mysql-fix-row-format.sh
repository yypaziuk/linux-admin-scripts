#!/bin/bash
# Convert all tables in a MySQL/MariaDB database to ROW_FORMAT=DYNAMIC.
# Required for Nextcloud compatibility with strict MySQL/MariaDB mode.
# Usage: set DB_NAME, DB_USER, DB_PASS below, then run as root or sudo.

DB_NAME="nextcloud"   # target database name
DB_USER="root"        # MySQL user with ALTER TABLE privileges
DB_PASS=""            # MySQL password (leave empty to use ~/.my.cnf)

tables=$(mysql -u"$DB_USER" -p"$DB_PASS" -e "USE $DB_NAME; SHOW TABLES;" 2>/dev/null | grep -v "Tables_in")

if [ -z "$tables" ]; then
    echo "[ERROR] No tables found in '$DB_NAME'. Check credentials and database name."
    exit 1
fi

for table in $tables; do
    echo "Altering $table ..."
    mysql -u"$DB_USER" -p"$DB_PASS" -e "ALTER TABLE $DB_NAME.$table ROW_FORMAT=DYNAMIC;"
done

echo "[SUCCESS] All tables in '$DB_NAME' updated to ROW_FORMAT=DYNAMIC."
