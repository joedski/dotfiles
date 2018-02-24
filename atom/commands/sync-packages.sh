#!/bin/bash

COMMANDS_PATH=~/.dotfiles/atom/commands

function docommand() {
  bash $COMMANDS_PATH/$1
}

docommand install-sync-to-packages-file.sh
docommand disable-unlisted.sh
apm upgrade
