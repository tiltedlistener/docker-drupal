FROM ubuntu:14.04

MAINTAINER tiltedlistener

# Getting baseline ready
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y vim
RUN apt-get install -y git

# Get Apache
RUN apt-get install -y apache2

# Configure Database
RUN /bin/bash -l -c 'echo "mysql-server mysql-server/root_password select root" | debconf-set-selections'
RUN /bin/bash -l -c 'echo "mysql-server mysql-server/root_password_again select root" | debconf-set-selections'
RUN apt-get install -y mysql-server libapache2-mod-auth-mysql php5-mysql
RUN /bin/bash -l -c "service mysql start; mysql -uroot -e 'Create database if not exists drupal'"
RUN /bin/bash -l -c "service mysql start; mysql -uroot -e 'UPDATE mysql.user SET Password=PASSWORD('root') WHERE User='root'";

# Install PHP
RUN apt-get install -y php5 libapache2-mod-php5 php5-mcrypt php5-gd

# Install Drush
RUN apt-get install -y drush

# Run Drupal Make 
ADD drupal.make /var/www/drupal.make
RUN drush make /var/www/drupal.make /var/www/drupal
RUN mv /var/www/html /var/www/html-old
RUN mv /var/www/drupal /var/www/html

# Setting up settings and files folders
RUN cp /var/www/html/sites/default/default.settings.php /var/www/html/sites/default/settings.php 
RUN mkdir /var/www/html/sites/default/files
RUN chmod a+w /var/www/html/sites/default/settings.php 
RUN chmod a+w /var/www/html/sites/default/files
RUN chmod a+w /var/www/html/sites/default

# Enable mod_rewrite
RUN a2enmod rewrite

# Update apache2 config for htaccess overrides
ADD apache2.conf /etc/apache2/apache2.conf

# Run Drupal Installation
RUN /bin/bash -l -c "cd /var/www/html;  service mysql start; drush site-install -y standard --account-name=admin --account-pass=root --db-url=mysql://root:root@localhost/drupal"