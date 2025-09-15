.PHONY: install uninstall reinstall status help setup-packages install-packages

# Default target
help:
	@echo "Dotfiles Management"
	@echo "==================="
	@echo ""
	@echo "Available commands:"
	@echo "  make setup       - Install packages AND dotfiles (complete setup)"
	@echo "  make install     - Install dotfiles only"
	@echo "  make uninstall   - Remove all dotfiles"
	@echo "  make reinstall   - Reinstall all dotfiles"
	@echo "  make status      - Show installation status"
	@echo ""
	@echo "Package management:"
	@echo "  make install-packages - Install all required packages via Homebrew"
	@echo ""
	@echo "Individual packages (install):"
	@echo "  make install-zsh      - Install zsh config"
	@echo "  make install-tmux     - Install tmux config"
	@echo "  make install-kitty    - Install kitty config"
	@echo "  make install-starship - Install starship config"
	@echo "  make install-nvim     - Install nvim config"
	@echo "  make install-git      - Install git config"
	@echo "  make install-fzf      - Install fzf config"
	@echo "  make install-shell    - Install shell config (.zprofile)"
	@echo ""
	@echo "Individual packages (uninstall):"
	@echo "  make uninstall-{package}  - Remove specific package"

setup: install-packages install
	@echo "🔧 Running additional setup..."
	@./setup.sh
	@echo "🎉 Complete setup finished!"
	@echo "Please restart your terminal or run: source ~/.zshrc"

install-packages:
	@echo "📦 Installing packages via Homebrew..."
	@command -v brew >/dev/null 2>&1 || { echo "Installing Homebrew..."; /bin/bash -c "$$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; }
	@echo "🍺 Installing core packages..."
	brew install git curl neovim tmux stow
	@echo "🔧 Installing development tools..."
	brew install fzf fd ripgrep eza bat zoxide starship lazygit tree-sitter
	@echo "📝 Installing language servers and tools..."
	brew install lua luarocks node python@3.12 pyenv
	@echo "🖥️  Installing terminal and fonts..."
	brew install --cask kitty font-jetbrains-mono-nerd-font
	@echo "✅ All packages installed!"

install:
	stow zsh tmux kitty starship nvim git fzf shell

uninstall:
	stow -D zsh tmux kitty starship nvim git fzf shell

reinstall:
	stow -R zsh tmux kitty starship nvim git fzf shell

# Individual package targets
install-zsh:
	stow zsh

install-tmux:
	stow tmux

install-kitty:
	stow kitty

install-starship:
	stow starship

install-nvim:
	stow nvim

install-git:
	stow git

install-fzf:
	stow fzf

install-shell:
	stow shell

# Uninstall individual packages
uninstall-zsh:
	stow -D zsh

uninstall-tmux:
	stow -D tmux

uninstall-kitty:
	stow -D kitty

uninstall-starship:
	stow -D starship

uninstall-nvim:
	stow -D nvim

uninstall-git:
	stow -D git

uninstall-fzf:
	stow -D fzf

uninstall-shell:
	stow -D shell

status:
	@echo "Checking symlink status..."
	@ls -la ~/{.zshrc,.tmux.conf,.gitconfig} 2>/dev/null | grep -E "\.dotfiles" || echo "Some configs not linked"
	@ls -la ~/.config/{kitty,nvim,starship.toml} 2>/dev/null | grep -E "\.dotfiles" || echo "Some .config items not linked"
	@echo ""
	@echo "Checking installed packages..."
	@command -v brew >/dev/null && echo "✅ Homebrew installed" || echo "❌ Homebrew not installed"
	@command -v git >/dev/null && echo "✅ git installed" || echo "❌ git not installed"
	@command -v nvim >/dev/null && echo "✅ neovim installed" || echo "❌ neovim not installed"
	@command -v tmux >/dev/null && echo "✅ tmux installed" || echo "❌ tmux not installed"
	@command -v starship >/dev/null && echo "✅ starship installed" || echo "❌ starship not installed"
	@command -v fzf >/dev/null && echo "✅ fzf installed" || echo "❌ fzf not installed"
	@command -v eza >/dev/null && echo "✅ eza installed" || echo "❌ eza not installed"
	@command -v bat >/dev/null && echo "✅ bat installed" || echo "❌ bat not installed"
	@command -v zoxide >/dev/null && echo "✅ zoxide installed" || echo "❌ zoxide not installed"
	@command -v lazygit >/dev/null && echo "✅ lazygit installed" || echo "❌ lazygit not installed"