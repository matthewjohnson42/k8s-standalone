#! /bin/bash

# build script for the professional-website container
# invokes k8s deploy script after build

# note: requires root user permissions
# usage: as default user, `sudo sh build-and-deploy.sh ${HOME}`
# usage: as root (IE, using sudo), `sh build-and-deploy.sh <default-user-home-directory>`

export USER_HOME=$1

echo
echo "[INFO] ensure that this repo has been updated prior to running this script"
echo

read -p "Enter kubernetes cluster IP for professional-website (from service-cidr, default 10.152.183.0/24 on microk8s): " PROFESSIONAL_WEBSITE_HOST

rm "${USER_HOME}/deploy_env_vars"
echo "PROFESSIONAL_WEBSITE_HOST=${PROFESSIONAL_WEBSITE_HOST}" >> "${USER_HOME}/deploy_env_vars"

echo
echo "[INFO] beginning build of docker container for professional-website"
echo
cd ${USER_HOME}/Workspace/professional-website
git fetch origin # sudo to deal with issues locking git files on AWS
git checkout origin/master
# copy of content from docker/docker-compose-up.sh
# content here references docker internal to minikube, allowing for minikube to reference the built images
docker build --tag localhost:32000/professional-website:0.0.1 --file docker/Dockerfile .
docker push localhost:32000/professional-website:0.0.1

echo
echo "[INFO] build of docker container complete"
echo

echo
echo "[INFO] beginning deploy to Kubernetes"
echo
cd ${USER_HOME}/Workspace/k8s-standalone/kubernetes/professional-website
sh kubernetes-deploy.sh ${USER_HOME}
echo
echo "[INFO] deploy to Kubernetes complete"
echo
