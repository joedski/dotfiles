# Some commands I find useful.

USEFUL_TOOLS=(
  brew
  ack
  ag
  jq
  tree
  docker-compose
)

for x in "${USEFUL_TOOLS[@]}"; do
  type "$x" || echo "Missing useful tool: ${x}"
done
