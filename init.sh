
sudo sh workspaceInit.sh ${HOME}
sudo sh cloudInit.sh ${HOME} $(id -u) $(id -g)
sudo sh webserverInit.sh
sudo sh buildAndDeployApp.sh
