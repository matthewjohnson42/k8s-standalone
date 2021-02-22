#! /bin/bash
# todo: remove -x from scripts when scripts validated
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
apt-get install -y npm maven mongodb-clients docker.io
# set docker daemon to start on boot, restart daemon to load config. note docker configs exist in kubernetes-init.sh
systemctl enable docker
# add user to the docker user group.
# allows access to the docker daemon via docker unix socket, accessed by the `docker` cmd line util.
prevGroups=$(groups ${USER_NAME} | sed 's/^[A-z0-9_-]*\$*\s*:\s*//g')
usermod -g docker ${USER_NAME}
for group in ${prevGroups}; do
  usermod -G ${group} ${USER_NAME}
done
usermod -G docker ${USER}
echo
echo "[INFO] dev toolchain setup complete"
echo
echo "[INFO] beginning setup of app sources"
echo
mkdir ${USER_HOME}/Workspace/
cd ${USER_HOME}/Workspace
git clone https://github.com/matthewjohnson42/personal-memex-server.git
git clone https://github.com/matthewjohnson42/personal-memex-service.git
git clone https://github.com/matthewjohnson42/personal-memex-ui.git
cd ${USER_HOME}/Workspace/personal-memex-ui
npm install ng
echo
echo "[INFO] setup of app sources complete"
echo

echo
echo "[INFO] beginning configuration of firewall"
echo
sh ufw/ufw-init.sh
echo
echo "[INFO] configuration of firewall complete"
echo

echo
echo "[INFO] starting setup of Kubernetes"
echo
cd ${USER_HOME}/Workspace/personal-memex-server
sh kubernetes/kubernetes-init.sh ${USER_HOME}
echo
echo "[INFO] Kubernetes setup complete"
echo

echo
echo "[INFO] starting deploy of application"
echo
cd ${USER_HOME}/Workspace/personal-memex-server
sh build-and-deploy.sh ${USER_NAME} ${USER_HOME}
echo
echo "[INFO] deploy of application complete"
echo
