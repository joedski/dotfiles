#!/bin/bash

diff <(apm list --bare --installed | sort | grep .) <(grep . ~/.atom/packages-file) \
  | grep '^<' \
  | sed '/^< /s///; /@.*$/ s///' \
  | xargs apm disable

diff <(apm list --bare --installed | sort | grep .) <(grep . ~/.atom/packages-file) \
  | grep '^>' \
  | sed '/^> /s///; /@.*$/ s///' \
  | xargs apm enable

