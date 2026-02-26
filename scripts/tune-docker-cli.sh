#!/usr/bin/env bash
set -euo pipefail

CONFIG_DIR="${DOCKER_CONFIG:-$HOME/.docker}"
CONFIG_FILE="$CONFIG_DIR/config.json"

mkdir -p "$CONFIG_DIR"

if [[ ! -f "$CONFIG_FILE" ]]; then
  printf '{}\n' > "$CONFIG_FILE"
fi

backup_file="$CONFIG_FILE.bak.$(date +%Y%m%d_%H%M%S)"
cp "$CONFIG_FILE" "$backup_file"

tmp_file="$(mktemp)"
jq '
  .features = (
    (.features // {}) |
    if type == "object" then
      with_entries(.value |= (if type == "string" then . else tostring end))
    else
      {}
    end |
    . + {buildkit: "true"}
  ) |
  .detachKeys = "ctrl-],ctrl-]" |
  .experimental = (.experimental // "enabled")
' "$CONFIG_FILE" > "$tmp_file"
mv "$tmp_file" "$CONFIG_FILE"

echo "Updated Docker CLI config: $CONFIG_FILE"
echo "Backup created: $backup_file"
echo "Current Docker tuning:"
jq '{features,detachKeys,experimental}' "$CONFIG_FILE"
