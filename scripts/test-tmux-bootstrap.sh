#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SESSION_SCRIPT="$ROOT_DIR/scripts/tmux-session.sh"
TMUX_CONF="$ROOT_DIR/tmux/.tmux.conf"
SOCKET_NAME="dotfiles-test-tmux-$$"
PROBE_OUT="/tmp/dotfiles-tmux-probe-$$.txt"
PROBE_SCRIPT="/tmp/dotfiles-tmux-probe-$$.zsh"
PROBE_WINDOW="probe-$$"
ATTACH_SESSION="main-$$"
NEW_BASE="project-$$"
# Avoid pyenv rehash lock stalls during concurrent shell startup in tests.
export PYENV_DISABLE_AUTO_REHASH=1

cleanup() {
  tmux -L "$SOCKET_NAME" kill-server > /dev/null 2>&1 || true
  rm -f "$PROBE_SCRIPT"
  rm -f "$PROBE_OUT"
}
trap cleanup EXIT

assert_window_bootstrap() {
  local session_name="$1"
  local windows
  windows="$(tmux -L "$SOCKET_NAME" list-windows -t "$session_name")"
  [[ "$windows" == *"editor"* ]] || {
    echo "FAIL: session '$session_name' missing editor window"
    echo "$windows"
    exit 1
  }
  [[ "$windows" == *"shell"* ]] || {
    echo "FAIL: session '$session_name' missing shell window"
    echo "$windows"
    exit 1
  }
}

assert_tmux_config_loaded() {
  local keys hooks opts

  keys="$(tmux -L "$SOCKET_NAME" list-keys)"
  hooks="$(tmux -L "$SOCKET_NAME" show-hooks -g)"
  opts="$(tmux -L "$SOCKET_NAME" show-options -g)"

  echo "$keys" | rg -q 'prefix[[:space:]]+N[[:space:]].*tmux-session\.sh attach' || {
    echo "FAIL: tmux prefix N binding was not loaded from tmux.conf"
    exit 1
  }
  echo "$keys" | rg -q 'prefix[[:space:]]+T[[:space:]].*tmux-session\.sh new' || {
    echo "FAIL: tmux prefix T binding was not loaded from tmux.conf"
    exit 1
  }
  echo "$hooks" | rg -q 'client-detached.*tmux-resurrect/scripts/save\.sh' || {
    echo "FAIL: client-detached save hook missing from tmux.conf"
    exit 1
  }
  echo "$hooks" | rg -q 'session-closed.*tmux-resurrect/scripts/save\.sh' || {
    echo "FAIL: session-closed save hook missing from tmux.conf"
    exit 1
  }
  echo "$opts" | rg -q '@continuum-save-interval 5' || {
    echo "FAIL: @continuum-save-interval expected to be 5"
    exit 1
  }
}

echo "Testing tmux config load path..."
tmux -L "$SOCKET_NAME" -f "$TMUX_CONF" new-session -d -s __config_check
assert_tmux_config_loaded
tmux -L "$SOCKET_NAME" kill-session -t __config_check > /dev/null 2>&1 || true

echo "Testing tmux attach/create bootstrap..."
TMUX_SOCKET_NAME="$SOCKET_NAME" TMUX_SESSION_NO_ATTACH=1 "$SESSION_SCRIPT" attach "$ATTACH_SESSION" "$PWD"
assert_window_bootstrap "$ATTACH_SESSION"

window_count="$(tmux -L "$SOCKET_NAME" list-windows -t "$ATTACH_SESSION" | wc -l | tr -d ' ')"
[[ "$window_count" == "2" ]] || {
  echo "FAIL: expected 2 windows in $ATTACH_SESSION, got $window_count"
  exit 1
}

echo "Testing tmux new unique naming..."
TMUX_SOCKET_NAME="$SOCKET_NAME" TMUX_SESSION_NO_ATTACH=1 "$SESSION_SCRIPT" new "$NEW_BASE" "$PWD"
TMUX_SOCKET_NAME="$SOCKET_NAME" TMUX_SESSION_NO_ATTACH=1 "$SESSION_SCRIPT" new "$NEW_BASE" "$PWD"

tmux -L "$SOCKET_NAME" has-session -t "$NEW_BASE"
tmux -L "$SOCKET_NAME" has-session -t "$NEW_BASE-2"
assert_window_bootstrap "$NEW_BASE"
assert_window_bootstrap "$NEW_BASE-2"

echo "Testing node/npm pathing inside a tmux pane..."
cat > "$PROBE_SCRIPT" << EOF
#!/usr/bin/env zsh
set -euo pipefail
{
  node -v >/dev/null 2>&1
  npm -v >/dev/null 2>&1
  echo node_exec=\$(node -p 'process.execPath')
  echo npm_prefix=\$(npm prefix -g)
  echo nvm_dir=\${NVM_DIR:-<unset>}
} > '$PROBE_OUT'
EOF
chmod +x "$PROBE_SCRIPT"

tmux -L "$SOCKET_NAME" new-window -d -t "$ATTACH_SESSION:" -n "$PROBE_WINDOW" -c "$PWD" "zsh -lic '$PROBE_SCRIPT'"

for _ in $(seq 1 1200); do
  if [[ -f "$PROBE_OUT" ]] && rg -q '^npm_prefix=' "$PROBE_OUT"; then
    break
  fi
  sleep 0.1
done

if [[ ! -f "$PROBE_OUT" ]] || ! rg -q '^npm_prefix=' "$PROBE_OUT"; then
  # Retry once in case startup tasks delayed probe execution.
  tmux -L "$SOCKET_NAME" new-window -d -t "$ATTACH_SESSION:" -n "${PROBE_WINDOW}-retry" -c "$PWD" "zsh -lic '$PROBE_SCRIPT'"
  for _ in $(seq 1 1200); do
    if [[ -f "$PROBE_OUT" ]] && rg -q '^npm_prefix=' "$PROBE_OUT"; then
      break
    fi
    sleep 0.1
  done
fi

[[ -f "$PROBE_OUT" ]] || {
  echo "FAIL: tmux probe output not created"
  tmux -L "$SOCKET_NAME" capture-pane -pt "$ATTACH_SESSION:$PROBE_WINDOW.1" -S -120 || true
  exit 1
}

node_exec="$(sed -n 's/^node_exec=//p' "$PROBE_OUT" | tail -n 1)"
npm_prefix="$(sed -n 's/^npm_prefix=//p' "$PROBE_OUT" | tail -n 1)"
nvm_dir="$(sed -n 's/^nvm_dir=//p' "$PROBE_OUT" | tail -n 1)"

[[ "$node_exec" == "$HOME"/.nvm/versions/node/*/bin/node ]] || {
  echo "FAIL: node path in tmux is not nvm-managed ($node_exec)"
  exit 1
}
[[ "$npm_prefix" == "$HOME"/.nvm/versions/node/* ]] || {
  echo "FAIL: npm global prefix in tmux is not nvm-managed ($npm_prefix)"
  exit 1
}
[[ "$nvm_dir" == "$HOME/.nvm" ]] || {
  echo "FAIL: NVM_DIR in tmux is unexpected ($nvm_dir)"
  exit 1
}

echo "tmux bootstrap tests passed."
