#! /bin/bash
# todo: remove -x from scripts when scripts validated
set -x

# init script for a single-node kubernetes cluster

# note: requires root user permissions
# usage: as default user, `sudo sh server-init.sh ${USER} ${HOME}`

USER_NAME=$1
USER_HOME=$2

echo
echo "[INFO] starting initialization of server"
echo "[INFO] includes:"
echo "[INFO]   disk mounting"
echo "[INFO]   dev tool installation (maven, npm)"
echo "[INFO]   clone of repositories to host"
echo "[INFO]   container cli installation (docker for containerd)"
echo "[INFO]   container orchestration installation (kubernetes as microk8s on containerd)"
echo

echo
echo "[INFO] starting configuration of disks"
# set up disk using AWS UI and parted
echo
echo "Please consider adding firewall rules for the instance via the AWS UI."
read -p "Add disk to instance via AWS UI and enter disk name: " DISK_NAME
partition1=$(ls /dev/ | grep ${DISK_NAME} | sort | tail -n 2 | head -n 1 | grep '1$')
partition2=$(ls /dev/ | grep ${DISK_NAME} | sort | tail -n 1 | grep '2$')
if [ -z "${partition1}" ] && [ -z "${partition2}" ]; then
  echo "partitions not found, creating"
  read -p "Please enter starting memory offset for partition 1 holding mongo (1MB assuming 8 GB disk): " PART1_START
  read -p "Please enter ending memory offset for partition 1 holding mongo (4097MB assuming 8 GB disk): " PART1_END
  read -p "Please enter starting memory offset for partition 1 holding elasticsearch (4098MB assuming 8 GB disk): " PART2_START
  read -p "Please enter ending memory offset for partition 1 holding elasticsearch (8195MB assuming 8 GB disk): " PART2_END
  parted /dev/${DISK_NAME} mklabel gpt
  parted /dev/${DISK_NAME} mkpart data ext4 ${PART1_START} ${PART1_END}
  parted /dev/${DISK_NAME} mkpart data ext4 ${PART2_START} ${PART2_END}
  mkfs.ext4 ${partition1}
  mkfs.ext4 ${partition2}
fi

echo
echo "[INFO] creating mount points and performing mount"
MONGO_DIR="/data/db"
ES_DIR="/data/es"
mkdir -p ${MONGO_DIR}
mkdir -p ${ES_DIR}
mount /dev/${partition1} ${MONGO_DIR}
mount /dev/${partition2} ${ES_DIR}
chmod -R a+rw /data
chown -R root:root /data
echo "[INFO] disk configuration complete"
echo

echo
echo "[INFO] adding scheduled backup of /data/db at 3 AM"
echo
ARCHIVE_DIR="${USER_HOME}/dbArchives"
ARCHIVE_LIMIT=50
mkdir -p "${ARCHIVE_DIR}"

# crontab entry. runs 3 AM every day. tars and zips the mongo db directory. removes archives in excess of limit.
echo "* 3 * * *    sudo tar -c ${MONGO_DIR} | gzip > \"${ARCHIVE_DIR}/\$(date +%Y%m%d%H%M%S).tar.gz\"; \
cd ${ARCHIVE_DIR}; \
archives=(\$(ls | sort -r)); \
count=0; \
while [ \${count} -lt \${#archives[@]} ]; do \
if [ \${count} -gt ${ARCHIVE_LIMIT} ]; then \
rm \${archives[\${count}]}; \
fi; \
count=\$((\${count}+1)); \
done" > crontab

crontab crontab
echo
echo "[INFO] scheduled backup added"
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
GROUPS_CMD_STRING="$(groups ${USER_NAME} | sed "s/${USER_NAME}.*:\s*//" | sed 's/\s\+/,/g'),docker"
usermod -g docker ${USER_NAME}
usermod -G ${GROUPS_CMD_STRING} ${USER_NAME}
echo
echo "[INFO] dev toolchain setup complete"
echo
echo "[INFO] beginning setup of app sources"
echo
mkdir ${USER_HOME}/Workspace/
cd ${USER_HOME}/Workspace
git clone https://github.com/matthewjohnson42/k8s-standalone.git
git clone https://github.com/matthewjohnson42/memex-service.git
git clone https://github.com/matthewjohnson42/memex-ui.git
git clone https://github.com/matthewjohnson42/professional-website.git
cd ${USER_HOME}/Workspace/memex-ui
npm install ng
echo
echo "[INFO] setup of app sources complete"
echo

echo
echo "[INFO] starting setup of Kubernetes"
echo
cd ${USER_HOME}/Workspace/k8s-standalone
sh kubernetes/kubernetes-init.sh ${USER_NAME} ${USER_HOME}
echo
echo "[INFO] Kubernetes setup complete"
echo

echo
echo "[INFO] server initialization complete."
echo
echo "[INFO] deploy of apps can be accomplished by running the build-and-deploy.sh scripts in the k8s-standalone repository that has been cloned into ${USER_HOME}/Workspace"
echo
