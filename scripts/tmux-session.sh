#!/usr/bin/env bash
set -euo pipefail

mode="${1:-attach}"
session_raw="${2:-main}"
start_dir="${3:-$PWD}"

tmux_cmd=(tmux)
if [[ -n "${TMUX_SOCKET_NAME:-}" ]]; then
  tmux_cmd+=(-L "$TMUX_SOCKET_NAME")
fi

tm() {
  "${tmux_cmd[@]}" "$@"
}

sanitize_session_name() {
  local raw="$1"
  # Keep tmux-safe names while preserving readability.
  printf "%s" "$raw" | tr '[:space:]/:.' '----'
}

session_name="$(sanitize_session_name "$session_raw")"

session_exists() {
  tm has-session -t "$1" 2> /dev/null
}

bootstrap_session() {
  local s="$1"
  local dir="$2"

  tm new-session -d -s "$s" -c "$dir" -n editor
  tm new-window -d -t "$s:2" -n shell -c "$dir"
  tm select-window -t "$s:1"
}

attach_or_switch() {
  local s="$1"
  if [[ "${TMUX_SESSION_NO_ATTACH:-0}" == "1" ]]; then
    return
  fi
  if [[ -n "${TMUX:-}" ]]; then
    tm switch-client -t "$s"
  else
    tm attach-session -t "$s"
  fi
}

next_unique_session_name() {
  local base="$1"
  local candidate="$base"
  local n=2
  while session_exists "$candidate"; do
    candidate="${base}-${n}"
    n=$((n + 1))
  done
  printf "%s" "$candidate"
}

case "$mode" in
  attach)
    if ! session_exists "$session_name"; then
      bootstrap_session "$session_name" "$start_dir"
    fi
    attach_or_switch "$session_name"
    ;;
  new)
    session_name="$(next_unique_session_name "$session_name")"
    bootstrap_session "$session_name" "$start_dir"
    attach_or_switch "$session_name"
    ;;
  *)
    echo "Usage: $0 <attach|new> [session_name] [start_dir]" >&2
    exit 2
    ;;
esac
