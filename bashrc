# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples

# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
#force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi

# Navigation between Drupal directories.
function dcd {
  local drupal_root drupal_version current_dir

  current_dir=$(pwd);
  while true; do
    if [ $current_dir == '/' ]; then
      echo dcd: no Drupal root directory was found
      return 1;
    fi
    # Drupal 8 root.
    if [ -f $current_dir/index.php ] && [ -f $current_dir/core/includes/bootstrap.inc ]; then
      drupal_root=$current_dir
      drupal_version=8
      break
    fi
    # Drupal 7 root.
    if [ -f $current_dir/index.php ] && [ -f $current_dir/includes/bootstrap.inc ]; then
      drupal_root=$current_dir
      drupal_version=7
      break
    fi
    current_dir=$(dirname $current_dir)
  done

  if [ -z $1 ]; then
    cd $drupal_root
    return 0;
  fi

  local dirs='sites sites/all sites/default'
  [ $drupal_version = 8 ] && dirs="$dirs modules themes profiles modules/contrib modules/custom profiles/modules profiles/modules/contrib profiles/modules/custom core/modules core/themes core/profiles" 
  [ $drupal_version = 7 ] && dirs="$dirs sites/all/modules sites/all/modules/contrib sites/all/modules/custom sites/all/modules/features sites/all/themes modules themes profiles profiles/modules profiles/modules/contrib profiles/modules/custom profiles/modules/features" 
  dirs="$dirs ."

  for dir in $dirs; do
    if [ -d $drupal_root/$dir/$1 ]; then
      cd $drupal_root/$dir/$1
      return 0
    fi
  done

  echo "dcd: no such directory $1"
  return 1
}

function parse_git_branch {
   git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\[\1\]/' 
}

export PS1="\[\e[00;32m\]\u@\h\[\e[0m\]\[\e[00;34m\]:\[\e[0m\]\[\e[00;33m\]\w\[\e[0m\]\[\e[00;36m\]\$(parse_git_branch)\[\e[0m\]\n\[\e[01;30m\]$ \[\e[0m\]"

alias drupalcs="phpcs --colors --standard=Drupal --extensions='php,module,inc,install,test,profile,theme,js,css,info,txt'"

echo -e "\e[96mWELCOME TO DRUPAL LEMP DEVELOPMENT STACK!\e[0m"

cd /var/www
