#!/bin/bash
set -euo pipefail

# Installs packages not yet installed, but which are listed in the list.

# NOTE: Package names do not have spaces, so this is fine.
for x in $(bash ~/.atom/commands/diff-packages.sh -V --left listed installed); do
  apm install "$x"
done
