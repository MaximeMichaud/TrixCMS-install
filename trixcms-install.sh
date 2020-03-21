#!/bin/bash
#
# [Script d'installation automatique sur Linux pour TrixCMS]
#
# GitHub : https://github.com/MaximeMichaud/TrixCMS-install
# URL : https://trixcms.eu/
#
# Ce script est destiné à une installation rapide et facile :
# wget https://raw.githubusercontent.com/MaximeMichaud/TrixCMS-install/master/trixcms-install.sh
# chmod +x trixcms-install.sh
# ./trixcms-install.sh
#
# TrixCMS-install Copyright (c) 2020 Maxime Michaud
# Licensed under MIT License
#
#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to deal
#   in the Software without restriction, including without limitation the rights
#   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#   copies of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in all
#   copies or substantial portions of the Software.
#
#################################################################################
#Couleurs
black=$(tput setaf 0)
red=$(tput setaf 1)
green=$(tput setaf 2)
yellow=$(tput setaf 3)
blue=$(tput setaf 4)
magenta=$(tput setaf 5)
cyan=$(tput setaf 6)
white=$(tput setaf 7)
on_red=$(tput setab 1)
on_green=$(tput setab 2)
on_yellow=$(tput setab 3)
on_blue=$(tput setab 4)
on_magenta=$(tput setab 5)
on_cyan=$(tput setab 6)
on_white=$(tput setab 7)
bold=$(tput bold)
dim=$(tput dim)
underline=$(tput smul)
reset_underline=$(tput rmul)
standout=$(tput smso)
reset_standout=$(tput rmso)
normal=$(tput sgr0)
alert=${white}${on_red}
title=${standout}
sub_title=${bold}${yellow}
repo_title=${black}${on_green}
message_title=${white}${on_magenta}
#################################################################################
function isRoot() {
  if [ "$EUID" -ne 0 ]; then
    return 1
  fi
}

function initialCheck() {
  if ! isRoot; then
    echo "Désolé, vous devez l'exécuter en tant que root"
    exit 1
  fi
  checkOS
}

# Define versions
PHPMYADMIN_VER=5.0.2

function checkOS() {
  if [[ -e /etc/debian_version ]]; then
    OS="debian"
    source /etc/os-release

    if [[ "$ID" == "debian" || "$ID" == "raspbian" ]]; then
      if [[ ! $VERSION_ID =~ (8|9|10) ]]; then
        echo "${alert}Votre version de Debian n'est pas supportée.${normal}"
        echo ""
        echo "${red}Si vous le souhaitez, vous pouvez tout de même continuer."
        echo "Gardez à l'esprit que ce n'est supportée !${normal}"
        echo ""
        until [[ $CONTINUE =~ (y|n) ]]; do
          read -rp "Continuer ? [y/n] : " -e CONTINUE
        done
        if [[ "$CONTINUE" == "n" ]]; then
          exit 1
        fi
      fi
    elif [[ "$ID" == "ubuntu" ]]; then
      OS="ubuntu"
      if [[ ! $VERSION_ID =~ (16.04|18.04) ]]; then
        echo "${alert}Votre version de Ubuntu n'est pas supportée.${normal}"
        echo ""
        echo "${red}Si vous le souhaitez, vous pouvez tout de même continuer."
        echo "Gardez à l'esprit que ce n'est supportée !${normal}"
        echo ""
        until [[ $CONTINUE =~ (y|n) ]]; do
          read -rp "Continuer? [y/n]: " -e CONTINUE
        done
        if [[ "$CONTINUE" == "n" ]]; then
          exit 1
        fi
      fi
    fi
  elif [[ -e /etc/fedora-release ]]; then
    OS=fedora
  elif [[ -e /etc/centos-release ]]; then
    if ! grep -qs "^CentOS Linux release 7" /etc/centos-release; then
      echo "${alert}Votre version de CentOS n'est pas supportée.${normal}"
      echo "${red}Gardez à l'esprit que ce n'est supportée !${normal}"
      echo ""
      unset CONTINUE
      until [[ $CONTINUE =~ (y|n) ]]; do
        read -rp "Continuer? [y/n] : " -e CONTINUE
      done
      if [[ "$CONTINUE" == "n" ]]; then
        exit 1
      fi
    fi
  else
    echo "${alert}On dirait que vous n'exécutez pas ce script d'installation automatique sur une distribution Debian/Ubuntu ${normal}"
    exit 1
  fi
}

function script() {
  installQuestions
  aptupdate
  aptinstall
  aptinstall_apache2
  aptinstall_mysql
  aptinstall_php
  aptinstall_phpmyadmin
  install_trixcms
  install_ioncube
  setupdone

}
function installQuestions() {
  echo "${cyan}Bienvenue dans l'installation automatique pour TrixCMS !"
  echo "https://github.com/MaximeMichaud/TrixCMS-install"
  echo "Je dois vous poser quelques questions avant de commencer l'installation."
  echo "Vous pouvez laisser les options par défaut et appuyer simplement sur Entrée si cela vous convient."
  echo ""
  echo "${alert}Veuillez sélectionner pour MYSQL : Use Legacy Authentication Method${normal}"
  echo "${cyan}Quelle version de PHP ?"
  echo "${red}Rouge = Fin de vie ${yellow}| Jaune = Sécurité uniquement ${green}| Vert = Support & Sécurité"
  echo "${yellow}   1) PHP 7.2 "
  echo "${green}   2) PHP 7.3 (recommandé) ${normal}${cyan} "
  #echo "   3) PHP 7.4 (recommandé) ${normal}${cyan}" (ioncube pas 7.4)
  until [[ "$PHP_VERSION" =~ ^[1-2]$ ]]; do
    read -rp "Version [1-2]: " -e -i 2 PHP_VERSION
  done
  case $PHP_VERSION in
  1)
    PHP="7.2"
    ;;
  2)
    PHP="7.3"
    ;;
  3)
    PHP="7.4"
    ;;
  esac
  echo ""
  echo "Nous sommes prêts à commencer l'installation."
  echo "You will be able to generate a client at the end of the installation."
  APPROVE_INSTALL=${APPROVE_INSTALL:-n}
  if [[ $APPROVE_INSTALL =~ n ]]; then
    read -n1 -r -p "Appuyez sur n'importe quelle touche pour continuer..."
  fi
}

function aptupdate() {
  apt-get update >/dev/null
}
function aptinstall() {
  apt-get -y install ca-certificates apt-transport-https dirmngr zip unzip sudo lsb-release gnupg openssl curl >/dev/null
}

function aptinstall_apache2() {
  apt-get install -y apache2
  a2enmod rewrite
  wget https://raw.githubusercontent.com/MaximeMichaud/TrixCMS-install/master/conf/000-default.conf
  mv 000-default.conf /etc/apache2/sites-available/
  rm -rf 000-default.conf
  service apache2 restart
}

function aptinstall_mysql() {
  if [[ "$OS" =~ (debian|ubuntu) ]]; then
    echo "MYSQL Installation"
    if [[ "$VERSION_ID" == "8" ]]; then
      echo "deb http://repo.mysql.com/apt/debian/ jessie mysql-8.0" >/etc/apt/sources.list.d/mysql.list
      echo "deb-src http://repo.mysql.com/apt/debian/ jessie mysql-8.0" >>/etc/apt/sources.list.d/mysql.list
      apt-key adv --keyserver keys.gnupg.net --recv-keys 8C718D3B5072E1F5
      apt-get -o Acquire::Check-Valid-Until=false update
      apt-get install --allow-unauthenticated mysql-server mysql-client -y
      systemctl enable mysql && systemctl start mysql
    fi
    if [[ "$VERSION_ID" == "9" ]]; then
      echo "deb http://repo.mysql.com/apt/debian/ stretch mysql-8.0" >/etc/apt/sources.list.d/mysql.list
      echo "deb-src http://repo.mysql.com/apt/debian/ stretch mysql-8.0" >>/etc/apt/sources.list.d/mysql.list
      apt-key adv --keyserver keys.gnupg.net --recv-keys 8C718D3B5072E1F5
      apt-get update
      apt-get install --allow-unauthenticated mysql-server mysql-client -y
      systemctl enable mysql && systemctl start mysql
    fi
    if [[ "$VERSION_ID" == "10" ]]; then
      echo "deb http://repo.mysql.com/apt/debian/ buster mysql-8.0" >/etc/apt/sources.list.d/mysql.list
      echo "deb-src http://repo.mysql.com/apt/debian/ buster mysql-8.0" >>/etc/apt/sources.list.d/mysql.list
      apt-key adv --keyserver keys.gnupg.net --recv-keys 8C718D3B5072E1F5
      apt-get update
      apt-get install --allow-unauthenticated mysql-server mysql-client -y
      systemctl enable mysql && systemctl start mysql
    fi
    if [[ "$VERSION_ID" == "16.04" ]]; then
      wget https://dev.mysql.com/get/mysql-apt-config_0.8.8-1_all.deb
      ls mysql-apt-config_0.8.8-1_all.deb
      dpkg -i mysql-apt-config_0.8.8-1_all.deb
      apt-key adv --keyserver keys.gnupg.net --recv-keys 8C718D3B5072E1F5
      apt-get update
      apt-get install --allow-unauthenticated mysql-server mysql-client -y
      systemctl enable mysql && systemctl start mysql
    fi
    if [[ "$VERSION_ID" == "18.04" ]]; then
      wget https://dev.mysql.com/get/mysql-apt-config_0.8.13-1_all.deb
      ls mysql-apt-config_0.8.13-1_all.deb
      dpkg -i mysql-apt-config_0.8.13-1_all.deb
      apt-key adv --keyserver keys.gnupg.net --recv-keys 8C718D3B5072E1F5
      apt-get update
      apt-get install --allow-unauthenticated mysql-server mysql-client -y
      systemctl enable mysql && systemctl start mysql
    fi
    if [[ "$VERSION_ID" == "20.04" ]]; then
      wget https://dev.mysql.com/get/mysql-apt-config_0.8.13-1_all.deb
      ls mysql-apt-config_0.8.13-1_all.deb
      dpkg -i mysql-apt-config_0.8.13-1_all.deb
      apt-key adv --keyserver keys.gnupg.net --recv-keys 8C718D3B5072E1F5
      apt-get update
      apt-get install --allow-unauthenticated mysql-server mysql-client -y
      systemctl enable mysql && systemctl start mysql
    fi
  fi
}

function aptinstall_php() {
  if [[ "$OS" =~ (debian|ubuntu) ]]; then
    echo "PHP Installation"
    wget -q https://packages.sury.org/php/apt.gpg -O- | sudo apt-key add -
    if [[ "$VERSION_ID" == "8" ]]; then
      echo "deb https://packages.sury.org/php/ jessie main" | sudo tee /etc/apt/sources.list.d/php.list
      apt-get update >/dev/null
      apt-get install php$PHP php$PHP-bcmath php$PHP-json php$PHP-mbstring php$PHP-common php$PHP-xml php$PHP-curl php$PHP-gd php$PHP-zip php$PHP-mysql php$PHP-sqlite -y
      sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 20M|' /etc/php/$PHP/apache2/php.ini
      sed -i 's|post_max_size = 8M|post_max_size = 20M|' /etc/php/$PHP/apache2/php.ini
      systemctl restart apache2
    fi
    if [[ "$VERSION_ID" == "9" ]]; then
      echo "deb https://packages.sury.org/php/ stretch main" | sudo tee /etc/apt/sources.list.d/php.list
      apt-get update >/dev/null
      apt-get install php$PHP php$PHP-bcmath php$PHP-json php$PHP-mbstring php$PHP-common php$PHP-xml php$PHP-curl php$PHP-gd php$PHP-zip php$PHP-mysql php$PHP-sqlite -y
      sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 20M|' /etc/php/$PHP/apache2/php.ini
      sed -i 's|post_max_size = 8M|post_max_size = 20M|' /etc/php/$PHP/apache2/php.ini
      systemctl restart apache2
    fi
    if [[ "$VERSION_ID" == "10" ]]; then
      echo "deb https://packages.sury.org/php/ buster main" | sudo tee /etc/apt/sources.list.d/php.list
      apt-get update >/dev/null
      apt-get install php$PHP php$PHP-bcmath php$PHP-json php$PHP-mbstring php$PHP-common php$PHP-xml php$PHP-curl php$PHP-gd php$PHP-zip php$PHP-mysql php$PHP-sqlite -y
      sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 20M|' /etc/php/$PHP/apache2/php.ini
      sed -i 's|post_max_size = 8M|post_max_size = 20M|' /etc/php/$PHP/apache2/php.ini
      systemctl restart apache2
    fi
    if [[ "$VERSION_ID" == "16.04" ]]; then
      add-apt-repository -y ppa:ondrej/php
      apt-get update >/dev/null
      apt install php$PHP libapache2-mod-php$PHP php$PHP-mysql php$PHP-curl php$PHP-json php$PHP-gd php$PHP-memcached php$PHP-intl php$PHP-sqlite3 php$PHP-gmp php$PHP-geoip php$PHP-mbstring php$PHP-xml php$PHP-zip -y
      sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 20M|' /etc/php/$PHP/apache2/php.ini
      sed -i 's|post_max_size = 8M|post_max_size = 20M|' /etc/php/$PHP/apache2/php.ini
      systemctl restart apache2
    fi
    if [[ "$VERSION_ID" == "18.04" ]]; then
      add-apt-repository -y ppa:ondrej/php
      apt-get update >/dev/null
      apt install php$PHP libapache2-mod-php$PHP php$PHP-mysql php$PHP-curl php$PHP-json php$PHP-gd php$PHP-memcached php$PHP-intl php$PHP-sqlite3 php$PHP-gmp php$PHP-geoip php$PHP-mbstring php$PHP-xml php$PHP-zip -y
      sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 20M|' /etc/php/$PHP/apache2/php.ini
      sed -i 's|post_max_size = 8M|post_max_size = 20M|' /etc/php/$PHP/apache2/php.ini
      systemctl restart apache2
    fi
    if [[ "$VERSION_ID" == "20.04" ]]; then
      add-apt-repository -y ppa:ondrej/php
      apt-get update >/dev/null
      apt install php$PHP libapache2-mod-php$PHP php$PHP-mysql php$PHP-curl php$PHP-json php$PHP-gd php$PHP-memcached php$PHP-intl php$PHP-sqlite3 php$PHP-gmp php$PHP-geoip php$PHP-mbstring php$PHP-xml php$PHP-zip -y
      sed -i 's|upload_max_filesize = 2M|upload_max_filesize = 20M|' /etc/php/$PHP/apache2/php.ini
      sed -i 's|post_max_size = 8M|post_max_size = 20M|' /etc/php/$PHP/apache2/php.ini
      systemctl restart apache2
    fi
  fi
}

function aptinstall_phpmyadmin() {
  echo "phpMyAdmin Installation"
  if [[ "$OS" =~ (debian|ubuntu) ]]; then
    mkdir /usr/share/phpmyadmin/
    cd /usr/share/phpmyadmin/ || exit
    wget https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN_VER/phpMyAdmin-$PHPMYADMIN_VER-all-languages.tar.gz
    tar xzf phpMyAdmin-$PHPMYADMIN_VER-all-languages.tar.gz
    mv phpMyAdmin-$PHPMYADMIN_VER-all-languages/* /usr/share/phpmyadmin
    rm /usr/share/phpmyadmin/phpMyAdmin-$PHPMYADMIN_VER-all-languages.tar.gz
    rm -rf /usr/share/phpmyadmin/phpMyAdmin-$PHPMYADMIN_VER-all-languages
    wget https://raw.githubusercontent.com/MaximeMichaud/TrixCMS-install/master/conf/phpmyadmin.conf
    mv phpmyadmin.conf /etc/apache2/sites-available/
    mkdir /usr/share/phpmyadmin/tmp
    chmod 777 /usr/share/phpmyadmin/tmp
    randomBlowfishSecret=$(openssl rand -base64 32)
    sed -e "s|cfg\['blowfish_secret'\] = ''|cfg['blowfish_secret'] = '$randomBlowfishSecret'|" config.sample.inc.php >config.inc.php
    a2ensite phpmyadmin
    systemctl restart apache2
  elif [[ "$OS" =~ (centos|amzn) ]]; then
    echo "No Support"
  elif [[ "$OS" == "fedora" ]]; then
    echo "No Support"
  fi
}

function install_ioncube() {
  wget https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz
  tar -xvzf ioncube_loaders_lin_x86-64.tar.gz
  cd ioncube && cp ioncube_loader_lin_$PHP.so /usr/lib/php/20180731/
  echo "zend_extension=/usr/lib/php/20180731/ioncube_loader_lin_$PHP.so" >>/etc/php/$PHP/apache2/php.ini
  echo "zend_extension=/usr/lib/php/20180731/ioncube_loader_lin_$PHP.so" >>/etc/php/$PHP/cli/php.ini
  systemctl restart apache2
}

function install_trixcms() {
  rm -rf /var/www/html/
  mkdir /var/www/html
  cd /var/www/html
  wget https://trixcms.eu/u/download/cms
  unzip -q cms
  rm -rf cms
  chmod -R 777 /var/www/html
}

function install_composer() {
  curl -sS https://getcomposer.org/installer | php
  mv composer.phar /usr/local/bin/composer
  chmod +x /usr/local/bin/composer
}

function apt-apache2_cloudflare() {
  apt-get update >/dev/null
  cd /root/ || exit
  apt-get install libtool apache2-dev
  wget https://www.cloudflare.com/static/misc/mod_cloudflare/mod_cloudflare.c
  apxs -a -i -c mod_cloudflare.c
  apxs2 -a -i -c mod_cloudflare.c
  systemctl restart apache2
}

function autoUpdate() {
  echo "Activation des mises à jour automatique..."
  apt-get install -y unattended-upgrades
}

function setupdone() {
  echo "C'est terminé !${normal}"
}
function manageMenu() {
  clear
  echo "Bienvenue dans l'installation automatique pour Azorium !"
  echo "https://github.com/MaximeMichaud/TrixCMS-install"
  echo ""
  echo "Il semblerait que le Script a déjà été utilisé dans le passé."
  echo ""
  echo "Qu'est-ce que tu veux faire?"
  echo "   1) Relancer l'installation"
  echo "   2) Mettre à jour phpMyAdmin"
  echo "   3) Ajouter un certificat (https)"
  echo "   4) Mettre à jour le script"
  echo "   5) Quitter"
  until [[ "$MENU_OPTION" =~ ^[1-5]$ ]]; do
    read -rp "Sélectionner une option [1-5] : " MENU_OPTION
  done
  case $MENU_OPTION in
  1)
    install_trixcms
    ;;
  2)
    updatephpMyAdmin
    ;;
  3)
    install_letsencrypt
    ;;
  4)
    update
    ;;
  5)
    exit 0
    ;;
  esac
}

function update() {
  wget https://raw.githubusercontent.com/MaximeMichaud/trixcms-install/master/trixcms-install.sh -O trixcms-install.sh
  chmod +x trixcms-install.sh
  echo ""
  echo "Mise à jour effectuée."
  sleep 2
  ./trixcms-install.sh
  exit
}

function updatephpMyAdmin() {
  rm -rf /usr/share/phpmyadmin/
  mkdir /usr/share/phpmyadmin/
  cd /usr/share/phpmyadmin/ || exit
  wget https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN_VER/phpMyAdmin-$PHPMYADMIN_VER-all-languages.tar.gz
  tar xzf phpMyAdmin-$PHPMYADMIN_VER-all-languages.tar.gz
  mv phpMyAdmin-$PHPMYADMIN_VER-all-languages/* /usr/share/phpmyadmin
  rm /usr/share/phpmyadmin/phpMyAdmin-$PHPMYADMIN_VER-all-languages.tar.gz
  rm -rf /usr/share/phpmyadmin/phpMyAdmin-$PHPMYADMIN_VER-all-languages
  mkdir /usr/share/phpmyadmin/tmp
  chmod 777 /usr/share/phpmyadmin/tmp
  randomBlowfishSecret=$(openssl rand -base64 32)
  sed -e "s|cfg\['blowfish_secret'\] = ''|cfg['blowfish_secret'] = '$randomBlowfishSecret'|" config.sample.inc.php >config.inc.php
}

initialCheck

if [[ -e /var/www/html/app/ ]]; then
  manageMenu
else
  script
fi
