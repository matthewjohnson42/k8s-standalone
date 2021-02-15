#! /bin/bash
set -x

# build script for the different components of the app

# note: requires root user permissions
# usage: as default user, `sudo sh build-and-deploy.sh ${HOME}`
# usage: as root (IE, using sudo), `sh build-and-deploy.sh <default-user-home-directory>`

export USER_HOME=$1

sh ufw/ufw-allow-out.sh

cd ${USER_HOME}/Workspace/personal-memex-service
git fetch origin # sudo to deal with issues locking git files on AWS
git checkout origin/master
sh ${USER_HOME}/Workspace/personal-memex-service/docker/docker-build.sh

cd ${USER_HOME}/Workspace/personal-memex-ui
git fetch origin
git checkout origin/master
sh ${USER_HOME}/Workspace/personal-memex-ui/docker/docker-build.sh

sh kubernetes/kubernetes-deploy.sh

sh ufw/ufw-deny-out.sh
