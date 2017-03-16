FROM debian:jessie

# Set variables.
ENV MYSQL_ROOT_PASS=123 \
    DUMB_INIT_VERSION='1.2.0' \
    DRUSH_VERSION='8.1.10' \
    DCG_VERSION='1.15.1' \
    PHPMYADMIN_VERSION='4.7.0-rc1' \
    ADMINER_VERSION='4.3.0' \
    MAILHOG_VERSION='v0.2.1' \
    MHSENDMAIL_VERSION='v0.2.0' \
    HOST_USER_NAME=lemp \
    HOST_USER_UID=1000 \
    HOST_USER_PASS=123 \
    TIMEZONE=Europe/Moscow \
    DEBIAN_FRONTEND=noninteractive \
    PHP_VERSION=7.0

# Set server timezone.
RUN echo $TIMEZONE | tee /etc/timezone && dpkg-reconfigure tzdata

# Install dotdeb repo.
RUN apt-get update \
    && apt-get install -y curl \
    && echo "deb http://packages.dotdeb.org jessie all" > /etc/apt/sources.list.d/dotdeb.list \
    && curl -sS https://www.dotdeb.org/dotdeb.gpg | apt-key add -

# Install required packages.
RUN apt-get update && apt-get -y install \
  sudo net-tools wget git vim zip unzip mc sqlite3 tree tmux ncdu html2text \
  bash-completion nginx mysql-server mysql-client php7.0-xml php7.0-mysql \
  php7.0-sqlite3 php7.0-curl php7.0-gd php7.0-json php7.0-mbstring php7.0-cgi \
  php7.0-fpm php7.0 php7.0-xdebug silversearcher-ag bsdmainutils man

# Install dumb-init.
RUN wget https://github.com/Yelp/dumb-init/releases/download/v$DUMB_INIT_VERSION/dumb-init_"$DUMB_INIT_VERSION"_amd64.deb && dpkg -i dumb-init_*.deb
  
# Copy sudoers file.
COPY sudoers /etc/sudoers
  
# Update default nginx configuration.
COPY sites-available/default /etc/nginx/sites-available/default

# Change mysql root password.
RUN service mysql start && mysqladmin -u root password $MYSQL_ROOT_PASS

# Grant access to debian user.
RUN DEBIAN_PASS=$(cat /etc/mysql/debian.cnf | grep -m1 password | sed 's/password = //') && \
    service mysql start && \
    mysql -uroot -p$MYSQL_ROOT_PASS -e"GRANT ALL PRIVILEGES ON *.* TO 'debian-sys-maint'@'localhost' IDENTIFIED BY '$DEBIAN_PASS' WITH GRANT OPTION";

# Disable bind-address.
RUN sed -i "s/bind-address/#bind-address/" /etc/mysql/my.cnf

# Grant access to root user from any host.
RUN service mysql start && \
    mysql -uroot -p$MYSQL_ROOT_PASS -e"GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASS' WITH GRANT OPTION";

# Change PHP settings.
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
COPY config /home/$HOST_USER_NAME/.config
RUN sed -i "s/%USER%/$HOST_USER_NAME/g" /home/$HOST_USER_NAME/.config/mc/hotlist
RUN sed -i "s/%PHP_VERSION%/$PHP_VERSION/g" /home/$HOST_USER_NAME/.config/mc/hotlist

# Install MailHog.
RUN wget https://github.com/mailhog/MailHog/releases/download/$MAILHOG_VERSION/MailHog_linux_amd64 && \
    chmod +x MailHog_linux_amd64 && \
    mv MailHog_linux_amd64 /usr/local/bin/mailhog && \
    wget https://github.com/mailhog/mhsendmail/releases/download/$MHSENDMAIL_VERSION/mhsendmail_linux_amd64 && \
    chmod +x mhsendmail_linux_amd64 && \
    mv mhsendmail_linux_amd64 /usr/local/bin/mhsendmail

# Install PhpMyAdmin
RUN wget https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN_VERSION/phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip && \
    unzip phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip && \
    mv phpMyAdmin-$PHPMYADMIN_VERSION-all-languages /usr/share/phpmyadmin && \
    rm phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip
COPY config.inc.php /usr/share/phpmyadmin/config.inc.php
RUN sed -i "s/root_pass/$MYSQL_ROOT_PASS/" /usr/share/phpmyadmin/config.inc.php
COPY sites-available/phpmyadmin /etc/nginx/sites-available/phpmyadmin
RUN ln -s /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/phpmyadmin

# Install Adminer
RUN mkdir /usr/share/adminer && \
    wget -O /usr/share/adminer/adminer.php https://www.adminer.org/static/download/$ADMINER_VERSION/adminer-$ADMINER_VERSION.php
COPY sites-available/adminer /etc/nginx/sites-available/adminer
RUN ln -s /etc/nginx/sites-available/adminer /etc/nginx/sites-enabled/adminer

# Install composer.
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Install PHPUnit,
RUN sudo -u $HOST_USER_NAME composer global require "phpunit/phpunit"
RUN echo 'export PATH=~/.composer/vendor/bin:$PATH' >> /home/$HOST_USER_NAME/.bashrc

# Install convert.php
RUN wget https://raw.githubusercontent.com/thomasbachem/php-short-array-syntax-converter/master/convert.php && \
    chmod +x convert.php && \
    mv convert.php /usr/local/bin/convert.php
     
# Install Drush.
RUN wget https://github.com/drush-ops/drush/releases/download/$DRUSH_VERSION/drush.phar && chmod +x drush.phar && mv drush.phar /usr/local/bin/drush
RUN mkdir /home/$HOST_USER_NAME/.drush && chown $HOST_USER_NAME:$HOST_USER_NAME /home/$HOST_USER_NAME/.drush
COPY drushrc.php /home/$HOST_USER_NAME/.drush/drushrc.php
COPY _dcd /etc/bash_completion.d/dcd

# Install some extra Drush command.
RUN drush dl --destination=/home/$HOST_USER_NAME/.drush registry_rebuild-7 site_audit && \
   (cd /home/$HOST_USER_NAME/.drush && wget https://raw.githubusercontent.com/Chi-teck/touch-site/master/touch_site.drush.inc)

# Enable drush completion.
COPY drush.complete.sh /etc/bash_completion.d/drush.complete.sh

# Install phpcs.
RUN wget https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar && chmod +x phpcs.phar && mv phpcs.phar /usr/local/bin/phpcs

# Install drupalcs.
RUN cd /usr/share/php && drush dl coder && phpcs --config-set installed_paths /usr/share/php/coder/coder_sniffer

# Install DCG.
RUN wget https://github.com/Chi-teck/drupal-code-generator/releases/download/$DCG_VERSION/dcg.phar && chmod +x dcg.phar && mv dcg.phar /usr/local/bin/dcg

# Install Drupal Console.
RUN curl https://drupalconsole.com/installer -L -o drupal.phar && mv drupal.phar /usr/local/bin/drupal && chmod +x /usr/local/bin/drupal

# Install Symfony console autocomplete.
RUN sudo -u $HOST_USER_NAME composer global require bamarni/symfony-console-autocomplete

# Install DCG completions.
RUN sudo -u $HOST_USER_NAME /home/$HOST_USER_NAME/.composer/vendor/bin/symfony-autocomplete dcg  > /etc/bash_completion.d/dcg_complete.sh

# Install Composer completions.
RUN sudo -u $HOST_USER_NAME /home/$HOST_USER_NAME/.composer/vendor/bin/symfony-autocomplete composer  > /etc/bash_completion.d/dcomposer_complete.sh

# Install d8-install script.
COPY d8-install /usr/local/bin/d8-install
RUN chmod +x /usr/local/bin/d8-install

# Install Node.js and NPM.
RUN curl -sL https://deb.nodesource.com/setup_4.x | bash - && apt-get install -y nodejs

# Install NPM tools.
RUN npm i -g grunt-cli gulp-cli bower eslint csslint drupal-project-loader

# Copy mysql data to a temporary location. 
RUN mkdir /var/lib/_mysql && cp -R /var/lib/mysql/* /var/lib/_mysql

# Set host user directory owner.
RUN chown -R $HOST_USER_NAME:$HOST_USER_NAME /home/$HOST_USER_NAME

# Empty /tmp directory.
RUN rm -rf /tmp/*

# Install cmd.sh file.
COPY cmd.sh /root/cmd.sh
RUN chmod +x /root/cmd.sh

# Default command..
CMD ["dumb-init", "-c", "--", "/root/cmd.sh"]
