FROM debian:jessie

# Set variables.
ENV DUMB_INIT_VERSION=1.2.1 \
    DRUSH_VERSION=8.1.15 \
    DCG_VERSION=1.21.3 \
    PHPMYADMIN_VERSION=4.7.6 \
    ADMINER_VERSION=4.3.1 \
    MAILHOG_VERSION=v1.0.0 \
    MHSENDMAIL_VERSION=v0.2.0 \
    PECO_VERSION=v0.5.2 \
    HOST_USER_NAME=lemp \
    PHP_VERSION=7.2 \
    NODEJS_VERSION=9 \
    YARN_VERSION=1.3.2 \
    HOST_USER_UID=1000 \
    HOST_USER_PASS=123 \
    MYSQL_ROOT_PASS=123 \
    TIMEZONE=Europe/Moscow \
    DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Set server timezone.
RUN echo $TIMEZONE > /etc/timezone && dpkg-reconfigure tzdata

# Update Apt sources.
RUN apt-get update && apt-get -y install wget apt-transport-https lsb-release ca-certificates && \
    wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg && \
    echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

# Install required packages.
RUN apt-get update && apt-get -y install \
  sudo \
  net-tools \
  apt-utils \
  curl \
  git \
  vim \
  zip \
  unzip \
  mc \
  sqlite3 \
  tree \
  ncdu \
  html2text \
  less \
  bash-completion \
  nginx \
  mysql-server \
  mysql-client \
  php$PHP_VERSION-xml \
  php$PHP_VERSION-mysql \
  php$PHP_VERSION-sqlite3 \
  php$PHP_VERSION-curl \
  php$PHP_VERSION-gd \
  php$PHP_VERSION-json \
  php$PHP_VERSION-mbstring \
  php$PHP_VERSION-cgi \
  php$PHP_VERSION-fpm \
  php$PHP_VERSION \
  php$PHP_VERSION-apcu \
  silversearcher-ag \
  bsdmainutils \
  man

# Install dumb-init.
RUN wget https://github.com/Yelp/dumb-init/releases/download/v$DUMB_INIT_VERSION/dumb-init_"$DUMB_INIT_VERSION"_amd64.deb && \
    dpkg -i dumb-init_*.deb && \
    rm dumb-init_"$DUMB_INIT_VERSION"_amd64.deb

# Copy sudoers file.
COPY sudoers /etc/sudoers

# Update default Nginx configuration.
COPY sites-available/default /etc/nginx/sites-available/default
RUN sed -i "s/%PHP_VERSION%/$PHP_VERSION/g" /etc/nginx/sites-available/default

# Change MySql root password.
RUN service mysql start && mysqladmin -u root password $MYSQL_ROOT_PASS

# Disable bind-address.
RUN sed -i "s/bind-address/#bind-address/" /etc/mysql/my.cnf

# Grant access to root user from any host.
RUN service mysql start && \
    mysql -uroot -p$MYSQL_ROOT_PASS -e"GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY '$MYSQL_ROOT_PASS' WITH GRANT OPTION";

# Change PHP settings.
COPY 20-development-fpm.ini /etc/php/$PHP_VERSION/fpm/conf.d/20-development.ini
COPY 20-development-cli.ini /etc/php/$PHP_VERSION/cli/conf.d/20-development.ini

# Xdebug does not support PHP 7.2 yet.
#COPY 20-xdebug.ini /etc/php/$PHP_VERSION/fpm/conf.d/20-xdebug.ini
#COPY 20-xdebug.ini /etc/php/$PHP_VERSION/cli/conf.d/20-xdebug.ini

# Create host user.
RUN useradd $HOST_USER_NAME -m -u$HOST_USER_UID -Gsudo
RUN echo $HOST_USER_NAME:$HOST_USER_PASS | chpasswd

# Install dot files.
COPY vimrc /etc/vim/vimrc.local 
COPY vim/colors /etc/vim/colors
COPY gitconfig /home/$HOST_USER_NAME/.gitconfig
COPY gitignore /home/$HOST_USER_NAME/.gitignore
COPY config /home/$HOST_USER_NAME/.config
RUN sed -i "s/%USER%/$HOST_USER_NAME/g" /home/$HOST_USER_NAME/.config/mc/hotlist
RUN sed -i "s/%PHP_VERSION%/$PHP_VERSION/g" /home/$HOST_USER_NAME/.config/mc/hotlist
COPY bashrc /tmp/bashrc
RUN cat /tmp/bashrc >> /home/$HOST_USER_NAME/.bashrc && rm /tmp/bashrc

# Install MailHog.
RUN wget https://github.com/mailhog/MailHog/releases/download/$MAILHOG_VERSION/MailHog_linux_amd64 && \
    chmod +x MailHog_linux_amd64 && \
    mv MailHog_linux_amd64 /usr/local/bin/mailhog && \
    wget https://github.com/mailhog/mhsendmail/releases/download/$MHSENDMAIL_VERSION/mhsendmail_linux_amd64 && \
    chmod +x mhsendmail_linux_amd64 && \
    mv mhsendmail_linux_amd64 /usr/local/bin/mhsendmail

RUN wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && \
    chmod +x jq-linux64 && mv jq-linux64 /usr/local/bin/jq

# Install PhpMyAdmin
RUN wget https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN_VERSION/phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip && \
    unzip phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip && \
    mv phpMyAdmin-$PHPMYADMIN_VERSION-all-languages /usr/share/phpmyadmin && \
    rm phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip
COPY config.inc.php /usr/share/phpmyadmin/config.inc.php
RUN sed -i "s/root_pass/$MYSQL_ROOT_PASS/" /usr/share/phpmyadmin/config.inc.php
COPY sites-available/phpmyadmin /etc/nginx/sites-available/phpmyadmin
RUN sed -i "s/%PHP_VERSION%/$PHP_VERSION/g" /etc/nginx/sites-available/phpmyadmin
RUN ln -s /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/phpmyadmin

# Install Adminer
RUN mkdir /usr/share/adminer && \
    wget -O /usr/share/adminer/adminer.php https://www.adminer.org/static/download/$ADMINER_VERSION/adminer-$ADMINER_VERSION.php
COPY sites-available/adminer /etc/nginx/sites-available/adminer
RUN sed -i "s/%PHP_VERSION%/$PHP_VERSION/g" /etc/nginx/sites-available/adminer
RUN ln -s /etc/nginx/sites-available/adminer /etc/nginx/sites-enabled/adminer

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Install Composer packages.
COPY composer.json /opt/composer/composer.json
RUN composer --working-dir=/opt/composer install

# Install convert.php
RUN wget -O /usr/local/bin/convert.php \
    https://raw.githubusercontent.com/thomasbachem/php-short-array-syntax-converter/master/convert.php && \
    chmod +x /usr/local/bin/convert.php

# Install Drush.
RUN wget -O /usr/local/bin/drush \
    https://github.com/drush-ops/drush/releases/download/$DRUSH_VERSION/drush.phar && \
    chmod +x /usr/local/bin/drush
RUN mkdir /home/$HOST_USER_NAME/.drush && chown $HOST_USER_NAME:$HOST_USER_NAME /home/$HOST_USER_NAME/.drush
COPY drushrc.php /home/$HOST_USER_NAME/.drush/drushrc.php

# Install some extra Drush command.
RUN wget -P /home/$HOST_USER_NAME/.drush https://raw.githubusercontent.com/Chi-teck/touch-site/master/touch_site.drush.inc

# Enable drush completion.
COPY drush.complete.sh /etc/bash_completion.d/drush.complete.sh

# Install DrupalRC.
RUN url=https://raw.githubusercontent.com/Chi-teck/drupalrc/master && \
    wget -O /etc/drupalrc $url/drupalrc && echo source /etc/drupalrc >> /etc/bash.bashrc && \
    wget -O /etc/bash_completion.d/drupal.complete.sh $url/drupal.complete.sh && \
    mkdir /usr/share/drupal-projects && \
    wget -P /usr/share/drupal-projects $url/drupal-projects/d6.txt && \
    wget -P /usr/share/drupal-projects $url/drupal-projects/d7.txt && \
    wget -P /usr/share/drupal-projects $url/drupal-projects/d8.txt

# Register Drupal codding standards.
RUN phpcs --config-set installed_paths /opt/composer/vendor/drupal/coder/coder_sniffer

# Install DCG.
RUN wget -O /usr/local/bin/dcg \
   https://github.com/Chi-teck/drupal-code-generator/releases/download/$DCG_VERSION/dcg.phar && \
   chmod +x /usr/local/bin/dcg

# Install DCG completions.
RUN sudo -u $HOST_USER_NAME symfony-autocomplete dcg  > /etc/bash_completion.d/dcg_complete.sh

# Install Composer completions.
RUN sudo -u $HOST_USER_NAME symfony-autocomplete composer  > /etc/bash_completion.d/dcomposer_complete.sh

# Install Peco.
RUN wget -P /tmp https://github.com/peco/peco/releases/download/$PECO_VERSION/peco_linux_amd64.tar.gz && \
    tar -xvf /tmp/peco_linux_amd64.tar.gz -C /tmp && \
    mv /tmp/peco_linux_amd64/peco /usr/local/bin/peco && \
    chmod +x /usr/local/bin/peco

# Install Node.js and NPM.
RUN curl -sL https://deb.nodesource.com/setup_$NODEJS_VERSION.x | bash - && apt-get install -y nodejs

# Install NPM tools.
RUN npm i -g grunt-cli gulp-cli eslint csslint stylelint

# Install Yarn.
RUN apt-get update && apt-get install -y curl apt-transport-https && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y yarn

# Copy MySql data to a temporary location.
RUN service mysql stop && mkdir /var/lib/_mysql && cp -R /var/lib/mysql/* /var/lib/_mysql

# Set host user directory owner.
RUN chown -R $HOST_USER_NAME:$HOST_USER_NAME /home/$HOST_USER_NAME

# Empty /tmp directory.
RUN rm -rf /tmp/*

# Remove default html directory.
RUN rm -r /var/www/html

# Install cmd.sh file.
COPY cmd.sh /root/cmd.sh
RUN chmod +x /root/cmd.sh

# Default command..
CMD ["dumb-init", "-c", "--", "/root/cmd.sh"]
