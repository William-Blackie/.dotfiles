# Keep this file minimal: exported vars + lightweight wrappers only.

##### Node.js / nvm (Fast PATH injection for non-interactive shells)
export NVM_DIR="$HOME/.nvm"
# If nvm is installed, try to inject the 'default' version's bin into PATH directly.
# This makes node/npm fast in non-interactive shells (no sourcing nvm.sh).
if [[ -d "$NVM_DIR/versions/node" ]]; then
  # Use a simple glob to find the current default version link if it exists.
  # nvm usually creates a 'default' alias which is a symlink or just a text file.
  # To keep this fast, we manually resolve what we can or just use nvm's structure.
  DEFAULT_NODE_BIN=$(find "$NVM_DIR/versions/node" -maxdepth 2 -type d -path "*/bin" | head -n 1)
  if [[ -n "$DEFAULT_NODE_BIN" ]]; then
    export PATH="$DEFAULT_NODE_BIN:$PATH"
  fi
fi

##### Python / pyenv (Fast PATH injection)
export PYENV_ROOT="$HOME/.pyenv"
export PYENV_DISABLE_AUTO_REHASH=1
if [[ -d "$PYENV_ROOT" ]]; then
  [[ -d "$PYENV_ROOT/bin" ]] && export PATH="$PYENV_ROOT/bin:$PATH"
  [[ -d "$PYENV_ROOT/shims" ]] && export PATH="$PYENV_ROOT/shims:$PATH"
fi

# Machine-local env for all zsh invocations (not tracked in dotfiles repo).
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
