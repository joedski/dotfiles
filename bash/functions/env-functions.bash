#!/bin/bash


# A couple of useful env-centric functions.


function envfilehelpdescription() {
  cat <<USAGE_TEXT
Env File:
  The env file format expected is simple:

    - Each line is processed like so:
      - Any line beginning with the hash symbol "#" is treated as a comment
        and ignored.  Note that there can be no leading whitespace.
      - Any line that looks like KEY=VALUE is treated as an assignment
        and is used to set an env var.
        - Note the lack of spaces around the "=".
        - Note that no escaping or quoting occurs.  Everything after the "="
          is taken as the literal value of the var.
      - Any other line is ignored.

  The env file is not a shell script, and should not be expected to be
  "source"d.

Env File Example:

# Here is an env file with three vars.
FIRST=The first value.  It can have spaces.
SECOND=Any "Quotes" will show up literally.
THIRD=No \$var substitution takes place.
USAGE_TEXT
}


function env-exportfile() {
  if [[ ! -n $1 ]]; then
    cat <<USAGE_TEXT
Function that exports KEY=VALUE pairs into the current shell environment.

Usage:
  env-exportfile <envfile>

Options:
  <envfile>
    Path to a file with KEY=VALUE lines.  See below for a description
    of the expected file format.  Any line that causes an error will
    abort execution.  This can leave some env vars in the environment.

$(envfilehelpdescription)

USAGE_TEXT
    return 0
  fi

  if [[ ! -f $1 ]]; then
    echo "Cannot find envfile '$1'"
    return 1
  fi

  local envfile=$1
  local export_return=0

  while IFS='' read -r l <&42 || [[ -n $l ]]; do
    # Skip empties
    # Skip comment-lines
    # Skip lines that aren't assignment-like
    # ... it's not the most thorough.
    if [[ -n $l && $l != "#"* && $l == *=* ]]; then
      export "$l"
      export_return=$?
      if [[ $export_return -ne 0 ]]; then
        return $export_return
      fi
    fi
  done 42< "$envfile"
}


function env-execwithfile() {
  if [[ ! -n $1 ]]; then
    cat <<USAGE_TEXT
Function that loads an env file with the "env-exportfile" function in a subshell
then executes the given command in that same subshell, with those loaded
env vars.

Useage:
  env-execwithfile <envfile> <cmd> [...cmdargs]

Options:
  <envfile>
    Path to a file with KEY=VALUE lines.  See below for a description
    of the expected file format.

  <cmd> [...cmdargs]
    Command to run, with optional args.

$(envfilehelpdescription)

Other Notes:

  If you just need to specify env vars on the command line, it's more
  efficient to use the "env" command directly, like:

    env FOO="foo value" BAR="bar value" some-cmd-here arg arg arg

  Shells like Bash support doing this without the "env" command, just
  the leading assignments.

USAGE_TEXT
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
    env-exportfile "$1"
    env-exportfile_return=$?
    if [[ $env-exportfile_return -eq 0 ]]; then
      shift
      "$@"
    else
      exit $env-exportfile_return
    fi
  )

  return $?
}
