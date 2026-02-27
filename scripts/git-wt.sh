#!/usr/bin/env bash
set -euo pipefail

# Advanced Git Worktree Manager
# Simplifies worktree creation, navigation, and cleanup.

usage() {
  echo "Usage: $0 {new|switch|done|list}"
  exit 1
}

[[ $# -lt 1 ]] && usage

mode="$1"

# Ensure we are in a git repo
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Not in a git repository"; exit 1; }

# Find the main repo root (handles being inside a worktree)
GIT_COMMON_DIR=$(git rev-parse --git-common-dir)
REPO_ROOT=$(cd "$GIT_COMMON_DIR/.." && pwd)
REPO_NAME=$(basename "$REPO_ROOT")
WT_PARENT=$(dirname "$REPO_ROOT")/wt

case "$mode" in
  new)
    branch="${2:-}"
    [[ -z "$branch" ]] && { echo "Usage: $0 new <branch>"; exit 1; }
    
    # Sanitize branch name for directory
    slug=$(echo "$branch" | tr '/' '-')
    target_dir="$WT_PARENT/$REPO_NAME-$slug"
    
    echo "Creating worktree for '$branch' at $target_dir..."
    mkdir -p "$WT_PARENT"
    
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      git worktree add "$target_dir" "$branch"
    else
      git worktree add -b "$branch" "$target_dir" origin/main || git worktree add -b "$branch" "$target_dir" origin/master || git worktree add -b "$branch" "$target_dir"
    fi
    
    # If inside tmux, offer to switch to a new session for this worktree
    if [[ -n "${TMUX:-}" ]]; then
      ~/.dotfiles/scripts/tmux-session.sh attach "$REPO_NAME-$slug" "$target_dir"
    fi
    ;;

  switch)
    # Fuzzy switch between existing worktrees
    selected=$(git worktree list --porcelain | grep 'worktree' | awk '{print $2}' | fzf --header "Switch Worktree" --reverse)
    [[ -z "$selected" ]] && exit 0
    
    if [[ -n "${TMUX:-}" ]]; then
      slug=$(basename "$selected")
      ~/.dotfiles/scripts/tmux-session.sh attach "$slug" "$selected"
    else
      cd "$selected" && exec "$SHELL"
    fi
    ;;

  done)
    # Cleanup current or selected worktree
    current_wt=$(git rev-parse --show-toplevel)
    echo "Removing worktree at $current_wt..."
    
    # Move out of the directory if we are in it
    cd "$REPO_ROOT"
    git worktree remove "$current_wt"
    git worktree prune
    ;;

  list)
    git worktree list
    ;;

  *)
    usage
    ;;
esac
