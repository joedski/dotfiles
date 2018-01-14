# TODO: Is there a more performant option?
if [ -f "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh" ]; then
  __GIT_PROMPT_DIR=$(brew --prefix)/opt/bash-git-prompt/share
  source "$(brew --prefix)/opt/bash-git-prompt/share/gitprompt.sh"

  # Tell gitprompt not to fetch the remote status every so often so that
  # password-protected rsa_id files don't pop up the password question
  # in the terminal prmopt.
  GIT_PROMPT_FETCH_REMOTE_STATUS=0
else
  echo "Install bash-git-prompt with: brew install bash-git-prompt"
  echo "See https://github.com/magicmonty/bash-git-prompt for details."
fi
