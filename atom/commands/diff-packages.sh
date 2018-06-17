#!/bin/bash
set -euo pipefail

# Usage: diff-packages.sh <list-a> <list-b>

source ~/.atom/commands/.fns.show.sh

function usage() {
  cat <<USAGE

  usage: diff-packages.sh [--left | --right] [--ignore-versions] <list-left> <list-right>

options:

  --help | -h
    Show this usage information and exit.

  --left | -l
    Show only the left side of the diff.

  --right | -r
    Show only the right side of the diff.
    Identical to swapping the list args and passing --left

  --ignore-versions | -V
    Strip version numbers before diffing.

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

function optionally-ignore-versions() {
  if [[ -n $IGNORE_VERSIONS ]]; then
    sed '/@.*$/ s///'
  else
    cat
  fi
}

function show-diff() {
  diff <(show-$LIST_LEFT | optionally-ignore-versions) <(show-$LIST_RIGHT | optionally-ignore-versions)
}



SHOW_SIDE=both
LIST_LEFT=''
LIST_RIGHT=''
IGNORE_VERSIONS=''

if [[ $# -eq 0 ]]; then
  usage
  exit 0
fi

while [[ ! -z ${1+x} ]]; do
  case "$1" in
    ( --help | -h )
      usage
      exit 0
    ;;

    ( --left | -l )
      SHOW_SIDE='<'
    ;;

    ( --right | -r )
      SHOW_SIDE='>'
    ;;

    ( --ignore-versions | -V )
      IGNORE_VERSIONS=1
    ;;

    ( * )
      if [[ $LIST_RIGHT ]]; then
        echo "Too many lists; can only diff two lists"
      elif [[ $LIST_LEFT ]]; then
        LIST_RIGHT=$(allow-args $1)
      else
        LIST_LEFT=$(allow-args $1)
      fi
    ;;
  esac

  shift
done

if [[ -z $LIST_LEFT || -z $LIST_RIGHT ]]; then
  echo "You must specify two lists!"
  usage
  exit 1
fi

if [[ $SHOW_SIDE == 'both' ]]; then
  show-diff
elif [[ $SHOW_SIDE == '<' || $SHOW_SIDE == '>' ]]; then
  show-diff \
    | grep '^'"$SHOW_SIDE"'' \
    | sed '/^'"$SHOW_SIDE"' /s///'
else
  echo "Internal error: '${SHOW_SIDE}' is not a valid side"
  exit 1
fi
