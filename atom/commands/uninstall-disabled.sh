#!/bin/bash

DIFF_PACKAGES=~/.atom/commands/diff-packages.sh

# diff <(apm list --bare --installed | sort | grep .) <(apm list --bare --installed --enabled | sort | grep .) \
$DIFF_PACKAGES installed enabled \
  | grep '^<' \
  | sed '/^< /s///; /@.*$/s///' \
  | xargs apm uninstall
