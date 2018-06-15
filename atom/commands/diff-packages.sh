#!/bin/bash
set -euo pipefail

# Usage: diff-packages.sh <list-a> <list-b>

source ~/.atom/commands/.fns.show.sh

function usage() {
  cat <<USAGE

  usage: diff-packages.sh <list-left> <list-right>

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



if [[ $# -lt 2 ]]; then
  usage
  exit 0
fi

LIST_LEFT=$(allow-args $1)
LIST_RIGHT=$(allow-args $2)

diff <(show-$LIST_LEFT) <(show-$LIST_RIGHT)
