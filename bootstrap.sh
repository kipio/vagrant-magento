# Variables
DBHOST=localhost
#DBHOST=127.0.0.1
DBNAME=magento2
DBUSER=magento2
DBPASSWD=magento2
BASEURL=http://magento.box

echo -e "\n\n------ apt-get update and upgrade ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo apt-get update
sudo apt-get upgrade


##################################################################
# PHP7.4
##################################################################


echo -e "\n\n------ Now installing software-properties-common ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo apt-get install software-properties-common
sudo apt-add-repository ppa:ondrej/php
sudo apt-get update

# Install PHP
echo -e "\n\n------ Installing PHP and PHP-specific packages ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo apt-get install -y php7.4
sudo apt-get -y install libapache2-mod-php7.4 php7.4-common php7.4-mcrypt php7.4-mysql php7.4-xml php7.4-xmlrpc php7.4-curl php7.4-gd php7.4-imagick php7.4-cli php7.4-dev php7.4-imap php7.4-mbstring php7.4-opcache php7.4-soap php7.4-zip php7.4-intl php7.4-json php7.4-curl php7.4-gettext php7.4-bcmath


##################################################################
# GIT APACHE2 ZIP AND UNZIP
##################################################################


echo -e "\n\n------ Now installing GIT ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo apt-get install -y git

echo -e "\n\n------ Now installing APACHE2 ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo apt-get install -y apache2

echo -e "\n\n------ Now installing ZIP ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo apt-get install zip
echo -e "\n\n------ Now installing UNZIP ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo apt-get install unzip


##################################################################
# MYSQL AND PHPMYADMIN
##################################################################


# MySQL setup for development purposes ONLY
echo -e "\n\n------ Now installing MySQL and PhpMyAdmin ------\n"
echo -e "Current time : $(date +'%T')\n"
debconf-set-selections <<< "mysql-server mysql-server/root_password password $DBPASSWD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $DBPASSWD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/dbconfig-install boolean true"
debconf-set-selections <<< "phpmyadmin phpmyadmin/app-password-confirm password $DBPASSWD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/admin-pass password $DBPASSWD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/mysql/app-pass password $DBPASSWD"
debconf-set-selections <<< "phpmyadmin phpmyadmin/reconfigure-webserver multiselect none"

# sudo apt-get -y install mysql-server phpmyadmin >> /var/www/html/vm_build.log 2>&1
sudo apt-get -y install mysql-server phpmyadmin

echo -e "\n\n------ Now setting up MySQL user and databse ------\n"
echo -e "Current time : $(date +'%T')\n"
mysql -uroot -p$DBPASSWD -e "CREATE DATABASE $DBNAME"
mysql -uroot -p$DBPASSWD -e "CREATE USER '$DBUSER'@'$DBHOST' identified by '$DBPASSWD'"
mysql -uroot -p$DBPASSWD -e "GRANT ALL PRIVILEGES ON $DBNAME.* to '$DBUSER'@'$DBHOST'"
mysql -uroot -p$DBPASSWD -e "FLUSH PRIVILEGES"


##################################################################
# UPDATING VHOST
##################################################################


# Enable Apache Mods
sudo a2enmod rewrite
sudo service apache2 restart

echo -e "\n\n------ Allowing Apache override to all ------\n"
echo -e "Current time : $(date +'%T')\n"
sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf

# updating vhost
echo -e "\n\n------ Updating apache VHOST ------\n"
echo -e "Current time : $(date +'%T')\n"

VHOST=$(cat <<EOF
    <VirtualHost *:80>
        DocumentRoot "/var/www/html/magento2/pub"
        ServerName magento.box
        <Directory "/var/www/html/magento2/pub">
            AllowOverride all
        </Directory>
    </VirtualHost>
EOF
)
sudo echo "$VHOST" > /etc/apache2/sites-available/000-default.conf

# Restart Apache
sudo service apache2 restart


##################################################################
# COMPOSER
##################################################################


echo -e "\n\n------ Now installing Composer for PHP package management ------\n"
echo -e "Current time : $(date +'%T')\n"
curl --silent https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer


##################################################################
# JAVA
##################################################################


# install java
echo -e "\n\n------ Now installing Java for ElasticSearch ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo apt-get -y install openjdk-11-jre-headless


##################################################################
# ELASTICSEARCH
##################################################################


# install ElasticSearch
echo -e "\n\n------ Now installing ElasticSearch ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update
sudo apt-get install elasticsearch=7.9.3

sudo a2enmod proxy && sudo a2enmod proxy_http && sudo systemctl restart apache2
# sudo service elasticsearch start
sudo systemctl start elasticsearch
sudo systemctl enable elasticsearch

# install head
# sudo /usr/share/elasticsearch/bin/plugin -install mobz/elasticsearch-head

# either of the next two lines is needed to be able to access "localhost:9200" from the host os
# sudo echo "network.bind_host: 0" >> /etc/elasticsearch/elasticsearch.yml
sudo echo "network.host: 0.0.0.0" >> /etc/elasticsearch/elasticsearch.yml
sudo echo 'discovery.seed_hosts: ["0.0.0.0"]' >> /etc/elasticsearch/elasticsearch.yml
sudo systemctl restart elasticsearch
curl -i http://localhost:9200/_cluster/health


##################################################################
# DOWNLOAD MAGENTO
##################################################################


# following keys are incorrect - so you need to update it
composer config --global http-basic.repo.magento.com ab7d8d0d3b62cd1493f429dcc166dff 063eb3e81ac2e89175256329c4b3601

echo -e "\n\n------ Now downloading Magento2.4.2 ------\n"
echo -e "Current time : $(date +'%T')\n"
composer create-project --repository-url=https://repo.magento.com/ magento/project-community-edition=2.4.2-p1 /var/www/html/magento2


##################################################################
# BEFORE INSTALLING MAGENTO
##################################################################


echo -e "\n\n------ Configuration before installing Magento2.4.2 ------\n"
echo -e "Current time : $(date +'%T')\n"
# Set file permissions before installation
# https://devdocs.magento.com/guides/v2.4/install-gde/composer.html
# cd /var/www/html/<magento install directory>
# find var generated vendor pub/static pub/media app/etc -type f -exec chmod g+w {} +
# find var generated vendor pub/static pub/media app/etc -type d -exec chmod g+ws {} +
# chown -R :www-data . # Ubuntu
# chmod u+x bin/magento

echo -e "\n------ find 1 ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo find /var/www/html/magento2/var /var/www/html/magento2/generated /var/www/html/magento2/vendor /var/www/html/magento2/pub/static /var/www/html/magento2/pub/media /var/www/html/magento2/app/etc -type f -exec chmod g+w {} +

echo -e "\n------ find 2 ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo find /var/www/html/magento2/var /var/www/html/magento2/generated /var/www/html/magento2/vendor /var/www/html/magento2/pub/static /var/www/html/magento2/pub/media /var/www/html/magento2/app/etc -type d -exec chmod g+ws {} +

echo -e "\n------ chown -R ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo chown -R :www-data /var/www/html/magento2/ # Ubuntu

echo -e "\n------ chown u+x ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo chmod u+x /var/www/html/magento2/bin/magento


##################################################################
# INSTALLING MAGENTO
##################################################################


echo -e "\n\n------ Installinging Magento2.4.2 ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo php /var/www/html/magento2/bin/magento setup:install --base-url=$BASEURL --db-host=$DBHOST --db-name=$DBNAME --db-user=$DBUSER --db-password=$DBPASSWD --admin-firstname=admin --admin-lastname=admin --admin-email=test.pionero@gmail.com --admin-user=admin --admin-password=admin123 --language=en_US --currency=USD --timezone=America/Chicago --use-rewrites=1 --backend-frontname=admin --search-engine=elasticsearch7 --elasticsearch-host=localhost --elasticsearch-port=9200


##################################################################
# AFTTER INSTALLING MAGENTO
##################################################################


echo -e "\n\n------ Configuration after installing Magento2.4.2 ------\n"
echo -e "Current time : $(date +'%T')\n"

echo -e "\n------ Setting mode as developer ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo php /var/www/html/magento2/bin/magento deploy:mode:set developer
# above line shows error

echo -e "\n------ Setting cache:disable ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo php /var/www/html/magento2/bin/magento cache:disable

echo -e "\n------ cache:flush ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo php /var/www/html/magento2/bin/magento cache:flush

echo -e "\n------ Setup:performance ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo php /var/www/html/magento2/bin/magento setup:performance:generate-fixtures /var/www/html/magento2/setup/performance-toolkit/profiles/ce/small.xml

echo -e "\n------ Setup:static-content:deploy ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo php /var/www/html/magento2/bin/magento setup:static-content:deploy -f

echo -e "\n------ Setup:di:compile ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo php /var/www/html/magento2/bin/magento setup:di:compile
# above line shows error

echo -e "\n------ Diable Two Factor ------\n"
echo -e "Current time : $(date +'%T')\n"
sudo php /var/www/html/magento2/bin/magento module:disable Magento_TwoFactorAuth
# above line shows error
