# Dotfiles

Terminal, editor, and tmux setup for a keyboard-first development workflow.

## Setup

```bash
git clone https://github.com/William-Blackie/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
make setup
```

This installs packages, symlinks configs with GNU Stow, hydrates local secrets, and runs post-install setup.

## Structure

```
~/.dotfiles/
├── zsh/.zshrc                          Zsh with Zinit, lazy-loaded nvm, fzf, zoxide
├── shell/
│   ├── .zprofile                       Homebrew init (login shells)
│   └── .ripgreprc                      Smart-case, hidden files, skip .git
├── tmux/.tmux.conf                     C-Space prefix, vim nav, catppuccin, TPM
├── kitty/.config/kitty/
│   ├── kitty.conf                      JetBrainsMono Nerd Font, no bell
│   └── catppuccin-mocha.conf           Color palette
├── starship/.config/starship.toml      Two-line prompt with git, python, node
├── nvim/.config/nvim/                  LazyVim with custom plugins
│   ├── lua/config/
│   │   ├── lazy.lua                    Plugin manager bootstrap
│   │   ├── options.lua                 4-space tabs (2 for web filetypes)
│   │   ├── keymaps.lua                 Insert-mode C-h/j/k/l navigation
│   │   └── autocmds.lua               Trim whitespace, filetype indent overrides
│   └── lua/plugins/
│       ├── claude-code.lua             Claude Code terminal integration
│       ├── typescript.lua              vtsls with inlay hints
│       ├── neo-tree.lua                File explorer (left sidebar, shows dotfiles)
│       ├── snacks.lua                  Picker config (hidden=yes, ignored=no)
│       ├── vim-tmux-navigator.lua      Seamless C-h/j/k/l between nvim and tmux
│       ├── stylelint.lua               CSS/SCSS linting via LSP
│       └── octo.lua                    GitHub PR/issue review from nvim
├── git/
│   ├── .gitconfig                      SSH, autoSetupRemote, vimdiff
│   └── .gitignore_global               macOS, editor, IDE, security patterns
├── bat/.config/bat/
│   ├── config                           Catppuccin theme
│   └── themes/
│       └── Catppuccin Mocha.tmTheme     Bat syntax theme (for delta too)
├── fzf/.fzf.zsh                        fzf shell integration
├── Makefile                            make install / uninstall / status
├── setup.sh                            Post-install (Zinit, TPM, pyenv, fzf)
└── backup.sh                           Backup existing configs before stow
```

## Daily use

| Command | What it does |
|---------|-------------|
| `start` | Attach/create session (default: `main`) with clean bootstrap windows |
| `tmx [name]` | Attach/create tmux session by name (reuses if it exists) |
| `tmn [name]` | Always create a new session (adds `-2`, `-3`, etc. if needed) |
| `tml` | List tmux sessions |
| `lg` | LazyGit |
| `ls` | eza with icons and git status |
| `cat` | bat with syntax highlighting |
| `dc` | `docker compose` shortcut |
| `dcu` | `docker compose up -d --remove-orphans` |
| `dcd` | `docker compose down --remove-orphans` |
| `p` / `pfs` | open the Grove project picker |
| `wtl` | list worktrees via `grove` |
| `wta <branch>` | create a new worktree branch |
| `wts [index...]` | start worktree services |
| `wtx [index...]` | stop worktree services |
| `wtp <index>` | promote worktree changes |
| `k9s` | Kubernetes terminal UI |
| `z <dir>` | zoxide smart cd |
| `C-t` | fzf file picker in shell |
| `C-r` | fzf history search |

New sessions created via `start`/`tmx`/`tmn` bootstrap with two windows in the current directory: `editor` and `shell`.

## Keybindings

### Tmux (prefix: `C-Space`)

| Key | Action |
|-----|--------|
| `C-h/j/k/l` | Navigate panes (works across nvim splits) |
| `prefix \|` | Split horizontally |
| `prefix -` | Split vertically |
| `prefix N` | Attach/create tmux session by name (prompt) |
| `prefix T` | Always create new tmux session by name (prompt) |
| `prefix c` | New window |
| `prefix H/L` | Swap window left/right |
| `prefix z` | Zoom pane |
| `prefix R` | Reload tmux config |
| `prefix I` | Install TPM plugins |
| `M-h/j/k/l` | Resize panes |

### Nvim (LazyVim)

| Key | Action |
|-----|--------|
| `<leader>e` | Toggle file explorer (cwd) |
| `<leader>E` | Toggle file explorer (current file dir) |
| `<leader><leader>` | Find files (alt+i to include ignored) |
| `<leader>/` | Grep (alt+i to include ignored) |
| `<leader>ac` | Toggle Claude Code |
| `<leader>as` | Send selection to Claude (visual mode) |
| `<leader>gp` | List PRs (Octo) |
| `<leader>gi` | List issues (Octo) |
| `<leader>k` | Open k9s |
| `<leader>kg` | Open local Grafana (`GRAFANA_URL`, then `:13000`, fallback `:3000`) |

## Managing configs

```bash
cd ~/.dotfiles

make install              # Stow all packages
make uninstall            # Unstow all
make reinstall            # Re-stow all (fixes broken links)
make status               # Check what's linked and what's installed
make check-shell          # shellcheck scripts
make check-format         # shfmt check for shell scripts
make check-secrets        # Scan for committed tokens/keys
make hydrate              # Write local config files from 1Password/Bitwarden
make tune-docker          # Apply local Docker CLI/Desktop tuning
make test                 # Run the current E2E smoke suite
make ci                   # Run full local CI suite
stow -R shell             # Re-stow directly with stow
```

`make hydrate` uses native `op` and `bw` CLI access. It looks up secure notes like `F_AWS_CONFIG` and writes them to their local file destinations.

## After pulling changes

```bash
cd ~/.dotfiles && make reinstall
```

Then in nvim: `:Lazy sync`.
In tmux: `prefix + I` to install any new plugins, then restart tmux for theme changes.

## CI

GitHub Actions runs `.github/workflows/ci.yaml` on push/PR to enforce:
- shell formatting (`shfmt`)
- shell linting (`shellcheck`)
- secret/key pattern scanning
- zsh syntax checks
- the current Docker-backed E2E smoke suite

## Docker Tuning

`make tune-docker` applies:
- Docker CLI defaults (`BuildKit`, quieter CLI hints/menu, sensible detach keys)
- Docker Desktop macOS hardware-aware resource/fs tuning with automatic backup of your existing settings file

Optional overrides for Docker Desktop tuning:
- `DOCKER_TUNE_CPUS`
- `DOCKER_TUNE_MEMORY_MIB`
- `DOCKER_TUNE_SWAP_MIB`
- `DOCKER_TUNE_TOTAL_CPUS` and `DOCKER_TUNE_TOTAL_MEM_MIB` (simulate hardware for testing)

After `make tune-docker`, restart Docker Desktop once so Desktop setting changes apply.
