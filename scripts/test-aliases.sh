#!/usr/bin/env zsh
# Test all custom aliases and functions defined in .zshrc

source "$HOME/.dotfiles/zsh/.zshrc"

PASS_COUNT=0
FAIL_COUNT=0

ok() {
  echo "PASS: $1"
  PASS_COUNT=$((PASS_COUNT + 1))
}

fail() {
  echo "FAIL: $1"
  FAIL_COUNT=$((FAIL_COUNT + 1))
}

# Test Existence
check_alias() {
  alias "$1" >/dev/null 2>&1 && ok "alias $1 exists" || fail "alias $1 missing"
}

check_func() {
  declare -f "$1" >/dev/null 2>&1 && ok "function $1 exists" || fail "function $1 missing"
}

main() {
  echo "Testing Zsh Aliases & Interactive Commands..."

  # Core
  check_alias "ls"
  check_alias "cat"
  check_alias "vim"
  
  # AI
  check_alias "ai"
  check_func "gai"
  check_func "gge"
  check_func "explain"

  # Git
  check_func "ggb"

  # Tmux
  check_func "pfs"

  # Kube
  check_alias "k"
  check_func "kkx"
  check_func "kkn"
  check_func "kkl"
  check_func "kke"

  # Reference
  check_func "cheatsheet"
  check_func "vimhelp"

  # Environment Verification
  [[ "$PYENV_DISABLE_AUTO_REHASH" == "1" ]] && ok "PYENV_DISABLE_AUTO_REHASH is set" || fail "PYENV_DISABLE_AUTO_REHASH missing"

  echo "
Summary: $PASS_COUNT passed, $FAIL_COUNT failed"
  [[ "$FAIL_COUNT" -eq 0 ]] || exit 1
}

main "$@"
