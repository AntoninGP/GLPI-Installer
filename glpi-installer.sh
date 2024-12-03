#!/bin/bash

# Mettre à jour les paquets
echo "Mise à jour des paquets"
apt update

# Installer Apache, PHP et les extensions requises
echo "Installation d'Apache et PHP"
apt install -y apache2 libapache2-mod-php
apt install -y php php-{mysql,gd,mbstring,xml,simplexml,xmlrpc,ldap,cas,curl,imap,zip,bz2,intl,apcu,cli,json}

# Installer MariaDB
echo "Installation de MariaDB"
apt install -y mariadb-server mariadb-client

# Configurer la base de données pour GLPI
echo "Configuration de la base de données pour GLPI"
mysql -e "CREATE DATABASE glpi;"
mysql -e "CREATE USER 'glpi'@'localhost' IDENTIFIED BY 'glpi_password';"
mysql -e "GRANT ALL PRIVILEGES ON glpi.* TO 'glpi'@'localhost';"
mysql -e "FLUSH PRIVILEGES;"

# Télécharger et extraire GLPI
echo "Téléchargement et extraction de GLPI"
wget -q https://github.com/glpi-project/glpi/releases/download/10.0.17/glpi-10.0.17.tgz
tar -xzf glpi-10.0.17.tgz
rm glpi-10.0.17.tgz

# Copier les fichiers GLPI dans le répertoire Apache
echo "Copie des fichiers GLPI dans le répertoire Apache"
cp -r glpi /var/www/html/
chown -R www-data:www-data /var/www/html/
rm -rf glpi

# Deplacer les dossiers "config" et "files" en dehors d'apache
echo "Deplacement des dossiers "config" et "files" en dehors d'apache"
mv /var/www/html/config /etc/glpi
mv /var/www/html/files /var/lib/glpi

echo "Redirection des dossiers "config" et "files" dans GLPI"
# Rediriger le dossier config
cp downstream.php /var/www/html/inc/downstream.php
chown -R www-data:www-data /var/www/html/inc/downstream.php
rm downstream.php

# Rediriger le dossier file
cp define.php /etc/glpi/local_define.php
chown -R www-data:www-data /etc/glpi/local_define.php
rm localdefine.php

# création du répertoire de logs
mkdir /var/log/glpi

# Autoriser l'accés au repertoires config, files et log par l'utilisateur www-data
echo "Mise à jour des autorisations..."
chown -R www-data:www-data /var/lib/glpi
chown -R www-data:www-data /var/log/glpi
chown -R www-data:www-data /etc/glpi  

# Php.ini modification variable "session.cookie_httponly = on"
cat /etc/php/8.2/apache2/php.ini | sed -e 's/session.cookie_httponly =/session.cookie_httponly = on/' > /etc/php/8.2/apache2/php.ini

# Redémarrer Apache et MariaDB
echo "Redémarrage d'Apache et MariaDB..."
systemctl restart apache2
systemctl restart mariadb

# Ouvrir le navigateur Web et terminer l'installation via l'interface Web
ipadd=$(ifconfig | grep inet | grep -v -E ‘inet6|127.0.0.1’ | tr -d [:alpha:] | tr -s [:space:] | cut -d: -f2)
echo "GLPI est maintenant opérationnel. Ouvrez votre navigateur et accédez à http://$ipadd/glpi pour terminer l'installation."
