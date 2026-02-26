#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLI_TUNE_SCRIPT="$ROOT_DIR/scripts/tune-docker-cli.sh"
DESKTOP_TUNE_SCRIPT="$ROOT_DIR/scripts/tune-docker-desktop-macos.sh"

TMP_HOME="$(mktemp -d)"
trap 'rm -rf "$TMP_HOME"' EXIT

echo "Testing Docker CLI tuning..."
DOCKER_CONFIG="$TMP_HOME/.docker" HOME="$TMP_HOME" "$CLI_TUNE_SCRIPT"

CONFIG_FILE="$TMP_HOME/.docker/config.json"
[[ -f "$CONFIG_FILE" ]] || {
  echo "FAIL: Docker config not created"
  exit 1
}

jq -e '.features.buildkit == "true"' "$CONFIG_FILE" > /dev/null
jq -e '.detachKeys == "ctrl-],ctrl-]"' "$CONFIG_FILE" > /dev/null

echo "Testing Docker Desktop tuning script..."
if [[ "$(uname -s)" == "Darwin" ]]; then
  mkdir -p "$TMP_HOME/Library/Group Containers/group.com.docker"
  SETTINGS_FILE="$TMP_HOME/Library/Group Containers/group.com.docker/settings-store.json"
  cat > "$SETTINGS_FILE" << 'EOF'
{
  "Cpus": 2,
  "MemoryMiB": 2048,
  "SwapMiB": 1024,
  "AutoPauseTimeoutSeconds": 1800,
  "UseVirtualizationFramework": true,
  "UseVirtualizationFrameworkVirtioFS": false,
  "UseGrpcfuse": true,
  "UseContainerdSnapshotter": false,
  "EnableCLIHints": true,
  "OpenUIOnStartupDisabled": false,
  "AnalyticsEnabled": true
}
EOF

  HOME="$TMP_HOME" \
    DOCKER_DESKTOP_SETTINGS_FILE="$SETTINGS_FILE" \
    DOCKER_TUNE_TOTAL_CPUS=12 \
    DOCKER_TUNE_TOTAL_MEM_MIB=32000 \
    "$DESKTOP_TUNE_SCRIPT"

  jq -e '.AutoPauseTimeoutSeconds == 0' "$SETTINGS_FILE" > /dev/null
  jq -e '.Cpus == 8' "$SETTINGS_FILE" > /dev/null
  jq -e '.MemoryMiB == 17600' "$SETTINGS_FILE" > /dev/null
  jq -e '.SwapMiB == 4400' "$SETTINGS_FILE" > /dev/null
  jq -e '.UseVirtualizationFramework == true' "$SETTINGS_FILE" > /dev/null
  jq -e '.UseVirtualizationFrameworkVirtioFS == true' "$SETTINGS_FILE" > /dev/null
  jq -e '.UseGrpcfuse == false' "$SETTINGS_FILE" > /dev/null
  jq -e '.UseContainerdSnapshotter == true' "$SETTINGS_FILE" > /dev/null
  jq -e '.EnableCLIHints == false' "$SETTINGS_FILE" > /dev/null
  jq -e '.OpenUIOnStartupDisabled == true' "$SETTINGS_FILE" > /dev/null
else
  HOME="$TMP_HOME" "$DESKTOP_TUNE_SCRIPT"
fi

echo "Docker tuning tests passed."
