#!/bin/bash

if [ $EUID -ne 0 ]; then
  >&2 echo -e '\e[91mPlease run as root.\e[0m'
  exit 1
fi

if [ $1 = 'on' ]; then
  phpenmod -s fpm xdebug && phpenmod -s cli xdebug && service php%PHP_VERSION%-fpm reload
elif [ $1 = 'off' ]; then
  phpdismod -s fpm xdebug && phpdismod -s cli xdebug && service php%PHP_VERSION%-fpm reload
else
  >&2 echo Usage: $(basename -- "$0") '[on|off]';
  exit 1
fi
