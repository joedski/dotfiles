#!/bin/bash

DIFF_PACKAGES=~/.atom/commands/diff-packages.sh

$DIFF_PACKAGES -V installed listed \
  | grep '^<' \
  | sed '/^< /s///; /@.*$/ s///' \
  | xargs apm disable

$DIFF_PACKAGES -V installed listed \
  | grep '^>' \
  | sed '/^> /s///; /@.*$/ s///' \
  | xargs apm enable
