.PHONY: install uninstall reinstall status help setup-packages install-packages test-shell test-tmux test-docker check-format check-shell check-zsh-syntax check-secrets ci tune-docker normalize-stow-links setup hydrate

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
	@echo "  make check-shell - Lint shell scripts with shellcheck"
	@echo "  make check-format - Verify shell script formatting with shfmt"
	@echo "  make check-zsh-syntax - Parse zsh dotfiles for syntax errors"
	@echo "  make check-secrets - Scan tracked files for key/token leaks"
	@echo "  make hydrate     - Write local config files from 1Password/Bitwarden"
	@echo "  make tune-docker  - Apply local Docker CLI/Desktop tuning"
	@echo "  make test        - Run all E2E environment tests"
	@echo "  make ci          - Run full local CI suite (checks + tests)"
	@echo ""
	@echo "Package management:"
	@echo "  make install-packages - Install all required packages"

setup: install-packages install
	@echo "🔧 Running additional setup..."
	@./setup.sh
	@echo "🎉 Complete setup finished!"
	@echo "Please restart your terminal or run: source ~/.zshrc"

install-packages:
	@./scripts/install-packages.sh

normalize-stow-links:
	@target="$$HOME/.zshenv"; \
	if [ -L "$$target" ]; then \
		link="$$(readlink "$$target")"; \
		case "$$link" in \
			"$(CURDIR)/shell/.zshenv"|"$${HOME}/.dotfiles/shell/.zshenv") \
				echo "🔧 Normalizing absolute symlink $$target"; \
				ln -snf ".dotfiles/shell/.zshenv" "$$target";; \
		esac; \
	fi

install:
	@$(MAKE) normalize-stow-links
	@echo "💧 Hydrating all secrets from vault..."
	@$(MAKE) hydrate
	@echo "📦 Stowing dotfiles (backing up conflicts)..."
	@BACKUP_DIR="$${HOME}/.dotfiles_backup_$$(date +%Y%m%d_%H%M%S)"; \
	PACKAGES="zsh tmux kitty starship nvim git fzf shell bat"; \
	mkdir -p "$$BACKUP_DIR"; \
	for pkg in $$PACKAGES; do \
		echo "→ Processing $$pkg"; \
		stow -n $$pkg 2>&1 | grep "existing target" | sed 's/.*existing target \(.*\) since.*/\1/' | while read -r target; do \
			[ -z "$$target" ] && continue; \
			target_path="$${HOME}/$$target"; \
			if [ -e "$$target_path" ] && [ ! -L "$$target_path" ]; then \
				backup_path="$$BACKUP_DIR/$$target"; \
				mkdir -p "$$(dirname "$$backup_path")"; \
				echo "  ⚠️  Backing up $$target"; \
				mv "$$target_path" "$$backup_path"; \
			fi; \
		done; \
		stow $$pkg; \
	done
	@command -v bat >/dev/null 2>&1 && bat cache --build || true
	@echo "✅ Stow complete. Backups in $$BACKUP_DIR"

uninstall:
	stow -D zsh tmux kitty starship nvim git fzf shell bat

reinstall:
	@$(MAKE) normalize-stow-links
	stow -R zsh tmux kitty starship nvim git fzf shell bat
	@command -v bat >/dev/null 2>&1 && bat cache --build || true

hydrate:
	@bash -lc '\
	set -euo pipefail; \
	read_secret() { \
		key="$$1"; \
		if command -v op >/dev/null 2>&1 && op account list >/dev/null 2>&1; then \
			op item get "$$key" --vault="Employee" --fields label=notesPlain --reveal 2>/dev/null && return 0; \
		fi; \
		if command -v bw >/dev/null 2>&1; then \
			status="$$(bw status 2>/dev/null || true)"; \
			if printf "%s" "$$status" | grep -q "\"status\":\"unlocked\""; then \
				bw get item "$$key" 2>/dev/null | python3 -c "import json,sys; data=json.load(sys.stdin); data=data[0] if isinstance(data,list) and data else data; print(data.get(\"notes\",\"\"), end=\"\")" && return 0; \
			fi; \
		fi; \
		return 1; \
	}; \
	write_secret() { \
		key="$$1"; dest="$$2"; \
		content="$$(read_secret "$$key" || true)"; \
		if [ -n "$$content" ]; then \
			echo "  → Hydrating $$dest"; \
			mkdir -p "$$(dirname "$$dest")"; \
			printf "%s\n" "$$content" > "$$dest"; \
			chmod 600 "$$dest"; \
		fi; \
	}; \
	echo "💧 Hydrating local config files..."; \
	write_secret F_AWS_CONFIG "$$HOME/.aws/config"; \
	write_secret F_AWS_CREDENTIALS "$$HOME/.aws/credentials"; \
	write_secret F_KUBECONFIG "$$HOME/.kube/config"; \
	write_secret F_SSH_PRIVATE_KEY "$$HOME/.ssh/id_ed25519"; \
	write_secret F_SSH_PUBLIC_KEY "$$HOME/.ssh/id_ed25519.pub"; \
	write_secret F_GITCONFIG_MABYDUCK "$$HOME/.gitconfig-mabyduck"; \
	write_secret F_GITCONFIG_DEVELOPERFY "$$HOME/.gitconfig-developerfy"; \
	write_secret F_GITCONFIG_PERSONAL "$$HOME/.gitconfig-personal"; \
	echo "✅ Hydration complete."; \
	'

check-format:
	@command -v shfmt >/dev/null 2>&1 || { echo "shfmt not found"; exit 1; }
	@files="$$(git ls-files '*.sh')"; \
	if [ -n "$$files" ]; then \
	  shfmt -d -i 2 -ci -sr -ln bash $$files; \
	fi

check-shell:
	@command -v shellcheck >/dev/null 2>&1 || { echo "shellcheck not found"; exit 1; }
	@files="$$(git ls-files '*.sh')"; \
	if [ -n "$$files" ]; then \
	  shellcheck -x $$files; \
	fi

check-zsh-syntax:
	@zsh -n zsh/.zshrc shell/.zprofile shell/.zshenv

check-secrets:
	@./scripts/check-sensitive.sh

test:
	@python3 ./scripts/test_e2e.py

tune-docker:
	@./scripts/tune-docker-cli.sh
	@./scripts/tune-docker-desktop-macos.sh

ci: check-format check-shell check-zsh-syntax check-secrets test

status:
	@echo "Checking symlink status..."
	@ls -la ~/{.zshrc,.tmux.conf,.gitconfig} 2>/dev/null | grep -E "\.dotfiles" || echo "Some configs not linked"
	@echo ""
	@echo "Checking installed packages..."
	@command -v git >/dev/null && echo "✅ git installed" || echo "❌ git not installed"
	@command -v nvim >/dev/null && echo "✅ neovim installed" || echo "❌ neovim not installed"
	@command -v tmux >/dev/null && echo "✅ tmux installed" || echo "❌ tmux not installed"
	@command -v starship >/dev/null && echo "✅ starship installed" || echo "❌ starship not installed"
	@command -v fzf >/dev/null && echo "✅ fzf installed" || echo "❌ fzf not installed"
