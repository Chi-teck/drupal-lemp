if [[ -d $HOME/.composer/vendor/bin ]]; then
  export PATH=$PATH:$HOME/.composer/vendor/bin
fi

# Task wrapper that searches for task file recursively.
function task {

  # Do not proceed if '--taskfile' option was supplied.
  for i in "$@"; do
    if [[ $i == -t* || $i == --taskfile=* ]]; then
      command task "$@"
      return $?
    fi
  done

  local DIR=$(pwd)
  while true; do
    if [[ $DIR == '/' ]]; then
      command task "$@"
      return $?
    fi

    if [[ -f $DIR/Taskfile.yml ]]; then
      command task --taskfile="$DIR"/Taskfile.yml "$@"
      return $?
    fi

    DIR=$(dirname "$DIR")
  done
}

alias mc='. /usr/share/mc/bin/mc-wrapper.sh'

function parse_git_branch {
  git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ \1 /'
}

export PS1="\[\e[42;30m\] \u@\h \[\e[0m\]\[\e[43;30m\] \w \[\e[0m\]\[\e[46;30m\]\$(parse_git_branch)\[\e[0m\]\n\[\e[01;30m\]$ \[\e[0m\]"

cd /var/www
echo -e "\e[96mWELCOME TO DRUPAL LEMP DEVELOPMENT STACK!\e[0m"
