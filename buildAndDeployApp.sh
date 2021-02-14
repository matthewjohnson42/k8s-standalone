
sudo sh ~/ufwAllowOut.sh

cd ~/Workspace/personal-memex-ui
git fetch origin
git checkout origin/master
sh docker/kube-build-and-deploy.sh

cd ~/Workspace/personal-memex-service
git fetch origin
git checkout origin/master
sh docker/kube-build-and-deploy.sh

sudo sh ~/ufwDenyOut.sh
