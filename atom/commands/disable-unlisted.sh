#!/bin/bash

diff <(apm list --bare --installed | sort | grep .) <(grep . ~/.atom/packages-file) \
  | grep '^<' \
  # Delete the diff prefix and the version pendant.
  | sed '/^< /s///; /@.*$/ s///' \
  | xargs apm disable
