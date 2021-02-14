
USER_HOME=$1
echo
echo "[INFO] beginning setup of dev toolchain"
echo
sudo apt-get update
sudo apt-get install -y npm maven
echo
echo "[INFO] dev toolchain setup complete"
echo
echo "[INFO] beginning setup of app sources"
echo
sudo mkdir ${USER_HOME}/Workspace/
cd ${USER_HOME}/Workspace
git clone https://github.com/matthewjohnson42/personal-memex-ui.git
git clone https://github.com/matthewjohnson42/personal-memex-service.git
echo
echo "[INFO] setup of app sources complete"
echo
