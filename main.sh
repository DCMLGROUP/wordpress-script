#!/bin/bash

# Source variables file
if [ -f "variables.sh" ]; then
    source variables.sh
else
    echo "Le fichier variables.sh est manquant. Veuillez le créer avec les variables requises."
    exit 1
fi

# Fonction pour détecter la distribution
detect_distribution() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VERSION=$VERSION_ID
    else
        echo "Impossible de détecter la distribution"
        exit 1
    fi
}

# Installation des dépendances selon la distribution
install_dependencies() {
    case $OS in
        "Debian GNU/Linux"|"Ubuntu")
            apt update
            apt install -y apache2 php php-mysql php-gd php-xml php-curl \
                         libapache2-mod-php mariadb-server mariadb-client \
                         php-bcmath php-mbstring php-zip unzip wget
            ;;
        "Fedora")
            dnf update -y
            dnf install -y httpd php php-mysql php-gd php-xml php-curl \
                         mariadb-server mariadb php-bcmath php-mbstring php-zip unzip wget
            systemctl enable httpd
            systemctl start httpd
            ;;
        "Raspbian GNU/Linux")
            apt update
            apt install -y apache2 php php-mysql php-gd php-xml php-curl \
                         libapache2-mod-php mariadb-server mariadb-client \
                         php-bcmath php-mbstring php-zip unzip wget
            ;;
        *)
            echo "Distribution non supportée"
            exit 1
            ;;
    esac
}

# Configuration de la base de données
configure_database() {
    systemctl start mariadb
    systemctl enable mariadb
    mysql -e "CREATE DATABASE $DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;"
    mysql -e "CREATE USER '$DB_USER'@'$DB_HOST' IDENTIFIED BY '$DB_PASSWORD';"
    mysql -e "GRANT ALL ON $DB_NAME.* TO '$DB_USER'@'$DB_HOST';"
    mysql -e "FLUSH PRIVILEGES;"
}

# Installation de WordPress
install_wordpress() {
    # Téléchargement et extraction de WordPress
    cd /tmp
    wget https://wordpress.org/latest.zip
    unzip latest.zip
    cp -r wordpress/* /var/www/html/
    rm -rf wordpress latest.zip
    
    # Configuration des permissions
    chown -R www-data:www-data /var/www/html/
    chmod -R 755 /var/www/html/
}

# Configuration du vhost Apache
configure_vhost() {
    cat > /etc/apache2/sites-available/wordpress.conf <<EOF
<VirtualHost *:80>
    ServerName $DOMAIN_NAME
    DocumentRoot /var/www/html
    
    <Directory /var/www/html>
        Options FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/wordpress-error.log
    CustomLog \${APACHE_LOG_DIR}/wordpress-access.log combined
</VirtualHost>
EOF

    a2ensite wordpress.conf
    a2enmod rewrite
    systemctl restart apache2
}

# Configuration de WordPress
configure_wordpress() {

}

# Exécution principale
echo "Début de l'installation de WordPress..."

detect_distribution
install_dependencies
configure_database
install_wordpress
configure_vhost
configure_wordpress

echo "Installation et configuration terminées!"
echo "Vous pouvez maintenant accéder à WordPress via http://$DOMAIN_NAME"
echo "Veuillez compléter l'installation via l'interface web."
