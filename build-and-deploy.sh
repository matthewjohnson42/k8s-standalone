#! /bin/bash
set -x

# build script for the different components of the app

# note: requires root user permissions
# usage: as default user, `sudo sh build-and-deploy.sh ${HOME}`
# usage: as root (IE, using sudo), `sh build-and-deploy.sh <default-user-home-directory>`

export USER_HOME=$1

sh ufw/ufw-allow-out.sh

cd ${USER_HOME}/Workspace/personal-memex-service/docker
git fetch origin # sudo to deal with issues locking git files on AWS
git checkout origin/master
sh docker-build.sh

cd ${USER_HOME}/Workspace/personal-memex-ui/docker
git fetch origin
git checkout origin/master
sh docker-build.sh

cd ${USER_HOME}/Workspace/personal-memex-server/kubernetes
sh kubernetes-deploy.sh

cd ${USER_HOME}/Workspace/personal-memex-server
sh ufw/ufw-deny-out.sh
