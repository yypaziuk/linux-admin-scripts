#!/bin/bash
# Rotate FTP storage: delete files older than KEEP_DAYS, remove empty subdirectories.
# Deploy to /usr/local/bin/ftp-rotate.sh and schedule via cron, e.g. daily at 03:30:
#   30 3 * * * /usr/local/bin/ftp-rotate.sh

FTP_ROOT="/srv/ftp"   # root directory of FTP storage
KEEP_DAYS=7           # delete files older than this many days

find "$FTP_ROOT" -type f -mtime +"$KEEP_DAYS" -delete
find "$FTP_ROOT" -mindepth 2 -type d -empty -delete
