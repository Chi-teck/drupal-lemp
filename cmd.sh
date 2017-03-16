#! /bin/bash

# Copy mysql data.
if [ ! "$(ls -A "/var/lib/mysql")" ]; then
  cp -R /var/lib/_mysql/* /var/lib/mysql
  chown -R mysql:mysql /var/lib/mysql
fi

# Change document root owner.
if [ ! "$(ls -A "/var/www")" ]; then
  chown $HOST_USER_NAME:$HOST_USER_NAME /var/www
fi

echo 'Starting nginx...'
service nginx start

echo 'Starting mysql...'
service mysql start

echo 'Starting php-fpm...'
service php$PHP_VERSION-fpm start

echo 'Starting mailhog...'
nohup mailhog &

echo 'Starting bash...'
bash
