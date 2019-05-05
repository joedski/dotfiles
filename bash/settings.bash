HISTSIZE=1048576
HISTFILE="$HOME/.bash_history"
SAVEHIST=$HISTSIZE
shopt -s histappend # append to history file

export EDITOR=vim

PYTHON_2_USER_BASE=$(python -c 'import site; print(site.USER_BASE)')
export PATH="${PATH}:${PYTHON_2_USER_BASE}/bin"

if which python3 > /dev/null; then
  PYTHON_3_USER_BASE=$(python3 -c 'import site; print(site.USER_BASE)')
  export PATH="${PATH}:${PYTHON_3_USER_BASE}/bin"
fi
