#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "Docker Desktop tuning is only applicable on macOS; skipping."
  exit 0
fi

if ! command -v jq > /dev/null 2>&1; then
  echo "jq is required (install: brew install jq)"
  exit 1
fi

detect_settings_file() {
  local candidate
  for candidate in \
    "$HOME/Library/Group Containers/group.com.docker/settings-store.json" \
    "$HOME/Library/Group Containers/group.com.docker/settings.json"; do
    [[ -f "$candidate" ]] && {
      printf "%s" "$candidate"
      return 0
    }
  done
  return 1
}

SETTINGS_FILE="${DOCKER_DESKTOP_SETTINGS_FILE:-}"
if [[ -z "$SETTINGS_FILE" ]]; then
  SETTINGS_FILE="$(detect_settings_file || true)"
fi

if [[ -z "$SETTINGS_FILE" || ! -f "$SETTINGS_FILE" ]]; then
  echo "Docker Desktop settings file not found; skipping."
  exit 0
fi

logical_cpus="${DOCKER_TUNE_TOTAL_CPUS:-$(sysctl -n hw.logicalcpu)}"
mem_mib_total="${DOCKER_TUNE_TOTAL_MEM_MIB:-$(($(sysctl -n hw.memsize) / 1024 / 1024))}"

recommend_cpus() {
  local total="$1"
  local candidate
  if ((total <= 4)); then
    candidate=2
  elif ((total <= 8)); then
    candidate=$((total - 2))
  else
    candidate=$(((total * 2) / 3))
  fi

  local upper=$((total - 2))
  ((upper < 2)) && upper=2
  ((candidate > upper)) && candidate=$upper
  ((candidate > 16)) && candidate=16
  ((candidate < 2)) && candidate=2
  printf "%s" "$candidate"
}

recommend_mem_mib() {
  local total="$1"
  local candidate reserve=6144

  if ((total <= 8192)); then
    candidate=3072
  elif ((total <= 12288)); then
    candidate=4096
  elif ((total <= 16384)); then
    candidate=6144
  else
    candidate=$(((total * 55) / 100))
    if ((total - candidate < reserve)); then
      candidate=$((total - reserve))
    fi
  fi

  ((candidate > 49152)) && candidate=49152
  ((candidate < 3072)) && candidate=3072
  printf "%s" "$candidate"
}

recommend_swap_mib() {
  local mem="$1"
  local candidate=$((mem / 4))
  ((candidate < 1024)) && candidate=1024
  ((candidate > 8192)) && candidate=8192
  printf "%s" "$candidate"
}

recommended_cpus="${DOCKER_TUNE_CPUS:-$(recommend_cpus "$logical_cpus")}"
recommended_mem="${DOCKER_TUNE_MEMORY_MIB:-$(recommend_mem_mib "$mem_mib_total")}"
recommended_swap="${DOCKER_TUNE_SWAP_MIB:-$(recommend_swap_mib "$recommended_mem")}"

backup_file="$SETTINGS_FILE.bak.$(date +%Y%m%d_%H%M%S)"
cp "$SETTINGS_FILE" "$backup_file"

tmp_file="$(mktemp)"
jq \
  --argjson cpus "$recommended_cpus" \
  --argjson memory "$recommended_mem" \
  --argjson swap "$recommended_swap" \
  '
  if has("Cpus") then
    .Cpus = $cpus |
    .MemoryMiB = $memory |
    .SwapMiB = $swap |
    .AutoPauseTimeoutSeconds = 0 |
    .UseVirtualizationFramework = true |
    .UseVirtualizationFrameworkVirtioFS = true |
    .UseGrpcfuse = false |
    .UseContainerdSnapshotter = true |
    .EnableCLIHints = false |
    .OpenUIOnStartupDisabled = true |
    .AnalyticsEnabled = false
  else
    .cpus = $cpus |
    .memoryMiB = $memory |
    .swapMiB = $swap |
    .autoPauseTimeoutSeconds = 0 |
    .useVirtualizationFramework = true |
    .useVirtualizationFrameworkVirtioFS = true |
    .useGrpcfuse = false |
    .useContainerdSnapshotter = true |
    .enableCliHints = false |
    .openUIOnStartupDisabled = true |
    .analyticsEnabled = false
  end
  ' "$SETTINGS_FILE" > "$tmp_file"
mv "$tmp_file" "$SETTINGS_FILE"

echo "Updated Docker Desktop settings: $SETTINGS_FILE"
echo "Backup created: $backup_file"
echo "Host resources: logicalCpus=$logical_cpus memoryMiB=$mem_mib_total"
echo "Applied values: cpus=$recommended_cpus memoryMiB=$recommended_mem swapMiB=$recommended_swap autoPause=0"

if pgrep -x Docker > /dev/null 2>&1; then
  echo "Docker Desktop is running. Restart Docker Desktop to apply these settings."
fi
