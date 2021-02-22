#! /bin/bash
set -x

# build script for the different components of the app

# note: requires root user permissions
# usage: as default user, `sudo sh build-and-deploy.sh ${HOME}`
# usage: as root (IE, using sudo), `sh build-and-deploy.sh <default-user-home-directory>`

export USER_HOME=$1

echo
echo "[INFO] allowing outbound HTTPS"
echo
cd ${USER_HOME}/Workspace/personal-memex-server
sh ufw/ufw-allow-out.sh

read -p "Enter kubernetes cluster IP for elasticsearch (from service-cidr, default 10.152.183.0/24 on microk8s): " ELASTICSEARCH_HOST
read -p "Enter kubernetes cluster IP for mongo (from service-cidr, default 10.152.183.0/24 on microk8s): " MONGO_HOST
read -p "Enter kubernetes cluster IP for the memex-app (from service-cidr, default 10.152.183.0/24 on microk8s): " MEMEX_HOST
read -p "Enter default user password for mongo: " MONGO_DEFAULT_USER_PW
read -p "Enter encryption key secret for JWT encryption: " TOKEN_ENC_KEY_SECRET
read -p "Enter encryption key secret for encryption of users' passwords: " USERPASS_ENC_KEY_SECRET

rm "${USER_HOME}/deploy_env_vars"
echo "ELASTICSEARCH_HOST=${ELASTICSEARCH_HOST}" >> "${USER_HOME}/deploy_env_vars"
echo "MONGO_HOST=${MONGO_HOST}" >> "${USER_HOME}/deploy_env_vars"
echo "MEMEX_HOST=${MEMEX_HOST}" >> "${USER_HOME}/deploy_env_vars"
echo "MONGO_DEFAULT_USER_PW=${MONGO_DEFAULT_USER_PW}" >> "${USER_HOME}/deploy_env_vars"
echo "TOKEN_ENC_KEY_SECRET=${TOKEN_ENC_KEY_SECRET}" >> "${USER_HOME}/deploy_env_vars"
echo "USERPASS_ENC_KEY_SECRET=${USERPASS_ENC_KEY_SECRET}" >> "${USER_HOME}/deploy_env_vars"

echo
echo "[INFO] beginning build of docker containers for service and UI"
echo
cd ${USER_HOME}/Workspace/personal-memex-service
git fetch origin # sudo to deal with issues locking git files on AWS
git checkout origin/master
# copy of content from docker/docker-compose-up.sh
# content here references docker internal to minikube, allowing for minikube to reference the built images
docker build --tag localhost:32000/memex-mongo:0.0.1 --file docker/mongo/Dockerfile .
docker push localhost:32000/memex-mongo:0.0.1
mvn clean install -f app/pom.xml
docker build --tag localhost:32000/memex-service:0.0.1 --file docker/app/Dockerfile .
docker push localhost:32000/memex-service:0.0.1
cd ${USER_HOME}/Workspace/personal-memex-ui
git fetch origin
git checkout origin/master
# copy of content from docker/docker-compose-up.sh
# content here references docker internal to minikube, allowing for minikube to reference the built images
npm install
npm run ng -- build
docker build --tag localhost:32000/memex-ui:0.0.1 -f docker/Dockerfile .
docker push localhost:32000/memex-ui:0.0.1

echo
echo "[INFO] build of docker containers complete"
echo

echo
echo "[INFO] beginning deploy to Kubernetes"
echo
cd ${USER_HOME}/Workspace/personal-memex-server/kubernetes
sh kubernetes-deploy.sh ${USER_HOME}
echo
echo "[INFO] deploy to Kubernetes complete"
echo

echo
echo "[INFO] beginning configuration of mongo"
echo
cd ${USER_HOME}/Workspace/personal-memex-service/docker/mongo
cat dbInit.js | sed "s/\${MONGO_DEFAULT_USER_PW}/${MONGO_DEFAULT_USER_PW}/g" > dbInitInterpolated.sh
mongo --host ${MONGO_HOST}:27017 < dbInitInterpolated.sh

echo
echo "[INFO] disallowing outbound HTTPS"
echo
cd ${USER_HOME}/Workspace/personal-memex-server
sh ufw/ufw-deny-out.sh
