#!/bin/bash

ST3_PATH_USER_CONFIG_LINUX=~/".config/sublime-text-3/Packages/User"
ST3_PATH_USER_CONFIG_OSX=~/"Library/Application Support/Sublime Text 3/Packages/User"

if [ -d ~/"Library/Application Support" ]; then
  ST3_PATH_USER_CONFIG=$ST3_PATH_USER_CONFIG_OSX
elif [ -d ~/".config" ]; then
  ST3_PATH_USER_CONFIG=$ST3_PATH_USER_CONFIG_LINUX
fi

if [ -z "$ST3_PATH_USER_CONFIG" ]; then
  echo "Unable to determine OS environment; not linking Sublime Text 3 User Config Dir."
  exit 1
elif [ -a "$ST3_PATH_USER_CONFIG" -a ! -L "$ST3_PATH_USER_CONFIG" ]; then
  echo "Sublime Text 3 User Config Dir '$ST3_PATH_USER_CONFIG' exists and is not a symlink; backup and/or remove contents, rm dir, and try again."
  exit 2
else
  if [ -L "$ST3_PATH_USER_CONFIG" ]; then rm "$ST3_PATH_USER_CONFIG"; fi
  ln -sv ~/.dotfiles/sublime-text-3 "$ST3_PATH_USER_CONFIG"
fi

