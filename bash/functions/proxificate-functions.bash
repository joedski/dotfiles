#!/bin/bash

# Functions around convenience-setting of proxy env vars.
# Tested in bash 3.2.57


function proxificate() {
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

  set-env [env]
    Export the env vars of the stated env into the current environment.
    If no env is stated, then use whatever is specified in
    the ~/.proxificate/default-env file.

  exec <env> <command> {...command-args}
    Load a subshell with the env vars of the stated env then run the given
    command in that subshell.

  sync-utils [env]
    Synchronize utility settings with the env vars in the given env.
    If no env is stated, then use whatever is specified in
    the ~/.proxificate/default-env file.

    See \`proxificate help sync-utils\` for more.

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

    ( init | set-env | exec | sync-utils )
      ;;

    ( * )
      echo "Unrecognized command '${p_command}'"
      return 1
      ;;
  esac

  "proxificate-${p_command}" "${p_command_args[@]}"
}



function proxificate-init() {
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
    echo "~/.proxificate/envs exists, but is not a directory.  Aborting."
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

- Lines starting with a hash \`#\` are ignored.
- Lines not so-ignored that contain an equals sign \`=\` are treated as an
  env var assignment.
    - Do not put spaces around the \`=\`, spaces are treated literally.
    - Values are read literally, no escaping or quoting occurs.  Any escapes or
      quotes will appear literally in the value.
    - Multi-line values are not supported.
    - Variable substitution does not occur.
- Any other lines are ignored.

Env files can set any env vars, but should set at least the following:

- \`PROXIFICATE_ENV_DESCRIPTION\` which is used by \`proxificate list\`
  to give a short description of this env.
- \`PROXIFICATE_STRICT_SSL\` whether or not utilities such as \`git\`,
  \`npm\`, or \`yarn\` should enable or disable \`strict-ssl\`.
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
NO_PROXY=api.example.com,internal.example.com
\`\`\`
PROXIFICATE_ENVS_README
  fi

  if [[ -d ~/.proxificate/sync-utils ]]; then
    echo "~/.proxificate/sync-utils already exists."
    echo "If you need to recreate the default scripts, remove or rename the sync-utils dir and rerun \`proxificate init\`."
  elif [[ -e ~/.proxificate/sync-utils ]]; then
    echo "~/.proxificate/sync-utils exists, but is not a directory.  Aborting."
  else
    mkdir ~/.proxificate/sync-utils
    echo "created ~/.proxificate/sync-utils/"
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
    echo "created default script ~/.proxificate/sync-utils/git.bash"
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
    echo "created default script ~/.proxificate/sync-utils/npm.bash"
    cat > ~/.proxificate/sync-utils/yarn.bash <<PROXIFICATE_INIT_SYNC_YARN
#!/bin/bash
# Sync yarn

if hash yarn 2>/dev/null; then
  if [[ -n \$HTTP_PROXY ]]; then
    echo yarn config set proxy \\""\$HTTP_PROXY"\\" --global
    yarn config set proxy "\$HTTP_PROXY" --global
  else
    echo yarn config rm proxy --global
    yarn config rm proxy --global
  fi

  if [[ -n \$HTTPS_PROXY ]]; then
    echo yarn config set https-proxy \\""\$HTTPS_PROXY"\\" --global
    yarn config set https-proxy "\$HTTPS_PROXY" --global
  else
    echo yarn config rm https-proxy --global
    yarn config rm https-proxy --global
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
    echo "created default script ~/.proxificate/sync-utils/yarn.bash"
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
    echo "created default script ~/.proxificate/sync-utils/apm.bash"
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
    echo "created default script ~/.proxificate/sync-utils/apm.bash"
    echo "Please review the created scripts and remove any you do not need."
  fi
}
