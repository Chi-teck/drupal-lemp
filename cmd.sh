#!/usr/bin/env bash

# Return orignal MySQL directory if the mounted one is empty.
if [ ! "$(ls -A "/var/lib/mysql")" ]; then
  cp -R /var/lib/mysql_default/* /var/lib/mysql
  chown -R mysql:mysql /var/lib/mysql
fi

# Change document root owner.
if [ ! "$(ls -A "/var/www")" ]; then
  chown $HOST_USER_NAME:$HOST_USER_NAME /var/www
fi

nohup mailhog &

service nginx start

service php$PHP_VERSION-fpm start

xdebug off

service mysql start

service ssh start

tail -f /var/log/nginx/access.log
