#!/bin/bash

# Update the packages file to list the currently installed and enabled packages.

SHOW_PACKAGES=~/.atom/commands/show-packages.sh

$SHOW_PACKAGES installed > ~/.atom/packages-file
