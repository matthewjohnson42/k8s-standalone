#!/bin/bash
set -x

# installs the container orchestration system (kubernetes on containerd)
# invoked from server-init.sh

USER_NAME=$1
USER_HOME=$2

echo
echo "[INFO] starting install of kubernetes as microk8s"
echo
# install microk8s to allow for kubernetes master (control plane) and slave (node) on a single host
# microk8s=1.20 has same transitive dependency, containerd=1.3.7, as docker=19.0.13
sudo -u ${USER_NAME} -g docker bash -c 'sudo snap install --classic --channel=1.20/stable microk8s'
usermod -G microk8s ${USER_NAME}
echo
echo "[INFO] beginning configuration of microk8s"
echo
# configure microk8s
sudo -u ${USER_NAME} -g docker bash -c 'microk8s enable dns registry storage ingress linkerd'
# trust the microk8s docker repository on localhost
cat << _EOF > ${USER_HOME}/daemon.json
{
  "insecure-registries" : ["localhost:32000"]
}
_EOF
mv ${USER_HOME}/daemon.json /etc/docker/daemon.json
systemctl restart docker
# add ingress/tls pre-req to kubernetes
sudo -u ${USER_NAME} -g docker bash -c 'microk8s kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.3.0/cert-manager.yaml'
curl -L -o kubectl-cert-manager.tar.gz https://github.com/jetstack/cert-manager/releases/download/v1.3.0/kubectl-cert_manager-linux-amd64.tar.gz
tar xzf kubectl-cert-manager.tar.gz
sudo mv kubectl-cert_manager /usr/local/bin
# add ingress/tls
sudo -u ${USER_NAME} -g docker bash -c 'microk8s kubectl apply -f ${HOME}/Workspace/personal-memex-server/kubernetes/ingress/ingress-meta.yml'
sudo -u ${USER_NAME} -g docker bash -c 'microk8s kubectl apply -f ${HOME}/Workspace/personal-memex-server/kubernetes/ingress/ingress.yml'
echo
echo "[INFO] please pause to open port 443 on the AWS instance"
read empty
echo
COUNT=0
while [ ${COUNT} -lt ${#USER_GROUPS[@]} ]; do
  GROUPS_STRING="${GROUPS_STRING} -G ${USER_GROUPS[${COUNT}]}"
  COUNT=$((${COUNT}+1))
done
echo
echo "[INFO] kubernetes install complete"
echo
