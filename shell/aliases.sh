# Use colors in coreutils utilities output
# alias ls='ls --color=auto'
alias grep='grep --color'

# Aliases to protect against overwriting
alias cp='cp -i'
alias mv='mv -i'

# Update dotfiles
dfu() {
  (
    cd ~/.dotfiles && git pull --ff-only && ./install -q
  )
}

# Jump to directory containing file
jump() {
  cd "$(dirname ${1})"
}

# Check if a file contains non-ascii characters
nonascii() {
  LC_ALL=C grep -n '[^[:print:][:space:]]' "${1}"
}

# Mirror stdout to stderr, useful for seeing data going through a pipe
alias peek='tee >(cat 1>&2)'
