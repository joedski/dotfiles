#!/bin/bash

DIFF_PACKAGES=~/.atom/commands/diff-packages.sh

$DIFF_PACKAGES -V --left installed listed \
  | xargs apm disable

$DIFF_PACKAGES -V --left installed listed \
  | xargs apm enable
