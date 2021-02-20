#! /bin/bash

# note: requires root user permissions
# usage: as root (IE using sudo), `sh ufw-init.sh`

# setup firewall
ufw --force enable
ufw deny out to any from any
ufw allow in to any port 22 from any
# ufw allow in to any port 53 from any # todo: confirm validity of removal, delete line after confirmed
ufw allow in to any port 80 from any
ufw allow in to any port 443 from any
ufw deny in to any from any
