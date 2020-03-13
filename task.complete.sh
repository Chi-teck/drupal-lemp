# BASH completion script for Task.
_task_completion() {

  # Complete only fist argument.
  if [[ $COMP_CWORD -gt 1 ]]; then
    return 0
  fi

  local TASKS
  if ! TASKS=$(task -l 2> /dev/null); then
    return 1
  fi

  SUGGESTIONS=$(echo "$TASKS" | sed '1d; s/://' | awk '{ print $2 }')

  local CUR="${COMP_WORDS[COMP_CWORD]}"
  COMPREPLY=( $(compgen -W "$SUGGESTIONS" -- "$CUR") );
}
complete -F _task_completion task
