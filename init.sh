sudo apt-get update
sudo apt-get install -y docker.io
cat << _EOF > ~/daemon.json
{
"exec-opts": ["native.cgroupdriver=systemd"]
}
_EOF
sudo mv ~/daemon.json /etc/docker/daemon.json
sudo systemctl enable docker
sudo systemctl stop docker
sudo systemctl start docker
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubeadm
# init kubernetes
sudo kubeadm init
# add user configurations for kubernetes
mkdir -p ~/.kube
sudo cp -i /etc/kubernetes/admin.conf ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
# add network handler for kubernetes
curl https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml -o kube-flannel.yml
kubectl apply -f kube-flannel.yml
# allow pods to run on the master node (only node)
kubectl taint nodes --all node-role.kubernetes.io/master-
