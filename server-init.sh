#! /bin/bash
# todo: remove -x from scripts when scripts validated
# todo: split out server init and app deploys
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
echo "[INFO]   app build and deploy"
echo

echo
echo "[INFO] starting configuration of disks"
# set up disk using AWS UI and parted
echo
echo "Please consider adding firewall rules for the instance via the AWS UI."
read -p "Add disk to instance via AWS UI and enter disk name: " DISK_NAME
partition1=$(ls /dev/ | grep ${DISK_NAME} | sort | tail -n 2 | head -n 1 | grep '1$')
partition2=$(ls /dev/ | grep ${DISK_NAME} | sort | tail -n 1 | grep '2$')
if [[ ! "${partition1}" ]] && [[ ! "${partition2}" ]]; then
  echo "partitions not found, creating"
  read -p "Please enter starting memory offset for partition 1 holding mongo (1MB assuming 8 GB disk): " PART1_START
  read -p "Please enter ending memory offset for partition 1 holding mongo (4097MB assuming 8 GB disk): " PART1_END
  read -p "Please enter starting memory offset for partition 1 holding elasticsearch (4098MB assuming 8 GB disk): " PART2_START
  read -p "Please enter ending memory offset for partition 1 holding elasticsearch (8195MB assuming 8 GB disk): " PART2_END
  parted /dev/${DISK_NAME} mklabel gpt
  parted /dev/${DISK_NAME} mkpart data ext4 ${PART1_START} ${PART1_END}
  parted /dev/${DISK_NAME} mkpart data ext4 ${PART2_START} ${PART2_END}
  if [[ ${partition1} ]]; then
    mkfs.ext4 ${partition1}
  else
    echo "Did not find partition 1 in expected location"
    echo "List of partitions for disk ${DISK_NAME}"
    echo "$(ls -la /dev | grep ${DISK_NAME})"
    exit 1
  fi
  if [[ ${partition2} ]]; then
    mkfs.ext4 ${partition2}
  else
    echo "Did not find partition 2 in expected location"
    echo "List of partitions for disk ${DISK_NAME}"
    echo "$(ls -la /dev | grep ${DISK_NAME})"
    exit 1
  fi
fi

echo "[INFO] creating mount points and performing mount"
mkdir /data
mkdir /data/db
mkdir /data/es
mount /dev/${partition1} /data/db
mount /dev/${partition2} /data/es
chmod -R a+rw /data
chown -R root:root /data
echo "[INFO] disk configuration complete"
echo

echo
echo "[INFO] beginning setup of dev toolchain"
echo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
apt-get update
# docker 19.0.13 depends on containerd 1.3.7, consistent with microk8s 1.20
apt-get install -y npm maven mongodb-clients docker-ce=5:19.03.13~3-0~ubuntu-focal
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
echo "[INFO] starting setup of Kubernetes"
echo
cd ${USER_HOME}/Workspace/personal-memex-server
sh kubernetes/kubernetes-init.sh ${USER_NAME} ${USER_HOME}
echo
echo "[INFO] Kubernetes setup complete"
echo

echo
echo "[INFO] starting deploy of application"
echo
cd ${USER_HOME}/Workspace/personal-memex-server
sh build-and-deploy.sh ${USER_HOME}
echo
echo "[INFO] deploy of application complete"
echo
