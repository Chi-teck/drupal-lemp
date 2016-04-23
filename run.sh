#! /bin/bash

if [ "$(ls -A "/var//www")" ]; then
  echo 'Use existing document root directory'
else
  echo 'Copy document root to the mounted directory.'
  cp -R /var/_www/* /var/www/
  rm -r /var/_www
  chown -R $HOST_USER_NAME:$HOST_USER_NAME /var/www
fi

if [ "$(ls -A "/var/lib/mysql")" ]; then
  echo 'Use existing database directory'
else
  echo  'Copy databases to the mounted directory.'
  cp -R /var/lib/_mysql/* /var/lib/mysql
  rm -r /var/lib/_mysql
  chown -R mysql:mysql /var/lib/mysql
fi

supervisord -c /etc/supervisor/supervisord.conf
bash
