#!/bin/bash

diff <(apm list --bare --installed | sort | grep .) <(grep . ~/.atom/packages-file)
