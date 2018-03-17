#!/bin/bash

# Update the packages file to list the currently installed and enabled packages.

apm list --bare --installed | sort | grep . > ~/.atom/packages-file
