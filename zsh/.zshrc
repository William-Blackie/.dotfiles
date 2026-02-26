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
zstyle ':completion:*' menu select
zstyle ':completion:*:descriptions' format '%F{245}%d%f'
zstyle ':completion:*:warnings' format '%F{203}no matches for:%f %d'

# fzf integration (load before fzf-tab so fzf-tab can wrap it)
if command -v fzf >/dev/null 2>&1; then
  [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
  export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  # Catppuccin Mocha, pared down for a minimal interface.
  export FZF_DEFAULT_OPTS=" \
--height=40% --layout=reverse --border --info=inline-right \
--color=bg:#1e1e2e,bg+:#313244,spinner:#f5c2e7,hl:#89b4fa \
--color=fg:#cdd6f4,header:#94e2d5,info:#bac2de,pointer:#f5e0dc \
--color=marker:#a6e3a1,fg+:#f5e0dc,prompt:#89b4fa,hl+:#cba6f7,border:#45475a"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# fzf-tab (load after compinit and fzf)
if (( $+functions[zinit] )); then
  zinit light Aloxaf/fzf-tab
fi
zstyle ':fzf-tab:*' fzf-flags --height=40% --layout=reverse --border

# Better vi-mode (configuration only here, loading at the end)
ZVM_VI_INSERT_ESCAPE_BINDKEY=jk # allow 'jk' to exit insert mode
ZVM_LINE_BEFORE_PROMPT=false     # keep prompt compact

if command -v gh >/dev/null 2>&1; then
  eval "$(gh completion -s zsh)"
fi

##### Prompt (Starship + Catppuccin)
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

##### Keybindings & history (vim-style)
bindkey -v
export KEYTIMEOUT=1   # make Esc feel instant

# History search (prefix-aware) on Ctrl-p / Ctrl-n, in BOTH insert + normal modes
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^p' up-line-or-beginning-search
bindkey '^n' down-line-or-beginning-search
bindkey -M vicmd '^p' up-line-or-beginning-search
bindkey -M vicmd '^n' down-line-or-beginning-search

HISTSIZE=500000
SAVEHIST=$HISTSIZE
HISTFILE=~/.zsh_history
setopt appendhistory sharehistory hist_ignore_space hist_ignore_all_dups \
       hist_save_no_dups hist_ignore_dups hist_find_no_dups

##### Aliases
alias c="clear"

# Vim Motion Quick Reference (searchable via fzf)
unalias vimhelp 2>/dev/null
vimhelp() {
  cat << 'EOF' | fzf --header "Vim Motion Quick Reference" --reverse
w - next word | b - back word | e - end of word
0 - start of line | $ - end of line | ^ - first non-blank
f{char} - jump forward to char | t{char} - jump until char
F{char} - jump backward to char | T{char} - jump back until char
; - repeat last f/t jump | , - reverse last f/t jump
dw - delete word | cw - change word | de - delete to end of word
df{char} - delete forward to char | dt{char} - delete until char
ci" - change inside quotes | ca" - change around quotes
ci( - change inside parens | ca( - change around parens
G - bottom of file | gg - top of file | {line}G - go to line
EOF
}

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
  start() { ~/.dotfiles/scripts/tmux-session.sh attach "${1:-main}" "$PWD"; }
  tmx()   { ~/.dotfiles/scripts/tmux-session.sh attach "${1:-main}" "$PWD"; }
  tmn()   { ~/.dotfiles/scripts/tmux-session.sh new "${1:-$(basename "$PWD")}" "$PWD"; }
  tml()   { tmux list-sessions; }
fi
if command -v docker >/dev/null 2>&1; then
  export DOCKER_BUILDKIT=1
  export COMPOSE_DOCKER_CLI_BUILD=1
  export DOCKER_CLI_HINTS=false
  export COMPOSE_MENU=false
  alias dc="docker compose"
  alias dcu="docker compose up -d --remove-orphans"
  alias dcd="docker compose down --remove-orphans"
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

##### Python / pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init - zsh)"

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

##### Zsh syntax highlighting & Vi Mode (load at the very end for ZLE wrapping)
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]="fg=#89b4fa,bold"
ZSH_HIGHLIGHT_STYLES[builtin]="fg=#cba6f7"
ZSH_HIGHLIGHT_STYLES[alias]="fg=#f9e2af"
ZSH_HIGHLIGHT_STYLES[path]="fg=#94e2d5"
ZSH_HIGHLIGHT_STYLES[unknown-token]="fg=#f38ba8,bold"
if (( $+functions[zinit] )); then
  zinit light zsh-users/zsh-syntax-highlighting
  zinit light jeffreytse/zsh-vi-mode
fi
