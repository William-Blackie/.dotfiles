#!/usr/bin/env bash
set -euo pipefail

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

ok() {
  printf "PASS: %s\n" "$1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

warn() {
  printf "WARN: %s\n" "$1"
  WARN_COUNT=$((WARN_COUNT + 1))
}

fail() {
  printf "FAIL: %s\n" "$1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

check_path_link() {
  local path="$1"
  local expected="$2"
  local label="$3"

  if [[ ! -e "$path" ]]; then
    fail "$label is missing at $path"
    return
  fi

  local actual_target expected_target
  actual_target="$(realpath "$path" 2> /dev/null || true)"
  expected_target="$(realpath "$expected" 2> /dev/null || true)"

  if [[ -z "$actual_target" || -z "$expected_target" ]]; then
    fail "$label could not be resolved (actual=$actual_target expected=$expected_target)"
    return
  fi

  if [[ "$actual_target" == "$expected_target" ]]; then
    ok "$label points to $expected"
  else
    fail "$label points to $actual_target (expected $expected_target)"
  fi
}

probe_mode() {
  local mode="$1"
  local output=""

  if ! output="$(
    zsh "$mode" '
set -e
type nvm >/dev/null 2>&1
# Trigger lazy wrappers so command -v resolves actual binaries.
node -v >/dev/null 2>&1
npm -v >/dev/null 2>&1
node_path="$(command -v node)"
npm_path="$(command -v npm)"
npm_prefix="$(npm prefix -g 2>/dev/null || true)"
echo "node_path=$node_path"
echo "npm_path=$npm_path"
echo "npm_prefix=$npm_prefix"
' 2>&1
  )"; then
    fail "zsh $mode probe failed"
    printf "%s\n" "$output"
    return
  fi

  local node_path npm_path npm_prefix
  node_path="$(printf "%s\n" "$output" | sed -n 's/^node_path=//p' | tail -n 1)"
  npm_path="$(printf "%s\n" "$output" | sed -n 's/^npm_path=//p' | tail -n 1)"
  npm_prefix="$(printf "%s\n" "$output" | sed -n 's/^npm_prefix=//p' | tail -n 1)"

  if [[ "$node_path" == "$HOME"/.nvm/versions/node/*/bin/node ]]; then
    ok "zsh $mode resolves node via nvm ($node_path)"
  else
    fail "zsh $mode resolves node outside nvm ($node_path)"
  fi

  if [[ "$npm_path" == "$HOME"/.nvm/versions/node/*/bin/npm ]]; then
    ok "zsh $mode resolves npm via nvm ($npm_path)"
  else
    fail "zsh $mode resolves npm outside nvm ($npm_path)"
  fi

  if [[ "$npm_prefix" == "$HOME"/.nvm/versions/node/* ]]; then
    ok "zsh $mode npm -g prefix is nvm-managed ($npm_prefix)"
  else
    fail "zsh $mode npm -g prefix is not nvm-managed ($npm_prefix)"
  fi
}

check_kubeconfig() {
  local kubeconfig require_kube
  require_kube="${REQUIRE_KUBECONFIG:-0}"
  kubeconfig="$(zsh -lc 'printf "%s" "${KUBECONFIG:-}"')"

  if [[ -z "$kubeconfig" ]]; then
    if [[ "$require_kube" == "1" ]]; then
      fail "KUBECONFIG is empty (REQUIRE_KUBECONFIG=1)"
    else
      warn "KUBECONFIG is empty; set REQUIRE_KUBECONFIG=1 to enforce"
    fi
    return
  fi

  local missing=0
  local path
  IFS=':' read -r -a paths <<< "$kubeconfig"
  for path in "${paths[@]}"; do
    [[ -z "$path" ]] && continue
    if [[ -f "$path" ]]; then
      ok "KUBECONFIG entry exists ($path)"
    else
      missing=1
      if [[ "$require_kube" == "1" ]]; then
        fail "KUBECONFIG entry missing ($path)"
      else
        warn "KUBECONFIG entry missing ($path)"
      fi
    fi
  done

  if [[ "$missing" == "0" ]]; then
    ok "KUBECONFIG resolves to existing file(s)"
  fi
}

main() {
  printf "Running zsh environment smoke tests...\n"

  check_path_link "$HOME/.zprofile" "$HOME/.dotfiles/shell/.zprofile" ".zprofile"
  check_path_link "$HOME/.zshrc" "$HOME/.dotfiles/zsh/.zshrc" ".zshrc"
  check_path_link "$HOME/.zshenv" "$HOME/.dotfiles/shell/.zshenv" ".zshenv"

  local modes=("-c" "-lc")
  if [[ "${INCLUDE_INTERACTIVE:-0}" == "1" ]]; then
    modes+=("-ic" "-lic")
  fi

  local mode
  for mode in "${modes[@]}"; do
    probe_mode "$mode"
  done

  check_kubeconfig

  printf "\nSummary: pass=%d warn=%d fail=%d\n" "$PASS_COUNT" "$WARN_COUNT" "$FAIL_COUNT"
  if [[ "$FAIL_COUNT" -gt 0 ]]; then
    exit 1
  fi
}

main "$@"
