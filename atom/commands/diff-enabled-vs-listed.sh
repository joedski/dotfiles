#!/bin/bash

diff <(apm list --bare --installed --enabled | sort | grep .) <(grep . ~/.atom/packages-file)
