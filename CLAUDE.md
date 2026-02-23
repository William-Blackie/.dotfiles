# CLAUDE.md

Dotfiles repo for macOS, managed with GNU Stow. Every file in a stow package directory maps 1:1 to its position under `$HOME`.

## How stow works

Each top-level directory is a stow "package." Running `stow <package>` from `~/.dotfiles/` creates symlinks in `$HOME`:

- `zsh/.zshrc` → `~/.zshrc`
- `kitty/.config/kitty/kitty.conf` → `~/.config/kitty/kitty.conf`
- `nvim/.config/nvim/` → `~/.config/nvim/`

To edit a config, edit the file inside `~/.dotfiles/` (or follow the symlink -- same effect). To add a new file to a package, place it at the correct relative path inside the package directory, then run `stow -R <package>`.

## Stow packages

| Package | Contents |
|---------|----------|
| `zsh` | `.zshrc` |
| `shell` | `.zprofile`, `.ripgreprc` |
| `tmux` | `.tmux.conf` |
| `kitty` | `.config/kitty/kitty.conf`, `.config/kitty/catppuccin-mocha.conf` |
| `starship` | `.config/starship.toml` |
| `nvim` | `.config/nvim/` (full LazyVim config) |
| `git` | `.gitconfig`, `.gitignore_global` |
| `bat` | `.config/bat/` |
| `fzf` | `.fzf.zsh` |

## Nvim details

LazyVim-based config. Plugin specs in `nvim/.config/nvim/lua/plugins/`. LazyVim extras are enabled in `lazyvim.json`.

Key points:
- `opts` in plugin specs gets deep-merged by lazy.nvim. Safe to use across multiple files for the same plugin.
- `config` in plugin specs **replaces** the entire setup function. Never use `config = function()` on `neovim/nvim-lspconfig` or other LazyVim-managed plugins unless you intend to replace their entire configuration.
- LazyVim extras (in `lazyvim.json`) already handle: eslint, python, typescript, docker, json, yaml, toml, sql, markdown, git, copilot, telescope, snacks_picker, prettier, black.
- Treesitter parsers are stored in `~/.local/share/nvim/site/`. If highlights break, delete `site/parser/`, `site/parser-info/`, and `site/queries/`, then run `:TSUpdate` in nvim.

## Rules

- All tools use Catppuccin Mocha. Keep the theme consistent.
- Don't add comments that just describe what the code does. Only comment non-obvious intent.
- The `.gitignore_global` should only contain OS/editor/IDE patterns. Language-specific ignores belong in project `.gitignore` files.
- Shell startup performance matters. nvm is lazy-loaded in `.zshrc` for this reason.
- Test tmux changes by running `prefix + R` (source config) or restarting tmux. Theme flavor changes require a full restart.

## Commands

```bash
cd ~/.dotfiles
make install          # Stow all packages
make uninstall        # Unstow all
make reinstall        # Re-stow (use after pulling changes)
make status           # Check symlinks and installed tools
make install-packages # Install all Homebrew dependencies
make setup            # Full setup (packages + stow + post-install)
```
