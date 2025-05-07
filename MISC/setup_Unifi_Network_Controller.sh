
# Ubuntu 22.04

sudo apt update && sudo apt upgrade -y

sudo apt install gnupg curl ca-certificates apt-transport-https -y

curl -fsSL https://pgp.mongodb.com/server-6.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu $(lsb_release -sc)/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list

sudo apt update
sudo apt install -y mongodb-org

sudo systemctl enable mongod
sudo systemctl start mongod

echo 'deb https://www.ui.com/downloads/unifi/debian stable ubiquiti' | sudo tee /etc/apt/sources.list.d/100-ubnt-unifi.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv C0A52C50

sudo apt update
sudo apt install unifi -y

sudo systemctl enable unifi
sudo systemctl start unifi


sudo ufw allow ssh
sudo ufw allow 8443/tcp
sudo ufw allow 8080/tcp
sudo ufw allow 8843/tcp
sudo ufw allow 8880/tcp
sudo ufw allow 3478/udp
sudo ufw enable


sudo apt install unattended-upgrades

https://public-ip>:8443
