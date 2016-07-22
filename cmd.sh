#! /bin/bash

# Copy mysql data.
if [ ! "$(ls -A "/var/lib/mysql")" ]; then
  cp -R /var/lib/_mysql/* /var/lib/mysql
  chown -R mysql:mysql /var/lib/mysql
fi

echo 'Starting nginx...'
service nginx start

echo 'Starting mysql...'
service mysql start

echo 'Starting php-fpm...'
service php7.0-fpm start

echo 'Starting mailhog...'
nohup mailhog &

echo 'Starting bash...'
bash
