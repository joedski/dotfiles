#!/bin/bash

diff <(apm list --bare --installed | sort | grep .) <(apm list --bare --installed --enabled | sort | grep .) \
  | grep '^<' \
  | sed '/^< /s///; /@.*$/s///' \
  | xargs apm uninstall
