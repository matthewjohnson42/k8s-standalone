# install docker
sudo apt-get update
sudo apt-get install -y docker.io
# configure docker to use systemd for userspace provisioning; limits performance impact
cat << _EOF > ~/daemon.json
{
"exec-opts": ["native.cgroupdriver=systemd"]
}
_EOF
sudo mv ~/daemon.json /etc/docker/daemon.json
# set docker daemon to start on boot, restart daemon to load config
sudo systemctl enable docker
sudo systemctl stop docker
sudo systemctl start docker
# install kubernetes from apt repo
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubeadm
# init kubernetes with IP range available for managed containers
# ref: https://console.aws.amazon.com/vpc/home?#vpcs
read -p "get CIDR range from https://console.aws.amazon.com/vpc/home?#vpcs : " cidr
sudo kubeadm init --pod-network-cidr ${cidr} --node-name master-kube-node
# add user configurations for kubernetes
mkdir -p ~/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
# add container network interface for kubernetes
curl https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml -o kube-flannel.yml
kubectl apply -f kube-flannel.yml
# allow pods to run on the master node (only node; contrast with multi-node/multi-docker-host cluster)
kubectl taint nodes --all node-role.kubernetes.io/master-
# set up disk using AWS UI and parted
read -p "add disk to instance via AWS UI and enter disk name without device directory: " diskName
sudo parted /dev/${diskName} mklabel gpt
sudo parted /dev/${diskName} mkpart data ext4 1MB 4097MB
sudo parted /dev/${diskName} mkpart data ext4 4098MB 8195MB
sudo mkfs.ext4 /dev/${diskName}1
sudo mkfs.ext4 /dev/${diskName}2
sudo mkdir /data
sudo mkdir /data/db
sudo mkdir /data/es
sudo mount /dev/${diskName}1 /data/db
sudo mount /dev/${diskName}2 /data/es
sudo chmod -R a+rw /data

sudo apt-get install npm
