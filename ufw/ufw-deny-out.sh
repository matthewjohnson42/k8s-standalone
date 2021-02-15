#! /bin/bash

# note: requires root user permissions
# usage: as root (IE using sudo), `sh ufw-deny-out.sh`

echo
echo "[INFO] disallowing outbound http"
echo

ufw deny out to any from any
