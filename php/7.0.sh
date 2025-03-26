sudo apt update && sudo apt install -y lsb-release apt-transport-https ca-certificates wget
wget -qO- https://packages.sury.org/php/apt.gpg | sudo tee /etc/apt/trusted.gpg.d/php.gpg > /dev/null
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
sudo apt update


sudo apt install -y php7.0 php7.0-fpm php7.0-cli php7.0-common php7.0-curl php7.0-gd php7.0-intl \
php7.0-mbstring php7.0-bcmath php7.0-xml php7.0-soap php7.0-xsl php7.0-zip php7.0-json \
php7.0-opcache php7.0-mysql php7.0-readline php7.0-mcrypt libapache2-mod-php7.0

apt install php7.0-pdo php7.0-sqlite3 php7.0-mysql -y


systemctl restart php7.0-fpm
systemctl restart apache2

plesk bin php_handler --add -displayname "PHP 7.0 by Sury" \
-path /usr/sbin/php-fpm7.0 \
-clipath /usr/bin/php7.0 \
-phpini /etc/php/7.0/fpm/php.ini \
-type fpm \
-id php7.0 \
-service php7.0-fpm \
-poold /etc/php/7.0/fpm/pool.d
