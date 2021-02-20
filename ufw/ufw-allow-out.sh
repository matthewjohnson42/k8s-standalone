#! /bin/bash

# note: requires root user permissions
# usage: as root (IE using sudo), `sh ufw-allow-out.sh`

ufw delete deny out to any from any
