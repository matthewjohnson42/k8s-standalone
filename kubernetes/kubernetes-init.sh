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
COUNT=0
while [ ${COUNT} -lt ${#USER_GROUPS[@]} ]; do
  GROUPS_STRING="${GROUPS_STRING} -G ${USER_GROUPS[${COUNT}]}"
  COUNT=$((${COUNT}+1))
done
echo
echo "[INFO] kubernetes install complete"
echo
