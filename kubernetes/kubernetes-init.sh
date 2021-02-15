#!/bin/bash
set -x

# installs the application container runtime (docker) and container orchestration system (kubernetes)
# invoked from server-init.sh

# note: requires root user permissions
# usage: as default user, `sh kubernetes-init.sh ${USER} ${HOME}`
# usage: as root (IE, using sudo), `sh build-and-deploy.sh <default-user-home-directory>`

USER_NAME=$1
USER_HOME=$2


echo
echo "[INFO] starting install of docker"
echo
# install docker
apt-get update
apt-get install -y docker.io
echo
echo "[INFO] beginning configuration of docker"
echo
# configure docker to use systemd for userspace provisioning; limits performance impact
cat << _EOF > ${USER_HOME}/daemon.json
{
"exec-opts": ["native.cgroupdriver=systemd"]
}
_EOF
mv ${USER_HOME}/daemon.json /etc/docker/daemon.json
# set docker daemon to start on boot, restart daemon to load config
systemctl enable docker
systemctl stop docker
systemctl start docker
# add user to the docker user group.
# allows access to the docker daemon via docker unix socket, accessed by the `docker` cmd line util.
usermod -G docker ${USER_NAME}
usermod -G docker ${USER}
echo
echo "[INFO] docker install complete"
echo


echo
echo "[INFO] starting install of kubernetes as minikube"
echo
# install minikube to enable kubernetes master (control plane) and slave (node) on a single host
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
dpkg -i minikube_latest_amd64.deb
# install kubectl
# possibly uncoupled with minikube's kubernetes install version
snap install kubectl --classic
echo
echo "[INFO] beginning configuration of minikube"
echo
# configure minikube
sudo -u ${USER_NAME} bash -c 'minikube config set driver docker'
sudo -u ${USER_NAME} bash -c 'minikube start'
sudo -u ${USER_NAME} bash -c 'minikube addons enable ingress'
mkdir /root/.kube
cp ${USER_HOME}/.kube/config /root/.kube/config
echo
echo "[INFO] kubernetes install complete"
echo
