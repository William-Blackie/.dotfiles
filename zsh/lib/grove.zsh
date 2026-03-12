# Grove - Project, worktree, and session manager
# This replaces the old inline pfs scripts.

if [[ -f "$HOME/.local/share/grove/shell/grove.zsh" ]]; then
  source "$HOME/.local/share/grove/shell/grove.zsh"
else
  # Provide a helpful fallback alias if grove isn't installed yet
  unalias p 2>/dev/null
  \p() {
    echo "Grove is not installed."
    echo "Please install grove from your private repository to use the project switcher (p), worktree tools (wt), and session management."
  }
  alias pfs="p"
fi
