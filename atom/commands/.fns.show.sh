# LIB: Helper functions for showing things.

function describe-lists() {
  cat <<DESCRIBE_LISTS
  - installed
      Packages that are currently installed, regardless of status.

  - not-installed
      Packages listed in packages-file but not installed.

  - enabled
      Packages that are installed and enabled.

  - disabled
      Packages that are installed but disabled.

  - listed
      Packages that are listed in packages-file, regardless of other status.
DESCRIBE_LISTS
}

function show-enabled() {
  apm list --bare --installed --enabled | sort | grep .
}

function show-listed() {
  grep . ~/.atom/packages-file
}

function show-installed() {
  apm list --bare --installed | sort | grep .
}

function show-disabled() {
  diff <(show-installed) <(show-enabled) \
  | grep '^<' \
  | sed '/^< /s///; /@.*$/s///'
}

function show-not-installed() {
  diff <(show-listed) <(show-installed) \
  | grep '^<' \
  | sed '/^< /s///; /@.*$/s///'
}
