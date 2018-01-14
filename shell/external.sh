#### Python Settings

# pip should only run if there is a virtualenv currently activated
export PIP_REQUIRE_VIRTUALENV=true

# Cache pip-installed packages to avoid re-downloading
export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache

# Python startup file
export PYTHONSTARTUP=$HOME/.pythonrc


#### Node and NVM

export NVM_DIR="$HOME/.nvm"
# This loads nvm
if [ -s "$NVM_DIR/nvm.sh" ]; then
  source "$NVM_DIR/nvm.sh"
elif [ -s "/usr/local/opt/nvm/nvm.sh" ]; then
  # Check the other locaation.
  source "/usr/local/opt/nvm/nvm.sh"
else
  echo "$NVM_DIR/nvm.sh not found."
fi

# This loads nvm bash_completion
[ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"


#### Ruby and RVM

# Load RVM into a shell session *as a function*
[ -s "$HOME/.rvm/scripts/rvm" ] && source "$HOME/.rvm/scripts/rvm"
if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

# Add RVM to path.
PATH=$PATH:$HOME/.rvm/bin


#### Local bin

PATH=$PATH:~/bin
