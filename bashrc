function parse_git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1 /'
}

export PS1="\[\e[42;30m\] \u@\h \[\e[0m\]\[\e[43;30m\] \w \[\e[0m\]\[\e[46;30m\]\$(parse_git_branch)\[\e[0m\]\n\[\e[01;30m\]$ \[\e[0m\]"

alias mc='. /usr/share/mc/bin/mc-wrapper.sh'

cd /var/www
echo -e "\e[96mWELCOME TO DRUPAL LEMP DEVELOPMENT STACK!\e[0m"
