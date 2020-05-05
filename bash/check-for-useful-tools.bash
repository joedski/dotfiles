# Some commands I find useful.

# Everyone likes homebrew but the way it wants you to munge perms
# on /usr/local concerns me.

USEFUL_TOOLS=(
  brew
  ack
  ag
  jq
  tree
  docker-compose
  rustup
)

for x in "${USEFUL_TOOLS[@]}"; do
  type "$x" >/dev/null 2>&1 || echo "Missing useful tool: ${x}"
done
