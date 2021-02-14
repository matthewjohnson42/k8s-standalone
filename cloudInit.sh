#!/bin/bash
set -ex


# usage: sudo sh cloudInit.sh ${HOME} $(id -u) $(id -g)
USER_HOME=$1
USER_ID=$2
GRP_ID=$3


echo
echo "[INFO] starting install of docker"
echo
# install docker
sudo apt-get update
sudo apt-get install -y docker.io
echo
echo "[INFO] beginning configuration of docker"
echo
# configure docker to use systemd for userspace provisioning; limits performance impact
cat << _EOF > ${USER_HOME}/daemon.json
{
"exec-opts": ["native.cgroupdriver=systemd"]
}
_EOF
sudo mv ${USER_HOME}/daemon.json /etc/docker/daemon.json
# set docker daemon to start on boot, restart daemon to load config
sudo systemctl enable docker
sudo systemctl stop docker
sudo systemctl start docker
echo
echo "[INFO] docker install complete"
echo


echo
echo "[INFO] starting install of kubernetes"
echo
# install cni for kubernetes
export GOPATH=/usr/local/bin
export GO_HOME=/root
sudo snap install go --classic
sudo go get github.com/containernetworking/cni
sudo go install github.com/containernetworking/cni/cnitool
sudo cp /root/go/bin/cnitool /usr/local/bin/
mkdir ${USER_HOME}/Workspace
cd ${USER_HOME}/Workspace
git clone https://github.com/containernetworking/plugins.git
cd plugins
./build_linux.sh
sudo mkdir -p /etc/cni/net.d
echo '{"cniVersion":"0.4.0","name":"flannel","type":"flannel"}' | sudo tee /etc/cni/net.d/10-flannel.conf
sudo mkdir -p /opt/cni/bin
sudo cp ./bin/* /opt/cni/bin
sudo ip netns add flannel
sudo CNI_PATH=./bin cnitool add flannel /var/run/netns/flannel
sudo CNI_PATH=./bin cnitool check flannel /var/run/netns/flannel
# install kubernetes from apt repo
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubeadm
# todo maybe move this to before the install (need seems unlikely)
echo 'KUBELET_EXTRA_ARGS="--network-plugin=cni --cni-bin-dir=/opt/cni/bin --cni-conf-dir=/etc/cni/net.d --cgroup-driver=systemd"' > ${HOME}/kubelet
sudo mv ${HOME}/kubelet /etc/default/kubelet
read -p "get CIDR range from https://console.aws.amazon.com/vpc/home?#vpcs : " cidr
# init kubernetes with:
#   IP range available for managed containers (ref: https://console.aws.amazon.com/vpc/home?#vpcs)
#   a non-default node name to bypass issues with running pods on the Kubernetes control plane being initalized
sudo kubeadm init --pod-network-cidr ${cidr} --node-name=master-kube-node
# add user configurations for kubernetes
mkdir -p ${USER_HOME}/.kube
sudo cp -i /etc/kubernetes/admin.conf ${USER_HOME}/.kube/config
sudo chown ${USER_ID}:${GRP_ID} ${USER_HOME}/.kube/config
# and do so for root as well
sudo mkdir -p /root/.kube
sudo cp -i /etc/kubernetes/admin.conf /root/.kube/config
sudo chown 0:0 /root/.kube/config
# configure master node to allow for execution of workflows
kubectl taint nodes --all node-role.kubernetes.io/master-
echo "[INFO] adding network interface (cni) for kubernetes"
# add pod network for kubernetes
curl https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml -o kube-flannel.yml
kubectl apply -f kube-flannel.yml
# update configuration for kubernetes with:
#   a container network plugin of "container network interface" (ref: https://www.cni.dev/)
#   a directory for CNI plugin binaries from the CNI install performed earlier with go and build scripts (ref: https://github.com/containernetworking/cni)
#   a directory for CNI plugin configurations, added earlier via cnitool
# sudo cat /etc/systemd/system/kubelet.service.d/10-kubeadm.conf | sed 's/KUBELET_CONFIG_ARGS=/KUBELET_CONFIG_ARGS=--network-plugin=cni --cni-bin-dir=\/opt\/cni\/bin --cni-conf-dir=\/etc\/cni\/net.d /g' > /etc/systemd/system/kubelet.service.d/10-kubeadm.conf
echo "[INFO] kubernetes install complete"
echo

echo
echo "[INFO] starting configuration of disks"
# set up disk using AWS UI and parted
read -p "add disk to instance via AWS UI and enter disk name: " diskName
if [ $(ls /dev | grep "${diskName}[0-9]" | wc -l | xargs) -eq 0 ]; then
  echo "partitions not found, creating"
  sudo parted /dev/${diskName} mklabel gpt
  sudo parted /dev/${diskName} mkpart data ext4 1MB 4097MB
  sudo parted /dev/${diskName} mkpart data ext4 4098MB 8195MB
  sudo mkfs.ext4 /dev/${diskName}1
  sudo mkfs.ext4 /dev/${diskName}2
fi
echo "[INFO] creating mount points and performing mount"
sudo mkdir /data
sudo mkdir /data/db
sudo mkdir /data/es
sudo mount /dev/${diskName}1 /data/db
sudo mount /dev/${diskName}2 /data/es
sudo chmod -R a+rw /data
echo "[INFO] disk configuration complete"
echo
