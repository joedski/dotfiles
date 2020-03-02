#!/bin/bash

# Functions around convenience-setting of proxy env vars.
# This grew to far bigger than I thought it would, and is probably
# a bit overkill.  Oh well.
# Tested in bash 3.2.57

# To start, source this file somewhere in your bashrc/bash_profile,
# then run 'proxificate init'.
# Run 'proxificate help' for help.



proxificate() {
  local p_command=
  local p_command_args=()
  local p_show_help=

  while [[ ${#@} -ne 0 ]]; do
    case "$1" in
      ( help | -h | --help )
        # If we have a sub-command, treat this flag as a flag
        # to that sub-command.
        if [[ -n $p_command ]]; then
          p_command_args=( "${p_command_args[@]}" "$1" )
          shift
        else
          p_show_help=1
          shift
        fi
        ;;

      ( * )
        if [[ -z $p_command ]]; then
          p_command=$1
          shift

          # Support "proxificate help $CMD" syntax
          if [[ $p_show_help ]]; then
            p_show_help=
            p_command_args=( "${p_command_args[@]}" "--help" )
          fi
        else
          p_command_args=( "${p_command_args[@]}" "$1" )
          shift
        fi
        ;;
    esac
  done

  if [[ -z $p_command ]]; then
    if [[ -n $p_show_help ]]; then
      cat <<PROXIFICATE_DISPATCH_HELP

Manage proxy env vars.

Usage:

  proxificate <command> {...command-args}
    Execute a proxificate command.

  proxificate help
    Show this message.

  proxificate help <command>
  proxificate <command> --help
    Show help for the given <command>

Available Commands:

  init
    Initializes proxificate.

  list
  ls
  l
    List the envs available in the ~/.proxificate/envs/ dir.

  set-env {--quiet} [env]
    Export the env vars of the stated env into the current environment.
    If no env is stated, then use whatever is specified in
    the ~/.proxificate/default-env file.

  exec (<env> | --default-env) <command> {...command-args}
    Load a subshell with the env vars of the stated env then run the given
    command in that subshell.  If you need to run a command that will change
    the env of the current shell, just use 'proxify set-env' and then your
    command, instead.

  sync-utils (<env> | --default-env | --current-env) [sync-script-name]
  sync-utils --list
    Synchronize utility settings with the env vars in the given env.

  current
    Show the currently set env.

Useful Files:

  ~/.proxificate/
    Configuration dir for proxificate.

  ~/.proxificate/default-env
    File whose first line names the default env.

  ~/.proxificate/envs/*.env
    Env files with env vars.

  ~/.proxificate/sync-utils/*
    Scripts to sync various utils to the current env.
    Only files flagged as executable will be run.

Limitations:

  Probably won't work quite as expected if you name an env '--default-env'
  or '--current-env'.

  Many of these are implemented as functions that open subshells, so they're
  not the most performant.  If you need to run many commands in a given env,
  open a new shell yourself, run 'proxificate set-env ...' there, then
  do your desired work.

  For scripts, just use a subshell:

    #!/usr/bin/env bash
    # stuff out here in a different env.
    (
      # stuff in here with a particular env.
      proxificate set-env "\${target_env_name}"
      dosomething
      doanotherthing
      for x in *; do
        allthethings "\$x"
      done
    )
    # back to a different env.

PROXIFICATE_DISPATCH_HELP
    else
      echo "No command given; see 'proxificate --help' for more."
    fi

    return 0
  fi

  case "$p_command" in
    ( l | ls | list )
      p_command=list
      ;;

    ( init | set-env | exec | sync-utils | current )
      ;;

    ( * )
      echo "Unrecognized command '${p_command}'"
      return 1
      ;;
  esac

  "proxificate-${p_command}" "${p_command_args[@]}"
}



proxificate-current() {
  if [[ -n $PROXIFICATE_ENV_NAME ]]; then
    if [[ -n $PROXIFICATE_ENV_DESCRIPTION ]]; then
      echo "Environment currently proxificated to: '$PROXIFICATE_ENV_NAME' - $PROXIFICATE_ENV_DESCRIPTION"
    else
      echo "Environment currently proxificated to: '$PROXIFICATE_ENV_NAME'"
    fi
  else
    echo "Environment not currently proxificated."
  fi
}



proxificate-list() {
  local env_file

  while [[ ${#@} -ne 0 ]]; do
    case "$1" in
      ( help | -h | --help )
        cat <<PROXIFICATE_INIT_HELP

List the envs available.

Usage:

  proxificate list
    List the envs available in '~/.proxificate/envs/'.

  proxificate list --help
  proxificate help list
    Shows this message.

PROXIFICATE_INIT_HELP
        return 0
        ;;

      ( * )
        shift
        ;;
    esac
  done

  if [[ ! -d ~/.proxificate || ! -d ~/.proxificate/envs ]]; then
    echo "Could not find ~/.proxificate/envs/; have you run 'proxificate init' yet?"
    return 1
  fi

  echo "Available envs:"
  for env_file in ~/.proxificate/envs/*.env; do
    if [[ -f $env_file ]]; then
      (
        proxificate-set-env -q -q "$(basename "$env_file")"
        echo " - $(basename "${env_file%.env}") - $PROXIFICATE_ENV_DESCRIPTION"
      )
    else
      echo "(none)"
    fi
  done
}



proxificate-sync-utils() {
  local p_env_use
  local p_env_name
  local p_script_use

  while [[ ${#@} -ne 0 ]]; do
    case "$1" in
      ( help | -h | --help )
        cat <<PROXIFICATE_INIT_HELP

Synchronizes utils to the current env by running all executable scripts in
the dir '~/.proxificate/sync-utils/'.

Usage:

  proxificate sync-utils (<env> | --default-env | --current-env)
    Run all the sync-utils scripts.
    You must specify one of <env>, --default-env, or --current-env.

  proxificate sync-utils (<env> | --default-env | --current-env) <util-name>
    Run only the named util sync script.

  proxificate sync-utils --help
  proxificate help sync-utils
    Shows this message.

  proxificate sync-utils -l
  proxificate sync-utils --list
    Shows a list of all the sync utils available, and which will be executed
    by default.

Options:

  <env>
    Sync utils to the named env's vars.

  -d | --default-env
    Sync utils to the vars of the env named in
    the '~/.proxificate/default-env' file.

  -c | --current-env
    Sync utils to the vars of the current shell's env.

PROXIFICATE_INIT_HELP
        return 0
        ;;

      ( -l | -ls | --ls | --list )
        if [[ ! -d ~/.proxificate/sync-utils ]]; then
          echo "Dir '~/.proxificate/sync-utils' does not exist.  Have you run 'proxificate init' yet?"
          return 1
        fi

        for s in ~/.proxificate/sync-utils/*; do
          if [[ ! -e "$s" ]]; then
            echo "No files found in '~/.proxificate/sync-utils'."
            break
          fi

          if [[ -x "$s" ]]; then
            echo " - $(basename "$s")"
          fi
        done

        return 0
        ;;

      ( -d | --default-env )
        if [[ -z $p_env_name && -z $p_env_use ]]; then
          p_env_use=default
          shift
        else
          echo "Please specify only either '--default-env', '--current-env', or an env name."
          return 1
        fi
        ;;

      ( -c | --current-env )
        if [[ -z $p_env_name && -z $p_env_use ]]; then
          p_env_use=current
          shift
        else
          echo "Please specify only either '--default-env', '--current-env', or an env name."
          return 1
        fi
        ;;

      ( * )
        if [[ -z $p_env_name && -z $p_env_use ]]; then
          p_env_name="$1"
          shift
        elif [[ -z $p_script_use ]]; then
          p_script_use="$1"
          shift
        else
          echo "Please specify only either '--default-env', '--current-env', or an env name."
          return 1
        fi
        ;;
    esac
  done

  if [[ ! -d ~/.proxificate/sync-utils ]]; then
    echo "Could not find '~/.proxificate/sync-utils'.  Have you run 'proxificate init' yet?"
    return 1
  fi

  if [[ -z $p_env_name && -z $p_env_use ]]; then
    echo "Please specify either '--default-env', '--current-env', or an env name.  See 'proxificate sync-utils --help' for more."
    return 1
  fi

  if [[ -n $p_script_use && ! -x ~/.proxificate/sync-utils/"$p_script_use" ]]; then
    echo "Could not find '~/.proxificate/sync-utils/$p_script_use'."
    return 1
  fi

  (
    if [[ -n $p_env_name ]]; then
      proxificate-set-env -q -q "$p_env_name" || exit $?
    elif [[ $p_env_use == "default" ]]; then
      proxificate-set-env -q -q || exit $?
    fi
    # else just use the current env.

    echo "Syncing utils to env '$PROXIFICATE_ENV_NAME'..."
    echo

    if [[ -n $p_script_use ]]; then
      echo "Running '$p_script_use'..."
      echo
      ~/.proxificate/sync-utils/"$p_script_use"
      echo
    else
      for s in ~/.proxificate/sync-utils/*; do
        if [[ -f $s && -x $s ]]; then
          echo "Running '$(basename "$s")'..."
          echo
          "$s"
          echo
        fi
      done
    fi
  )

  return $?
}



proxificate-exec() {
  local p_no_more_options
  local p_env_name
  local p_use_default_env
  local p_command
  local p_command_args

  while [[ ${#@} -ne 0 ]]; do
    case "$1" in
      ( help | -h | --help )
        cat <<PROXIFICATE_INIT_HELP

Execute a command in a subshell with env vars of the named env.

Usage:

  proxificate exec (<env> | --default-env) [--] <cmd> [...cmd-args]
    List the envs available in '~/.proxificate/envs/'.

  proxificate list --help
  proxificate help list
    Shows this message.

Options:

  -d | --default-env
    Use the default env.

  --
    Stop processing options, treat everything else as the command and args.

PROXIFICATE_INIT_HELP
        return 0
        ;;

      ( -- )
        p_no_more_options=1
        shift
        ;;

      ( -d | --default-env )
        if [[ -z $p_no_more_options ]]; then
          p_use_default_env=1
          shift
        else
          if [[ -z $p_command ]]; then
            p_command="$1"
            shift
          else
            p_command_args=( "${p_command_args[@]}" "$1" )
            shift
          fi
        fi
        ;;

      ( * )
        if [[ -z $p_no_more_options && -z $p_use_default_env && -z $p_env_name ]]; then
          p_env_name="$1"
          shift
        else
          if [[ -z $p_command ]]; then
            p_command="$1"
            shift
          else
            p_command_args=( "${p_command_args[@]}" "$1" )
            shift
          fi
        fi
        ;;
    esac
  done

  if [[ -z $p_command ]]; then
    echo "Please specify a command.  See 'proxificate exec --help' for more."
  fi

  (
    proxificate set-env -q -q "$p_env_name" || exit $?
    "$p_command" "${p_command_args[@]}"
  )

  return $?
}



proxificate-set-env() {
  local p_env_name
  local p_env_file_name
  local p_env_file_path
  local p_quietness=0

  while [[ ${#@} -ne 0 ]]; do
    case "$1" in
      ( help | -h | --help )
        cat <<PROXIFICATE_INIT_HELP

Export env vars into the current environment.

Usage:

  proxificate set-env [-q] [env]
    Sets env vars from the [env], where [env] is the name of an env
    file in ~/.proxificate/envs/.  Writing the ".env" file extension is
    optional, it will be automatically added if not present.

    NOTE: Specifying an empty name '' is the same as not specifying any
    env.  Both mean to use the Default Env, if any.

  proxificate set-env --help
  proxificate help set-env
    Shows this message.

Options:

  -q | --quiet
    Be quieter.  Can be specified multiple times, with the caveat that
    trying to specify it like '-qq' is not supported.  Use '-q -q'
    instead.

    No quietness/normal behavior:
      Prints out a message stating the env name and each assignment.

    --quiet:
      Prints out only a message stating the env name.

    --quiet --quiet:
      Prints nothing.

PROXIFICATE_INIT_HELP
        return 0
        ;;

      ( -q | --quiet )
        ((p_quietness = p_quietness + 1))
        shift
        ;;

      ( * )
        if [[ -n $p_env_name ]]; then
          echo "Please specify only one env name."
          return 1
        fi

        p_env_name=$1
        shift
        ;;
    esac
  done

  if [[ ! -d ~/.proxificate/envs ]]; then
    echo "Could not find ~/.proxificate/envs/; have you run 'proxificate init' yet?"
    return 1
  fi

  if [[ $p_env_name == -d || $p_env_name == --default-env ]]; then
    p_env_name=
  fi

  if [[ -z $p_env_name ]]; then
    if [[ ! -f ~/.proxificate/default-env ]]; then
      echo "No default-env is set.  To set a default-env, write the name of the desired env as the first line in the file '~/.proxificate/default-env'."
      echo "Example:"
      echo "  echo 'My-Env' > ~/.proxificate/default-env"
      return 1
    fi

    read -r p_env_name < ~/.proxificate/default-env

    if (($? != 0)); then
      echo "Could not read from '~/.proxificate/default-env'.  Please check to make sure the first line is the desired env name."
      return 1
    fi
  fi

  if [[ $p_env_name == *.env ]]; then
    p_env_file_name="${p_env_name%.env}"
  else
    p_env_file_name="$p_env_name"
  fi

  p_env_file_path="$HOME/.proxificate/envs/${p_env_file_name}.env"

  if [[ ! -f $p_env_file_path ]]; then
    echo "Unknown env name '$p_env_name'.  Check the spelling, or check 'proxificate list'."
    return 1
  fi

  if ((p_quietness <= 0)); then
    echo "Proxificating environment to '$p_env_file_name':"
  elif ((p_quietness <= 1)); then
    echo "Proxificating environment to '$p_env_file_name'."
  fi

  while IFS='' read -r l <&42 || [[ -n $l ]]; do
    # Skip empties
    # Skip comment-lines
    # Skip lines that aren't assignment-like
    # ... it's not the most thorough.
    if [[ -n $l && $l != "#"* && $l == *=* ]]; then
      export "$l" || return $?

      if ((p_quietness <= 0)); then
        echo "  $l"
      fi
    fi
  done 42< "$p_env_file_path"

  export PROXIFICATE_ENV_NAME="$p_env_name"
}



proxificate-init() {
  local p_dir=~/.proxificate

  while [[ ${#@} -ne 0 ]]; do
    case "$1" in
      ( help | -h | --help )
        cat <<PROXIFICATE_INIT_HELP

Initialize proxificate by creating the following:

- ~/.proxificate/ - Proxificate settings dir.
- ~/.proxificate/envs/ - Dir that stores available envs.
  - You'll put your various envs in here.
- ~/.proxificate/sync-utils/ - Dir that stores scripts to set the proxy
  settings in the various utils, such as git, npm, or yarn.
  - Add extra sync scripts here if you need to support other utils.

It will also create helpful readmes in those dirs.

Usage:

  proxificate init
    Initializes the dirs if they have not been already created.

  proxificate init --help
  proxificate help init
    Shows this message.

PROXIFICATE_INIT_HELP
        return 0
        ;;

      ( * )
        shift
        ;;
    esac
  done

  if [[ -d ~/.proxificate || -L ~/.proxificate ]]; then
    # NOTE: Treating symlinks as dirs.
    echo "~/.proxificate/ already exists."
  elif [[ -e ~/.proxificate ]]; then
    echo "~/.proxificate exists, but is not a directory.  Aborting."
    return 1
  else
    mkdir ~/.proxificate
    echo "created ~/.proxificate/"
    cat > ~/.proxificate/README.md <<PROXIFICATE_DIR_README
Proxificate Dir
===============

The settings dir for the \`proxificate\` function.

The main things in here:

- The optional \`default-env\` file, which contains the name of the env in
  the \`envs\` dir to load if no arguments are given
  to \`proxificate set-env\`.
- The \`envs\` dir, which contains a bunch of named environment var sets.
- The \`sync-utils\` dir, which contains a bunch of scripts, each of which
  syncs one util to the current \`HTTP_PROXY\`, \`HTTPS_PROXY\`, and
  \`PROXIFICATE_STRICT_SSL\` env vars.
    - If you need to sync more tools, you can duplicate one of the existing
      scripts and modify it to suit your needs.

If at any point you want to reset this whole dir, or just one of the sub dirs
simply \`rm -rf\` the dir and rerun \`proxificate init\`.



## Note for Mac Users: System-Wide Env Vars

If you want to set proxy vars system wide, use the \`launchctl\` command:

\`\`\`sh
launchctl setenv HTTP_PROXY "\$HTTP_PROXY"
launchctl setenv HTTPS_PROXY "\$HTTPS_PROXY"
\`\`\`

You may need to \`sudo\` these, and this will affect all processes and users,
not just you!
PROXIFICATE_DIR_README
  fi

  if [[ -d ~/.proxificate/envs ]]; then
    echo "~/.proxificate/envs/ already exists."
  elif [[ -e ~/.proxificate/envs ]]; then
    echo "~/.proxificate/envs exists, but is not a directory.  Skipping."
  else
    mkdir ~/.proxificate/envs
    echo "created ~/.proxificate/envs/; be sure to add some .env files there."
    cat > ~/.proxificate/envs/README.md <<PROXIFICATE_ENVS_README
Proxificate Env Files
=====================

Env files here should have names that end with \`.env\`.  Anything before that
file extension is taken as the name of that env, and the value of the
\`PROXIFICATE_ENV_DESCRIPTION\` var within that \`.env\` file is used as the
description of that env.

Env files used by \`proxificate\` are excruciatingly simple:

- Leading spaces are not removed.
- Lines starting with a hash \`#\` are ignored.
    - If a line begins with spaces then a hash, it's treated as not beginning
      with a hash because it begins with a space!
- Lines not so-ignored that contain an equals sign \`=\` are treated as an
  env var assignment.
    - Do not put spaces around the \`=\`, spaces are treated literally.
    - Do not put spaces in or around the var name.
    - Values are read literally, no escaping or quoting occurs.  Any escapes or
      quotes will appear literally in the value.
    - Multi-line values are not supported.
    - Variable substitution does not occur.
- Any other lines are ignored.

Env files can set any env vars, but should set at least the following:

- \`PROXIFICATE_ENV_DESCRIPTION\` which is used by \`proxificate list\`
  to give a short description of this env.
- \`PROXIFICATE_STRICT_SSL\` whether or not utilities such as \`npm\`, or
  \`yarn\` should enable or disable \`strict-ssl\`.
  Set to any value to enable \`strict-ssl\` or to empty/no value to disable it.
- \`HTTP_PROXY\`
- \`http_proxy\`
- \`HTTPS_PROXY\`
- \`https_proxy\`
- \`NO_PROXY\`

Example:

\`\`\`
PROXIFICATE_ENV_DESCRIPTION=The Example Company Main Proxy
# Sets strict-ssl to false in certain tools to enable MITM-mode.
# Some corporate proxies don't seem to handle certs well,
# which is why this is even an option.
PROXIFICATE_STRICT_SSL=
HTTP_PROXY=http://corporate.example.com:80
http_proxy=http://corporate.example.com:80
HTTPS_PROXY=http://corporate.example.com:80
https_proxy=http://corporate.example.com:80
NO_PROXY=api.example.com,internal.example.com,github.com
\`\`\`
PROXIFICATE_ENVS_README
  fi

  if [[ -d ~/.proxificate/sync-utils ]]; then
    echo "'~/.proxificate/sync-utils' already exists."
    echo "If you need to recreate the default scripts, remove or rename the sync-utils dir and rerun \`proxificate init\`."
  elif [[ -e ~/.proxificate/sync-utils ]]; then
    echo "~/.proxificate/sync-utils exists, but is not a directory.  Skipping."
  else
    mkdir ~/.proxificate/sync-utils
    echo "created '~/.proxificate/sync-utils/'"
    cat > ~/.proxificate/sync-utils/git.bash <<PROXIFICATE_INIT_SYNC_GIT
#!/bin/bash
# Sync git

if hash git 2>/dev/null; then
  # No strict-ssl setting?

  if [[ -n \$HTTP_PROXY ]]; then
    echo git config --global http.proxy \\""\$HTTP_PROXY"\\"
    git config --global http.proxy "\$HTTP_PROXY"
  else
    echo git config --global --unset http.proxy
    git config --global --unset http.proxy
  fi

  if [[ -n \$HTTPS_PROXY ]]; then
    echo git config --global http.proxy \\""\$HTTPS_PROXY"\\"
    git config --global http.proxy "\$HTTPS_PROXY"
  else
    echo git config --global --unset http.proxy
    git config --global --unset http.proxy
  fi
else
  echo "sync-utils/git: skipping: could not find git"
fi
PROXIFICATE_INIT_SYNC_GIT
    chmod u+x ~/.proxificate/sync-utils/git.bash
    echo "created default script '~/.proxificate/sync-utils/git.bash'"
    cat > ~/.proxificate/sync-utils/npm.bash <<PROXIFICATE_INIT_SYNC_NPM
#!/bin/bash
# Sync npm

if hash npm 2>/dev/null; then
  if [[ -n \$HTTP_PROXY ]]; then
    echo npm config set proxy \\""\$HTTP_PROXY"\\"
    npm config set proxy "\$HTTP_PROXY"
  else
    echo npm config rm proxy
    npm config rm proxy
  fi

  if [[ -n \$HTTPS_PROXY ]]; then
    echo npm config set https-proxy \\""\$HTTPS_PROXY"\\"
    npm config set https-proxy "\$HTTPS_PROXY"
  else
    echo npm config rm https-proxy
    npm config rm https-proxy
  fi

  if [[ -n \$PROXIFICATE_STRICT_SSL ]]; then
    echo npm config set strict-ssl true
    npm config set strict-ssl true
  else
    echo npm config set strict-ssl false
    npm config set strict-ssl false
  fi
else
  echo "sync-utils/npm: skipping: could not find npm"
fi
PROXIFICATE_INIT_SYNC_NPM
    chmod u+x ~/.proxificate/sync-utils/npm.bash
    echo "created default script '~/.proxificate/sync-utils/npm.bash'"
    cat > ~/.proxificate/sync-utils/yarn.bash <<PROXIFICATE_INIT_SYNC_YARN
#!/bin/bash
# Sync yarn

if hash yarn 2>/dev/null; then
  if [[ -n \$HTTP_PROXY ]]; then
    echo yarn config set proxy \\""\$HTTP_PROXY"\\" --global
    yarn config set proxy "\$HTTP_PROXY" --global
  else
    echo yarn config delete proxy --global
    yarn config delete proxy --global
  fi

  if [[ -n \$HTTPS_PROXY ]]; then
    echo yarn config set https-proxy \\""\$HTTPS_PROXY"\\" --global
    yarn config set https-proxy "\$HTTPS_PROXY" --global
  else
    echo yarn config delete https-proxy --global
    yarn config delete https-proxy --global
  fi

  if [[ -n \$PROXIFICATE_STRICT_SSL ]]; then
    echo yarn config set strict-ssl true --global
    yarn config set strict-ssl true --global
  else
    echo yarn config set strict-ssl false --global
    yarn config set strict-ssl false --global
  fi
else
  echo "sync-utils/yarn: skipping: could not find yarn"
fi
PROXIFICATE_INIT_SYNC_YARN
    chmod u+x ~/.proxificate/sync-utils/yarn.bash
    echo "created default script '~/.proxificate/sync-utils/yarn.bash'"
    cat > ~/.proxificate/sync-utils/apm.bash <<PROXIFICATE_INIT_SYNC_APM
#!/bin/bash
# sync Atom's package manager apm

if hash apm 2>/dev/null; then
  if [[ -n \$HTTP_PROXY ]]; then
    echo apm config set proxy \\""\$HTTP_PROXY"\\"
    apm config set proxy "\$HTTP_PROXY"
  else
    echo apm config rm proxy
    apm config rm proxy
  fi

  if [[ -n \$HTTPS_PROXY ]]; then
    echo apm config set https-proxy \\""\$HTTPS_PROXY"\\"
    apm config set https-proxy "\$HTTPS_PROXY"
  else
    echo apm config rm https-proxy
    apm config rm https-proxy
  fi

  if [[ -n \$PROXIFICATE_STRICT_SSL ]]; then
    echo apm config set strict-ssl true
    apm config set strict-ssl true
  else
    echo apm config set strict-ssl false
    apm config set strict-ssl false
  fi
else
  echo "sync-utils/apm: skipping: could not find apm; you may need to start Atom then rerun this script"
fi
PROXIFICATE_INIT_SYNC_APM
    chmod u+x ~/.proxificate/sync-utils/apm.bash
    echo "created default script '~/.proxificate/sync-utils/apm.bash'"
    echo "Please review the created scripts and remove any you do not need."
  fi
}
