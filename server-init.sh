#! /bin/bash
set -x

# init script for server hosting matthewjohnson42/personal-memex-service and matthewjohnson42/personal-memex-ui

# note: requires root user permissions
# usage: as default user, `sudo sh server-init.sh ${USER} ${HOME}`
# usage: as root (IE, using sudo), `sh build-and-deploy.sh <default-user-home-directory>`

USER_NAME=$1
USER_HOME=$2

echo
echo "[INFO] starting initialization of server"
echo "[INFO] includes:"
echo "[INFO]   disk mounting"
echo "[INFO]   dev tool installation (maven, npm)"
echo "[INFO]   container host installation (docker)"
echo "[INFO]   container orchestration installation (kubernetes)"
echo "[INFO]   firewall configuration (ufw)"
echo "[INFO]   app build and deploy"
echo

echo
echo "[INFO] starting configuration of disks"
# set up disk using AWS UI and parted
read -p "add disk to instance via AWS UI and enter disk name: " DISK_NAME
if [ $(ls /dev | grep "${DISK_NAME}[0-9]" | wc -l | xargs) -eq 0 ]; then
  echo "partitions not found, creating"
  parted /dev/${DISK_NAME} mklabel gpt
  parted /dev/${DISK_NAME} mkpart data ext4 1MB 4097MB
  parted /dev/${DISK_NAME} mkpart data ext4 4098MB 8195MB
  mkfs.ext4 /dev/${DISK_NAME}1
  mkfs.ext4 /dev/${DISK_NAME}2
fi
echo "[INFO] creating mount points and performing mount"
mkdir /data
mkdir /data/db
mkdir /data/es
mount /dev/${DISK_NAME}1 /data/db
mount /dev/${DISK_NAME}2 /data/es
chmod -R a+rw /data
echo "[INFO] disk configuration complete"
echo

echo
echo "[INFO] beginning setup of dev toolchain"
echo
apt-get update
apt-get install -y npm maven
echo
echo "[INFO] dev toolchain setup complete"
echo
echo "[INFO] beginning setup of app sources"
echo
mkdir ${USER_HOME}/Workspace/
cd ${USER_HOME}/Workspace
git clone https://github.com/matthewjohnson42/personal-memex-server.git
git clone https://github.com/matthewjohnson42/personal-memex-ui.git
git clone https://github.com/matthewjohnson42/personal-memex-service.git
echo
echo "[INFO] setup of app sources complete"
echo

cd ${USER_HOME}/Workspace/personal-memex-server
sh kubernetes/kubernetes-init.sh ${USER_NAME} ${USER_HOME}
sh ufw/ufw-init.sh ${USER_HOME}
sh build-and-deploy.sh
