#!/bin/bash

# A couple of useful env-centric functions.


function sourceenv() {
  if [[ ! -n $1 ]]; then
    cat <<<USAGE
Function that loads KEY=VALUE pairs into the current shell environment.

Useage:
  sourceenv <envfile>

Options:
  <envfile>
    Path to a file with KEY=VALUE lines.  Lines beginning with a "#" and empty
    lines will be ignored.  Quotes will be picked up literally, so don't use
    them unless you want quotes in the var values.
USAGE
    return 0
  fi

  if [[ ! -f $1 ]]; then
    echo "Cannot find envfile '$1'"
    return 1
  fi

  local envfile=$1

  while IFS='' read -r l <&42 || [[ -n $l ]]; do
    # Skip empties
    # Skip comment-lines
    # Skip lines that aren't assignment-like
    # ... it's not the most thorough.
    if [[ -n $l && $l != "#"* && $l == *=* ]]; then
      export "$l"
    fi
  done 42< "$envfile"
}


function runwithenv() {
  if [[ ! -n $1 ]]; then
    cat <<<USAGE
Function that loads an env file with the "sourceenv" function in a subshell
then executes the given command in that same subshell, with those loaded
env vars.

Useage:
  runwithenv <envfile> <cmd> [...cmdargs]

Options:
  <envfile>
    Path to a file with KEY=VALUE lines.  Lines beginning with a "#" and empty
    lines will be ignored.  Quotes will be picked up literally, so don't use
    them unless you want quotes in the var values.

  <cmd> [...cmdargs]
    Command to run, with optional args.
USAGE
    return 0
  fi

  if [[ ! -f $1 ]]; then
    echo "Cannot find envfile '$1'"
    return 1
  fi

  if [[ ! -n $2 ]]; then
    echo "No command given"
    return 1
  fi

  (
    sourceenv "$1"
    shift
    "$@"
  )
}
