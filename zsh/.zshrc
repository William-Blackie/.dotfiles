##### Homebrew (macOS)
# Guard against double-init when .zprofile already ran this in a login shell
if [[ -z "$HOMEBREW_PREFIX" ]]; then
  if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
fi

##### Zinit (plugin manager)
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  if command -v git >/dev/null 2>&1; then
    git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
  fi
fi
if [[ -f "${ZINIT_HOME}/zinit.zsh" ]]; then
  source "${ZINIT_HOME}/zinit.zsh"
fi

##### Plugins (work-focused)
if (( $+functions[zinit] )); then
  zinit light zsh-users/zsh-completions
  zinit light zsh-users/zsh-autosuggestions
  # fzf-tab loaded after compinit below (required by its docs)

  # OMZ snippets (non-theme)
  zinit snippet OMZL::git.zsh
  zinit snippet OMZP::git
  zinit snippet OMZP::sudo
  zinit snippet OMZP::aws
  zinit snippet OMZP::kubectl
  zinit snippet OMZP::kubectx
  zinit snippet OMZP::command-not-found

  # Annexes
  zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust
fi

##### Completions
[[ -d "$HOME/.docker/completions" ]] && fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit && compinit
# fzf-tab must load after compinit
if (( $+functions[zinit] )); then
  zinit light Aloxaf/fzf-tab
fi
if command -v gh >/dev/null 2>&1; then
  eval "$(gh completion -s zsh)"
fi

##### Prompt (Starship + Catppuccin)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

##### Keybindings & history
bindkey -e
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward
HISTSIZE=500000
SAVEHIST=$HISTSIZE
HISTFILE=~/.zsh_history
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups \
       hist_save_no_dups hist_ignore_dups hist_find_no_dups

##### Aliases
alias c="clear"

if command -v eza >/dev/null 2>&1; then
  alias ls="eza -lah --git --group-directories-first --icons"
fi
if command -v bat >/dev/null 2>&1; then
  alias cat="bat -pp"
fi
if command -v nvim >/dev/null 2>&1; then
  alias vim="nvim"
fi
if command -v lazygit >/dev/null 2>&1; then
  alias lg="lazygit"
fi
if command -v tmux >/dev/null 2>&1; then
  alias start="tmux attach-session -t main || tmux new-session -d -s main"
fi

alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gca="git commit -a"
alias gcm="git commit -m"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gbd="git branch -d"
alias gbr="git branch"
alias gpl="git pull"
alias gph="git push"
alias gsh="git stash"
alias gshp="git stash pop"
alias gshl="git stash list"
alias gd="git diff"
alias gds="git diff --staged"
alias glog="git log --oneline --graph --decorate --all"

##### fzf + zoxide
if command -v fzf >/dev/null 2>&1; then
  [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  # Catppuccin Mocha theme for fzf
  export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
fi
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

##### Python / pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init - zsh)"

##### Node.js / nvm (lazy-loaded for faster shell startup)
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

##### Scaleway CLI autocomplete
command -v scw >/dev/null 2>&1 && eval "$(scw autocomplete script shell=zsh)"

##### Machine-local config (not tracked — put KUBECONFIG, work secrets, etc. here)
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

##### Editor
export EDITOR="nvim"
export VISUAL="nvim"

##### Better defaults for tools
export BAT_THEME="Catppuccin Mocha"
export EZA_COLORS="uu=36:gu=37:sn=32:sb=32:da=34:ur=34:uw=35:ux=36:ue=36:gr=34:gw=35:gx=36:tr=34:tw=35:tx=36:"
[[ -f "$HOME/.local/bin/env" ]] && . "$HOME/.local/bin/env"

export PATH="$HOME/.cartesia/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@15/bin:$PATH"

##### Zsh syntax highlighting (load after all other ZLE setup)
if (( $+functions[zinit] )); then
  zinit light zsh-users/zsh-syntax-highlighting
fi
