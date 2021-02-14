# setup firewall
echo
echo "[INFO] beginning configuration of firewall"
echo
sudo ufw --force enable
sudo ufw deny out to any from any
sudo ufw allow in to any port 22 from any
sudo ufw allow in to any port 53 from any
sudo ufw allow in to any port 80 from any
sudo ufw allow in to any port 443 from any
sudo ufw deny in to any from any
