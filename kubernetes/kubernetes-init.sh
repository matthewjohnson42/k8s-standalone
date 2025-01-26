#!/bin/bash

# installs the container orchestration system (kubernetes on containerd)
# usage, as default user:
# cd ~/Workspace/k8s-standalone
# sudo sh kubernetes/kubernetes-init.sh ${USER} ${HOME}

USER_NAME=$1
USER_HOME=$2

echo
echo "[INFO] starting install of kubernetes as microk8s"
echo
# install microk8s to allow for kubernetes master (control plane) and slave (node) on a single host
# microk8s=1.20 has same transitive dependency, containerd=1.3.7, as docker=19.0.13
#sudo -u "${USER_NAME}" -g docker bash -c 'sudo snap install --classic --channel=1.20/stable microk8s'
sudo -u "${USER_NAME}" -g docker bash -c 'sudo snap install --classic microk8s'
usermod -aG "microk8s" "${USER_NAME}"
echo
echo "[INFO] beginning configuration of microk8s"
echo
# configure microk8s
sudo -u "${USER_NAME}" -g docker bash -c 'microk8s enable dns registry storage ingress linkerd'
# trust the microk8s docker repository on localhost
cat << _EOF > "${USER_HOME}/daemon.json"
{
  "insecure-registries" : ["localhost:32000"]
}
_EOF
mv "${USER_HOME}/daemon.json" /etc/docker/daemon.json
systemctl restart docker
microk8s enable registry
microk8s enable ingress
# add ingress/tls pre-req to kubernetes
sudo -u "${USER_NAME}" -g docker bash -c 'microk8s kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.3/cert-manager.yaml'
echo "Waiting 30s for cert-manager containers to be applied" && sleep 30;
#curl -L -o kubectl-cert-manager.tar.gz https://github.com/jetstack/cert-manager/releases/download/v1.3.0/kubectl-cert_manager-linux-amd64.tar.gz
#tar xzf kubectl-cert-manager.tar.gz
#sudo mv kubectl-cert_manager /usr/local/bin
# add ingress/tls
sudo -u "${USER_NAME}" -g docker bash -c "microk8s kubectl apply -f ${USER_HOME}/Workspace/k8s-standalone/kubernetes/memex/ingress/ingress-meta.yml"
sudo -u "${USER_NAME}" -g docker bash -c "microk8s kubectl apply -f ${USER_HOME}/Workspace/k8s-standalone/kubernetes/professional-website/ingress/ingress-meta.yml"
echo "Waiting 10s for ingress metadata to be applied" && sleep 10;
sudo -u "${USER_NAME}" -g docker bash -c "microk8s kubectl apply -f ${USER_HOME}/Workspace/k8s-standalone/kubernetes/memex/ingress/ingress.yml"
sudo -u "${USER_NAME}" -g docker bash -c "microk8s kubectl apply -f ${USER_HOME}/Workspace/k8s-standalone/kubernetes/professional-website/ingress/ingress.yml"
echo "Waiting 10s for ingress controller to be applied" && sleep 10;
echo
echo "[INFO] configuration of microk8s complete"
echo
echo "[INFO] kubernetes install complete"
echo
