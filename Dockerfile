FROM debian:jessie

# Set variables.
ENV MYSQL_PASS=123 \
    DRUSH_VERSION='8.1.2' \
    DCG_VERSION='1.9.1' \
    PHPMYADMIN_VERSION='4.6.3' \
    MAILHOG_VERSION='v0.2.0' \
    HOST_USER_NAME=lemp \
    HOST_USER_UID=1000 \
    HOST_USER_PASS=123 \
    TIMEZONE=Europe/Moscow \
    DEBIAN_FRONTEND=noninteractive

# Set server timezone.
RUN echo $TIMEZONE | tee /etc/timezone && dpkg-reconfigure tzdata

# Install dotdeb repo.
RUN apt-get update \
    && apt-get install -y curl \
    && echo "deb http://packages.dotdeb.org jessie all" > /etc/apt/sources.list.d/dotdeb.list \
    && curl -sS https://www.dotdeb.org/dotdeb.gpg | apt-key add -

# Install required packages.
RUN apt-get update && apt-get -y install \
  sudo supervisor net-tools wget git vim zip unzip mc sqlite3 tree tmux ncdu \
  html2text bash-completion nginx mysql-server mysql-client php7.0-xml \
  php7.0-mysql php7.0-curl php7.0-gd php7.0-json php7.0-mbstring php7.0-cgi php7.0-fpm \
  php7.0 php7.0-xdebug
  
# Copy sudoers file
COPY sudoers /etc/sudoers
  
# Update default nginx configuration.
COPY sites-available/default /etc/nginx/sites-available/default
COPY sites-available/default-locations /etc/nginx/sites-available/default-locations

# Create runtime directory for php-fpm.
RUN mkdir /run/php

# Change mysql root password.
RUN service mysql start && mysqladmin -u root password $MYSQL_PASS

# Install mysql-init.sh script.
COPY mysql-init.sh /usr/local/bin
RUN chmod +x /usr/local/bin/mysql-init.sh

# Fix mysql directory onwer.
#RUN chown -R mysql:mysql /var/lib/mysql

# Change php settings.
COPY 20-development-fpm.ini /etc/php/7.0/fpm/conf.d/20-development.ini
COPY 20-development-cli.ini /etc/php/7.0/cli/conf.d/20-development.ini
COPY 20-xdebug.ini /etc/php/7.0/fpm/conf.d/20-xdebug.ini
COPY 20-xdebug.ini /etc/php/7.0/cli/conf.d/20-xdebug.ini
    
# Create host user.
RUN useradd $HOST_USER_NAME -m -u$HOST_USER_UID -Gsudo
RUN echo $HOST_USER_NAME:$HOST_USER_PASS | chpasswd
  
# Add dot files.
COPY bashrc /home/$HOST_USER_NAME/.bashrc
COPY vimrc /home/$HOST_USER_NAME/.vimrc
COPY gitconfig /home/$HOST_USER_NAME/.gitconfig
COPY gitignore /home/$HOST_USER_NAME/.gitignore

# Install MailHog.
RUN wget https://github.com/mailhog/MailHog/releases/download/$MAILHOG_VERSION/MailHog_linux_amd64 && \
	chmod +x MailHog_linux_amd64 && \
	mv MailHog_linux_amd64 /usr/local/bin/mailhog && \
	wget https://github.com/mailhog/mhsendmail/releases/download/$MAILHOG_VERSION/mhsendmail_linux_amd64 && \
	chmod +x mhsendmail_linux_amd64 && \
	mv mhsendmail_linux_amd64 /usr/local/bin/mhsendmail

# Install PhpMyAdmin
RUN wget http://files.directadmin.com/services/all/phpMyAdmin/phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.tar.gz && \
    tar -xf phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.tar.gz && \
    mv phpMyAdmin-$PHPMYADMIN_VERSION-all-languages /usr/share/phpmyadmin && \
    rm phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.tar.gz
COPY sites-available/phpmyadmin /etc/nginx/sites-available/phpmyadmin
RUN ln -s /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/phpmyadmin

# Install composer.
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Install convert.php
RUN wget https://raw.githubusercontent.com/thomasbachem/php-short-array-syntax-converter/master/convert.php && \
    chmod +x convert.php && \
    mv convert.php /usr/local/bin/convert.php
     
# Install Drush.
RUN wget https://github.com/drush-ops/drush/releases/download/$DRUSH_VERSION/drush.phar && chmod +x drush.phar && mv drush.phar /usr/local/bin/drush
RUN mkdir /home/$HOST_USER_NAME/.drush && chown $HOST_USER_NAME:$HOST_USER_NAME /home/$HOST_USER_NAME/.drush
COPY drushrc.php /home/$HOST_USER_NAME/.drush/drushrc.php

# Install some extra Drush command.
RUN sudo -u $HOST_USER_NAME drush dl registry_rebuild-7 && (cd /home/$HOST_USER_NAME/.drush && wget https://raw.githubusercontent.com/Chi-teck/touch-site/master/touch_site.drush.inc)

# Enable drush completion.
COPY drush.complete.sh /etc/bash_completion.d/drush.complete.sh

# Install phpcs
RUN wget https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar && chmod +x phpcs.phar && mv phpcs.phar /usr/local/bin/phpcs

# Install drupalcs
RUN cd /usr/share/php && drush dl coder && phpcs --config-set installed_paths /usr/share/php/coder/coder_sniffer 

# Install DCG.
RUN wget https://github.com/Chi-teck/drupal-code-generator/releases/download/$DCG_VERSION/dcg.phar && chmod +x dcg.phar && mv dcg.phar /usr/local/bin/dcg

# Install Drupal Console.
RUN curl https://drupalconsole.com/installer -L -o drupal.phar && mv drupal.phar /usr/local/bin/drupal && chmod +x /usr/local/bin/drupal

# Install Node.js and NPM.
RUN curl -sL https://deb.nodesource.com/setup_4.x | bash - && apt-get install -y nodejs

# Install NPM tools.
RUN npm i -g grunt-cli gulp-cli eslint csslint drupal-project-loader

# Add supervisor configuration.
COPY supervisor.conf /etc/supervisor/conf.d/supervisor.conf

# Enable supervisor control to everyone.
RUN sed -i -e 's/chmod=0700/chmod=0777/g' /etc/supervisor/supervisord.conf

# Copy mysql data to a temporary location. 
RUN mkdir /var/lib/_mysql && cp -R /var/lib/mysql/* /var/lib/_mysql

# Set host user directory owner.
RUN chown -R $HOST_USER_NAME:$HOST_USER_NAME /home/$HOST_USER_NAME

# Empty /tmp directory.
RUN rm -rf /tmp/*

CMD ["/usr/bin/supervisord", "-n"]
