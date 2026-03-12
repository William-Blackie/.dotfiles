# Minimal .zshenv - Most logic moved to zsh/lib/path.zsh for modularity.

# Ensure we have the base PATH needed to find the dotfiles modular loader
export PATH="$HOME/.local/bin:$PATH"

# Machine-local env for all zsh invocations (not tracked in dotfiles repo).
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
