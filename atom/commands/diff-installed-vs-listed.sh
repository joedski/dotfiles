#!/bin/bash

diff <(apm list --bare --installed | sort | grep .) <(grep . packages-list)
