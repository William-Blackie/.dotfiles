# Keep this file minimal: exported vars + lightweight wrappers only.

##### Node.js / nvm (lazy-loaded; available in interactive and non-interactive zsh)
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  _nvm_load() {
    unset -f nvm node npm npx yarn pnpm corepack
    \. "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && \. "$NVM_DIR/bash_completion"
  }
  nvm()      { _nvm_load; nvm "$@" }
  node()     { _nvm_load; node "$@" }
  npm()      { _nvm_load; npm "$@" }
  npx()      { _nvm_load; npx "$@" }
  yarn()     { _nvm_load; yarn "$@" }
  pnpm()     { _nvm_load; pnpm "$@" }
  corepack() { _nvm_load; corepack "$@" }
fi

# Machine-local env for all zsh invocations (not tracked in dotfiles repo).
[[ -f ~/.zshenv.local ]] && source ~/.zshenv.local
