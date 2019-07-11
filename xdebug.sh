#!/bin/bash

if [ $EUID -ne 0 ]; then
  >&2 ansi --red --bold 'This script should be run as root.'
  exit 1
fi

if [ "$1" = 'on' ]; then
  phpenmod xdebug && service apache2 reload
elif [ "$1" = 'off' ]; then
  phpdismod xdebug && service apache2 reload
else
  >&2 echo Usage: $(basename -- "$0") '[on|off]';
  exit 1
fi
