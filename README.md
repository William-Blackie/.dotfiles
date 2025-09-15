# William's Dotfiles

A unified configuration setup featuring the Catppuccin theme across all tools with vim-style keybindings, managed with GNU Stow.

## Quick Start

```bash
# One command setup - installs everything!
git clone https://github.com/William-Blackie/.dotfiles.git ~/.dotfiles && cd ~/.dotfiles && make setup
```

This will:
1. Install Homebrew (if not present)
2. Install all required packages (neovim, tmux, kitty, etc.)
3. Install Zinit, TPM, and other plugin managers
4. Link all dotfiles using GNU Stow
5. Set up Python and Node.js environments

## Features

- 🎨 **Catppuccin Mocha** theme across all tools (Neovim, Tmux, Kitty, Starship)
- ⌨️ **Vim-style keybindings** with seamless navigation between Neovim and Tmux
- 🚀 **Modern tools**: LazyVim, Starship prompt, Zinit plugin manager
- 🔧 **GNU Stow** for clean dotfile management with symlinks
- 📦 **Modular packages** - install only what you need

## Tools & Themes

- **Terminal**: Kitty with Catppuccin Mocha
- **Shell**: Zsh with Zinit plugin manager
- **Prompt**: Starship with Catppuccin theme
- **Editor**: LazyVim (Neovim) with Catppuccin
- **Multiplexer**: Tmux with Catppuccin and vim navigation
- **File Manager**: eza with icons
- **Cat Replacement**: bat with syntax highlighting
- **Git UI**: LazyGit
- **Package Management**: Homebrew + automatic setup

See [PACKAGES.md](PACKAGES.md) for a complete list of installed packages.

## Installation

### Complete Setup (Recommended)
```bash
# Clone dotfiles
git clone https://github.com/William-Blackie/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# Install everything (packages + dotfiles + additional setup)
make setup
```

### Manual Installation

#### Prerequisites
```bash
# Install GNU Stow (if not using make setup)
brew install stow

# Clone dotfiles
git clone https://github.com/William-Blackie/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

#### Install Just Packages
```bash
make install-packages
```

#### Install Just Dotfiles
```bash
make install
```

### Install Configurations
```bash
# Method 1: Using Make (recommended)
make install

# Method 2: Using Stow directly
stow zsh tmux kitty starship nvim git fzf shell

# Install selectively
make install-zsh           # Install just zsh
make install-nvim          # Install just nvim
stow fzf shell             # Install fzf and shell configs
```

### Remove Configurations
```bash
# Remove all
make uninstall

# Remove specific packages
make uninstall-zsh         # Remove zsh config
make uninstall-nvim        # Remove nvim config
stow -D fzf shell          # Or use stow directly for multiple
```

### Check Status
```bash
make status          # See which configs are linked
./manage.sh status   # See package installation status
```

## Package Structure

```
~/.dotfiles/
├── zsh/
│   └── .zshrc              # Modern zsh with Zinit
├── tmux/
│   └── .tmux.conf          # Tmux with Catppuccin & vim navigation
├── kitty/
│   └── .config/kitty/
│       ├── kitty.conf      # Kitty terminal config
│       └── catppuccin-mocha.conf
├── starship/
│   └── .config/
│       └── starship.toml   # Starship prompt with Catppuccin
├── nvim/
│   └── .config/nvim/       # LazyVim configuration
├── git/
│   └── .gitconfig          # Git configuration
├── fzf/
│   └── .fzf.zsh           # FZF fuzzy finder setup
├── shell/
│   └── .zprofile          # Shell environment setup
└── README.md
```

## Key Features

### Unified Keybindings
- `Ctrl+h/j/k/l` - Navigate between Neovim splits and Tmux panes seamlessly
- `Ctrl+Space` - Tmux prefix key (more ergonomic than Ctrl+b)
- `|` and `-` - Split windows in Tmux (matches Neovim muscle memory)

### Theme Consistency
All tools use the same Catppuccin Mocha color palette for a cohesive experience.

### Modern Workflow
- Fast fuzzy finding with fzf and Telescope
- Git integration with LazyGit
- Smart directory jumping with zoxide
- Auto-suggestions and syntax highlighting in shell
- Seamless vim-tmux navigation

## Usage Tips

```bash
# Quick tmux session
start

# LazyGit in any repo
lg

# Better ls with icons
ls

# Syntax-highlighted cat
cat file.txt

# All your vim muscle memory works in tmux!
# Ctrl+h/j/k/l to navigate between panes and vim splits
```
