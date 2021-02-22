#!/bin/bash
set -x

# installs the container orchestration system (kubernetes on containerd)
# invoked from server-init.sh

USER_HOME=$1

echo
echo "[INFO] starting install of kubernetes as microk8s"
echo
# install microk8s to allow for kubernetes master (control plane) and slave (node) on a single host
# microk8s=1.20 has same transitive dependency, containerd=1.3.7, as docker=19.0.13
snap install --classic --channel=1.20/stable microk8s
sudo usermod -a -G microk8s ubuntu
echo
echo "[INFO] beginning configuration of minikube"
echo
# configure microk8s
microk8s enable dns registry storage ingress
cat << _EOF > ${USER_HOME}/daemon.json
{
  "insecure-registries" : ["localhost:32000"]
}
_EOF
mv ${USER_HOME}/daemon.json /etc/docker/daemon.json
systemctl restart docker
echo
echo "[INFO] kubernetes install complete"
echo
