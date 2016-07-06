#! /bin/bash

if [ ! "$(ls -A "/var/lib/mysql")" ]; then
  cp -R /var/lib/_mysql/* /var/lib/mysql
  chown -R mysql:mysql /var/lib/mysql
fi

rm -r /var/lib/_mysql

exit 0;
