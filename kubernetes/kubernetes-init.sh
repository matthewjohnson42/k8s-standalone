#!/bin/bash
set -x

# installs the container orchestration system (kubernetes on containerd)
# invoked from server-init.sh

echo
echo "[INFO] starting install of kubernetes as microk8s"
echo
# install microk8s to allow for kubernetes master (control plane) and slave (node) on a single host
snap install --classic microk8s
sudo usermod -a -G microk8s ubuntu
newgrp microk8s
echo
echo "[INFO] beginning configuration of minikube"
echo
# configure microk8s
microk8s enable dns registry storage ingress
echo
echo "[INFO] kubernetes install complete"
echo
