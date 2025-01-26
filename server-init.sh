#! /bin/bash

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
read -p "Add primary disk to AWS instance via AWS UI and enter primary disk name: " DISK_NAME
partition1=$(ls /dev/ | grep ${DISK_NAME} | sort | tail -n 2 | head -n 1 | grep 'p1$')
partition2=$(ls /dev/ | grep ${DISK_NAME} | sort | tail -n 1 | grep 'p2$')
if [ -z "${partition1}" ] && [ -z "${partition2}" ]; then
  echo "partitions not found, creating"
  read -p "Please enter starting memory offset for partition 1 holding mongo (1MB assuming 8 GB disk): " PART1_START
  read -p "Please enter ending memory offset for partition 1 holding mongo (4097MB assuming 8 GB disk): " PART1_END
  read -p "Please enter starting memory offset for partition 1 holding elasticsearch (4098MB assuming 8 GB disk): " PART2_START
  read -p "Please enter ending memory offset for partition 1 holding elasticsearch (8195MB assuming 8 GB disk): " PART2_END
  parted /dev/${DISK_NAME} mklabel gpt && sleep 1
  parted /dev/${DISK_NAME} mkpart data ext4 ${PART1_START} ${PART1_END} && sleep 1
  parted /dev/${DISK_NAME} mkpart data ext4 ${PART2_START} ${PART2_END} && sleep 1
  partition1=$(ls /dev/ | grep ${DISK_NAME} | sort | tail -n 2 | head -n 1 | grep 'p1$')
  partition2=$(ls /dev/ | grep ${DISK_NAME} | sort | tail -n 1 | grep 'p2$')
  mkfs.ext4 /dev/${partition1}
  mkfs.ext4 /dev/${partition2}
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
chmod -R a+rw /backup
chown -R root:root /backup
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
apt-get install -y npm maven docker.io
curl https://downloads.mongodb.com/compass/mongodb-mongosh_2.2.12_amd64.deb -o mongodb-mongosh_2.2.12_amd64.deb
dpkg -i mongodb-mongosh_2.2.12_amd64.deb
# set docker daemon to start on boot, restart daemon to load config. note docker configs exist in kubernetes-init.sh
systemctl enable docker
# add user to the docker user group.
# allows access to the docker daemon via docker unix socket, accessed by the `docker` cmd line util.
# requires new user session
usermod -aG docker ${USER_NAME}
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
echo "[INFO] adding server cron jobs"
echo
cd "${USER_HOME}/Workspace/k8s-standalone"
USER_HOME_ESC=$(echo "${USER_HOME}" | sed 's/\//\\\//g')
mkdir -p "${USER_HOME}/cron"
cat cron/crontab | sed "s/\${USER_HOME}/${USER_HOME_ESC}/g" > "${USER_HOME}/cron/crontab"
sudo -u ${USER_NAME} crontab "${USER_HOME}/cron/crontab"
echo
echo "[INFO] cron jobs added"
echo

echo
echo "[INFO] starting addition of entries to user home directory"
echo

if [ -f "${USER_HOME}/.bash_profile" ]; then
  cat userhome/bash_profile_append >> "${USER_HOME}/.bash_profile"
fi

if [ -f "${USER_HOME}/.bashrc" ]; then
  cat userhome/bash_profile_append >> "${USER_HOME}/.bashrc"
fi

echo
echo "[INFO] addition of entries to user home directory complete"
echo

echo
echo "[INFO] server initialization complete."
echo
echo "[INFO] the current user session should be terminated, and a new session started. this will update user permissions."
echo "[INFO] following re-login, the following command should be run to initialize the kubernetes cluster on the instance:"
echo
echp "cd ~/Workspace/k8s-standalone"
echo "sudo sh kubernetes/kubernetes-init.sh \${USER} \${HOME}"
echo
