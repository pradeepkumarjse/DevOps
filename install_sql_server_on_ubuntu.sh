sudo wget -qO- https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list)"
sudo apt-get update
sudo apt-get install -y mssql-server
sudo /opt/mssql/bin/mssql-conf setup
sudo systemctl start mssql-server
sqlcmd -S localhost -U sa -P 'YourStrong!Password'
sudo apt-get install -y mssql-tools unixodbc-dev
