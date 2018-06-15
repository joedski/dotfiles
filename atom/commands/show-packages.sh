#!/bin/bash
set -euo pipefail

# Usage: diff-packages.sh <list-a> <list-b>

source ~/.atom/commands/.fns.show.sh

function usage() {
  cat <<USAGE

  usage: show-packages.sh <list>

lists:

$(describe-lists)

USAGE
}

function allow-args() {
  case $1 in
    ( enabled | disabled | listed | installed | not-installed )
      echo $1
      ;;

    ( * )
      echo "'$1' is not a valid list."
      exit 1
      ;;
  esac
}



if [[ $# -lt 1 ]]; then
  usage
  exit 0
fi

LIST_NAME=$(allow-args $1)

show-$LIST_NAME
