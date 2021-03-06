#!/bin/bash

INPUT=$1

function show-help() {
  cat <<HELP

Usage

  git set-user
  git set-user --list
  git set-user -l
    see available users

  get set-user <search>
    set a user by search text

Important Files

  The following files are checked for user names:

    - ~/.gituserlist
    - ~/.gituserlist.local

  The .gituserlist.local file is optional, but recommended.

  These files should on each line have a name and email pair
  in the format of:

    \${NAME} <\${EMAIL}>

  For example, 2 entries:

    Joseph Sikorski <joedski@gmail.com>
    Joe Sikorski <joe@somewhere.com>

  NOTE: No escaping occurs, all characters will be used
  literally as entered.

HELP
}

function get-user-list() {
  if [[ ! -f ~/.gituserlist ]]; then
    echo "~/.gituserlist not found"
    exit 1
  fi

  USER_LIST=$(
    diff <(sort ~/.gituserlist | grep .) <(sort ~/.gituserlist.local 2>/dev/null | grep .) \
      | grep -E '^[><] ' \
      | sed -E 's/^[><] //'
  )
}

function list-users() {
  get-user-list

  echo "Users:"
  echo "$USER_LIST" | sed 's/^/ - /'
}

if [[ -z "$INPUT" ]]; then
  list-users
  echo
  echo 'Use -h for help.'
  exit 0
fi

if [[ "$INPUT" = '--help' || "$INPUT" = '-h' ]]; then
  show-help
  exit 0
fi

if [[ "$INPUT" = '--list' || "$INPUT" = '-l' ]]; then
  list-users
  exit 0
fi

get-user-list

USER_ENTRY=$(echo "$USER_LIST" | grep -s "$INPUT")

# echoing an empty string without -n is treated as 1 line by wc,
# so just directly testing if it's empty.
if [[ -z "$USER_ENTRY" ]]; then
  echo 'No matching user entries'
  exit 1
fi

USER_ENTRY_COUNT=$(echo "$USER_ENTRY" | wc -l | sed -E 's/^ +//; s/ +$//')

if [[ $USER_ENTRY_COUNT -ne 1 ]]; then
  echo 'Ambiguous search matched more than 1 user:'
  echo "$USER_ENTRY" | sed 's/^/- /'
  exit 1
fi

USER_ENTRY_NAME=$(echo "$USER_ENTRY" | sed -E 's/ +<[^<>]*>$//')
USER_ENTRY_EMAIL=$(echo "$USER_ENTRY" | sed -E 's/.* +<([^<>]*)>$/\1/')

echo "git config user.name \"$USER_ENTRY_NAME\""
echo "git config user.email \"$USER_ENTRY_EMAIL\""
git config user.name "$USER_ENTRY_NAME"
git config user.email "$USER_ENTRY_EMAIL"
echo 'done!'
