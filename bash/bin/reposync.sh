#!/bin/bash

# reposync - Simple way to sync repos in a folder.

function reposync_help() {
  cat <<REPOSYNC_HELP
List or pull git repos in a dir.

  reposync list <dir>
  reposync sync <repos-file>

Command: \`reposync list <dir>\`
Outputs a repos file with a list of each git repo found in <dir>.

Command: \`reposync sync <repos-file>\`
Creates the repos dir for the given file if it doesn't exist, then
clones each repo if they don't exist, creating any parent dirs if necessary.

Note that will skip any lines prefixed with a ! or #.

REPOSYNC_HELP
}

function reposync_list() {
  local TARGET=$1

  if [ ! "$TARGET" ]; then
    echo "Usage: reposync list <dir>"
    exit 1
  fi

  if [ ! -d "$TARGET" ]; then
    echo "'$TARGET' is not a directory!"
    exit 1
  fi

  if [ "$TARGET" != '.' ]; then
    pushd "$TARGET" > /dev/null
  fi

  OIFS="$IFS"
  IFS=$'\n'
  local TARGETS_GIT=($(find . -name '.git' -type d))
  IFS="$OIFS"

  local TARGETS_DIR=()
  local TD
  local TORIGIN

  if [ ! "${TARGETS_GIT[*]}" ]; then
    echo "No git repositories found in '$TARGET'!"
    if [ "$TARGET" != '.' ]; then
      popd > /dev/null
    fi
    return
  fi

  for T in "${TARGETS_GIT[@]}"; do
    TD=${T%/.git}
    pushd "$TD" > /dev/null
    TORIGIN=$(git remote -v \
      | grep '^origin' \
      | grep '(fetch)' \
      | sed '/^origin'$'\t''/ s///; /[ ]*(fetch)/ s///')
    TARGETS_DIR=("${TARGETS_DIR[@]}" "$TD <-- $TORIGIN")
    popd > /dev/null
  done

  echo "TARGET=$TARGET"
  for T in "${TARGETS_DIR[@]}"; do
    echo "$T"
  done

  if [ "$TARGET" != '.' ]; then
    popd > /dev/null
  fi
}

function reposync_sync() {
  echo "
  NOTE: Some repositories may request credentials or require ssh key authorization!
"

  local REPOS_FILE=$1
  local TARGETS_DIR=()
  local TAGRET

  if [ ! -f $REPOS_FILE ]; then
    echo "'$REPOS_FILE' is not a file."
    return
  fi

  local LINE
  while read -r LINE; do
    case "$LINE" in
      ( TARGET=* )
        TARGET="${LINE#TARGET=}"
        ;;

      # Skip negated lines.
      ( !* )
        ;;

      # Skip comment lines.
      ( \#* )
        ;;

      ( * )
        TARGETS_DIR=("${TARGETS_DIR[@]}" "$LINE")
        ;;
    esac
  done < "$REPOS_FILE"

  if [ "$TARGET" != '.' ]; then
    pushd "$TARGET" > /dev/null
  fi

  local T
  local TDIR
  local TDIRDIR
  local TORIGIN
  for T in "${TARGETS_DIR[@]}"; do
    TDIR="${T% <-- *}"
    TORIGIN="${T#* <-- }"

    echo "Repo: $T"

    if [ -d "$TDIR" ]; then
      echo "Already exists; skipping."
      echo
      continue
    fi

    TDIRDIR=$(dirname "$TDIR")

    # Only try to make the parent if it's not the current dir.
    if [ "$TDIRDIR" != '.' ]; then
      mkdir -p "$TDIRDIR"
    fi

    git clone "$TORIGIN" "$TDIR"

    # Add an empty line to make things easier to distinguish.
    echo
  done

  if [ "$TARGET" != '.' ]; then
    popd > /dev/null
  fi
}

case $1 in
  ( list )
    reposync_list $2
    ;;

  ( sync )
    reposync_sync $2
    ;;

  ( help | --help | -h )
    reposync_help
    ;;

  ( '' )
    echo "Please enter a command."
    echo
    reposync_help
    ;;

  ( * )
    echo "'$1' is not a valid command."
    ;;
esac
