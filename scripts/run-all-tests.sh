#!/usr/bin/env bash
set -euo pipefail

# Unified Test Runner for Dotfiles
# Provides a high-signal overview of environment health.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# Colors for output
BOLD="\033[1m"
GREEN="\033[0;32m"
RED="\033[0;31m"
YELLOW="\033[0;33m"
RESET="\033[0m"

PASS_COUNT=0
FAIL_COUNT=0

run_test() {
  local label="$1"
  local script="$2"

  echo -e "${BOLD}Running $label...${RESET}"
  if "$script"; then
    echo -e "${GREEN}PASS: $label${RESET}
"
    PASS_COUNT=$((PASS_COUNT + 1))
  else
    echo -e "${RED}FAIL: $label${RESET}
"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
}

main() {
  echo -e "${BOLD}Starting Dotfiles Environment Tests...${RESET}"
  echo -e "Root: $ROOT_DIR
"

  run_test "Environment Smoke Tests (nvm/npm/kube)" "./scripts/test-zsh-env.sh"
  run_test "tmux Bootstrap Tests" "./scripts/test-tmux-bootstrap.sh"
  run_test "Docker Tuning Tests" "./scripts/test-docker-tuning.sh"
  run_test "Secret Scan" "./scripts/check-sensitive.sh"

  # Summary
  echo -e "${BOLD}Test Summary${RESET}"
  echo -e "------------"
  echo -e "Passed: ${GREEN}$PASS_COUNT${RESET}"
  echo -e "Failed: ${RED}$FAIL_COUNT${RESET}"

  if [[ "$FAIL_COUNT" -eq 0 ]]; then
    echo -e "
${GREEN}✅ Your environment is in top shape!${RESET}"
    exit 0
  else
    echo -e "
${RED}❌ Some tests failed. Please review the output above.${RESET}"
    exit 1
  fi
}

main "$@"
