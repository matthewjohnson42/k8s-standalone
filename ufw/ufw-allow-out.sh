#! /bin/bash

# note: requires root user permissions
# usage: as root (IE using sudo), `sh ufw-allow-out.sh`

echo
echo "[INFO] allowing outbound http"
echo

ufw delete deny out to any from any
