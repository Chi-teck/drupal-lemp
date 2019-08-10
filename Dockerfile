FROM debian:stretch

# Set variables.
ENV DUMB_INIT_VERSION=1.2.2 \
    DRUSH_VERSION=8.3.0 \
    DCG_VERSION=2.0.0-beta3 \
    PHPMYADMIN_VERSION=4.9.0.1 \
    ADMINER_VERSION=4.7.2 \
    MAILHOG_VERSION=v1.0.0 \
    MHSENDMAIL_VERSION=v0.2.0 \
    PECO_VERSION=v0.5.3 \
    BAT_VERSION=0.11.0 \
    GOTTY_VERSION=2.0.0-alpha.3 \
    HOST_USER_NAME=lemp \
    PHP_VERSION=7.3 \
    NODEJS_VERSION=10 \
    HOST_USER_UID=1000 \
    HOST_USER_PASSWORD=123 \
    MYSQL_ROOT_PASSWORD=123 \
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
RUN apt-get update && apt-get -y install --no-install-recommends apt-utils \
    sudo \
    net-tools \
    apt-utils \
    gnupg \
    curl \
    git \
    vim \
    zip \
    unzip \
    mc \
    silversearcher-ag \
    bsdmainutils \
    man \
    openssh-server \
    patch \
    sqlite3 \
    tree \
    ncdu \
    rsync \
    html2text \
    less \
    bash-completion \
    nginx \
    mariadb-server \
    mariadb-client \
    php-xdebug \
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
    php$PHP_VERSION-apcu

# Install dumb-init.
RUN wget https://github.com/Yelp/dumb-init/releases/download/v$DUMB_INIT_VERSION/dumb-init_"$DUMB_INIT_VERSION"_amd64.deb && \
    dpkg -i dumb-init_*.deb && \
    rm dumb-init_"$DUMB_INIT_VERSION"_amd64.deb

# Copy sudoers file.
COPY sudoers /etc/sudoers

# Install SSL.
COPY request-ssl.sh /root
RUN bash /root/request-ssl.sh && rm root/request-ssl.sh

# Update default Nginx configuration.
COPY sites-available/default /etc/nginx/sites-available/default
RUN sed -i "s/%PHP_VERSION%/$PHP_VERSION/g" /etc/nginx/sites-available/default

# Configure MySQL.
RUN sed -i "s/bind-address/#bind-address/" /etc/mysql/mariadb.conf.d/50-server.cnf && \
    sed -i "s/password =/password = $MYSQL_ROOT_PASSWORD/" /etc/mysql/debian.cnf && \
    service mysql start && \
    mysql -uroot -e"SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$MYSQL_ROOT_PASSWORD')" && \
    mysql -uroot -e"UPDATE mysql.user SET plugin = 'mysql_native_password' WHERE user = 'root'" && \
    mysql -uroot -e"GRANT ALL ON *.* TO 'root'@'%' identified by '$MYSQL_ROOT_PASSWORD'" && \
    mysql -uroot -e"FLUSH PRIVILEGES"

# Override some PHP settings.
COPY 30-local-fpm.ini /etc/php/$PHP_VERSION/fpm/conf.d/30-local.ini
COPY 30-local-cli.ini /etc/php/$PHP_VERSION/cli/conf.d/30-local.ini

# Install xdebug manager.
COPY xdebug.sh /usr/local/bin/xdebug
RUN chmod +x /usr/local/bin/xdebug && \
    sed -i "s/%PHP_VERSION%/$PHP_VERSION/g" /usr/local/bin/xdebug

# Create host user.
RUN useradd $HOST_USER_NAME -m -u$HOST_USER_UID -Gsudo -s /bin/bash && \
    echo $HOST_USER_NAME:$HOST_USER_PASSWORD | chpasswd

# Install dot files.
COPY vimrc /etc/vim/vimrc.local 
COPY vim/colors /etc/vim/colors
COPY gitconfig /etc/gitconfig
COPY gitignore /etc/gitignore
COPY config /home/$HOST_USER_NAME/.config
RUN sed -i "s/%USER%/$HOST_USER_NAME/g" /home/$HOST_USER_NAME/.config/mc/hotlist && \
    sed -i "s/%PHP_VERSION%/$PHP_VERSION/g" /home/$HOST_USER_NAME/.config/mc/hotlist
COPY bashrc /tmp/bashrc
RUN cat /tmp/bashrc >> /home/$HOST_USER_NAME/.bashrc && rm /tmp/bashrc

# Install HR.
RUN wget https://raw.githubusercontent.com/LuRsT/hr/master/hr && \
   chmod +x hr && \
   mv hr /usr/local/bin/hr

# Install MailHog.
RUN wget https://github.com/mailhog/MailHog/releases/download/$MAILHOG_VERSION/MailHog_linux_amd64 && \
    chmod +x MailHog_linux_amd64 && \
    mv MailHog_linux_amd64 /usr/local/bin/mailhog && \
    wget https://github.com/mailhog/mhsendmail/releases/download/$MHSENDMAIL_VERSION/mhsendmail_linux_amd64 && \
    chmod +x mhsendmail_linux_amd64 && \
    mv mhsendmail_linux_amd64 /usr/local/bin/mhsendmail

# Install ANSI.
RUN wget https://raw.githubusercontent.com/fidian/ansi/master/ansi && \
    chmod +x ansi && \
    mv ansi /usr/local/bin/ansi

# Install JQ.
RUN wget https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 && \
    chmod +x jq-linux64 && mv jq-linux64 /usr/local/bin/jq

# Install PhpMyAdmin.
RUN wget https://files.phpmyadmin.net/phpMyAdmin/$PHPMYADMIN_VERSION/phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip && \
    unzip phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip && \
    mv phpMyAdmin-$PHPMYADMIN_VERSION-all-languages /usr/share/phpmyadmin && \
    rm phpMyAdmin-$PHPMYADMIN_VERSION-all-languages.zip
COPY config.inc.php /usr/share/phpmyadmin/config.inc.php
RUN sed -i "s/root_pass/$MYSQL_ROOT_PASSWORD/" /usr/share/phpmyadmin/config.inc.php
COPY sites-available/phpmyadmin /etc/nginx/sites-available/phpmyadmin
RUN sed -i "s/%PHP_VERSION%/$PHP_VERSION/g" /etc/nginx/sites-available/phpmyadmin && \
    ln -s /etc/nginx/sites-available/phpmyadmin /etc/nginx/sites-enabled/phpmyadmin

# Install Adminer.
RUN mkdir /usr/share/adminer && \
    wget -O /usr/share/adminer/adminer.php https://www.adminer.org/static/download/$ADMINER_VERSION/adminer-$ADMINER_VERSION.php
COPY sites-available/adminer /etc/nginx/sites-available/adminer
RUN sed -i "s/%PHP_VERSION%/$PHP_VERSION/g" /etc/nginx/sites-available/adminer && \
    ln -s /etc/nginx/sites-available/adminer /etc/nginx/sites-enabled/adminer

# Install Composer.
RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer

# Install Drupal Coder.
RUN mkdir /opt/drupal-coder && \
    COMPOSER_BIN_DIR=/usr/local/bin composer --working-dir=/opt/drupal-coder require drupal/coder && \
    phpcs --config-set installed_paths /opt/drupal-coder/vendor/drupal/coder/coder_sniffer

# Install Symfony console autocomplete.
RUN mkdir /opt/symfony-console-autocomplete && \
    COMPOSER_BIN_DIR=/usr/local/bin composer --working-dir=/opt/symfony-console-autocomplete require bamarni/symfony-console-autocomplete:dev-master

# Install VarDumper Component.
RUN mkdir /opt/var-dumper && \
    COMPOSER_BIN_DIR=/usr/local/bin composer --working-dir=/opt/var-dumper require symfony/var-dumper:^4.2 && \
    COMPOSER_BIN_DIR=/usr/local/bin composer --working-dir=/opt/var-dumper require symfony/console:^4.2
COPY dumper.php /usr/share/php

# Install PHP coding standards Fixer.
RUN mkdir /opt/php-cs-fixer && \
    COMPOSER_BIN_DIR=/usr/local/bin composer --working-dir=/opt/php-cs-fixer require friendsofphp/php-cs-fixer

# Install PHPUnit.
RUN mkdir /opt/phpunit && \
    COMPOSER_BIN_DIR=/usr/local/bin composer --working-dir=/opt/phpunit require phpunit/phpunit

# Install Drush.
RUN wget -O /usr/local/bin/drush  https://github.com/drush-ops/drush/releases/download/$DRUSH_VERSION/drush.phar && \
    chmod +x /usr/local/bin/drush

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

# Install DCG.
RUN wget -O /usr/local/bin/dcg \
    https://github.com/Chi-teck/drupal-code-generator/releases/download/$DCG_VERSION/dcg.phar && \
    chmod +x /usr/local/bin/dcg

# Install DCG completions.
RUN SHELL=/bin/bash symfony-autocomplete dcg  > /etc/bash_completion.d/dcg_complete.sh

# Install Composer completions.
RUN SHELL=/bin/bash symfony-autocomplete composer  > /etc/bash_completion.d/dcomposer_complete.sh

# Install Peco.
RUN wget -P /tmp https://github.com/peco/peco/releases/download/$PECO_VERSION/peco_linux_amd64.tar.gz && \
    tar -xvf /tmp/peco_linux_amd64.tar.gz -C /tmp && \
    mv /tmp/peco_linux_amd64/peco /usr/local/bin/peco && \
    chmod +x /usr/local/bin/peco

# Install Bat.
RUN wget -P /tmp https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat-musl_${BAT_VERSION}_amd64.deb && \
    sudo dpkg -i /tmp/bat-musl_${BAT_VERSION}_amd64.deb

# Install GoTTY.
RUN wget -P /tmp https://github.com/yudai/gotty/releases/download/v$GOTTY_VERSION/gotty_${GOTTY_VERSION}_linux_amd64.tar.gz && \
    tar -xvf /tmp/gotty_${GOTTY_VERSION}_linux_amd64.tar.gz -C /tmp && \
    mv /tmp/gotty /usr/local/bin/gotty && \
    chmod +x /usr/local/bin/gotty

# Install Node.js and NPM.
RUN curl -sL https://deb.nodesource.com/setup_$NODEJS_VERSION.x | bash - && apt-get install -y nodejs

# Install NPM tools.
RUN npm i -g grunt-cli gulp-cli eslint csslint stylelint

# Install Yarn.
RUN apt-get update && apt-get install -y curl apt-transport-https && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update && apt-get install -y yarn

# Preserve default MySQL data.
RUN mkdir /var/lib/mysql_default && cp -R /var/lib/mysql/* /var/lib/mysql_default

# Set host user directory owner.
RUN chown -R $HOST_USER_NAME:$HOST_USER_NAME /home/$HOST_USER_NAME

# Empty /tmp directory.
RUN rm -rf /tmp/*

# Remove default html directory.
RUN rm -r /var/www/html

# Install cmd.sh file.
COPY cmd.sh /root/cmd.sh
RUN chmod +x /root/cmd.sh

# Default command.
CMD ["dumb-init", "-c", "--", "/root/cmd.sh"]
