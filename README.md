# Dotfiles

Minimal dotfiles for Ubuntu servers. Optimized for development over SSH.

## Quick Install

```bash
git clone https://github.com/maxrantil/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## What's Included

- **Zsh** - Vi mode, starship prompt, fzf, auto-detects distro
- **Tmux** - Backtick prefix, vim navigation, session persistence
- **Neovim** - Gruvbox theme, git integration, FZF, linting
- **Git** - Delta pager, shortcuts (gs, ga, gc, etc.)
- **Bookmarks** - Quick navigation (cf → ~/.config, sc → ~/.local/bin)

## Key Features

- **Symlink-based** - Edit once, auto-tracked in git
- **Distro-aware** - Debian (apt) and Arch (pacman) aliases
- **Tmux ready** - Persistent sessions survive SSH disconnects
- **Vi everywhere** - Consistent keybindings across zsh/tmux/vim

## Usage

```bash
# Update dotfiles
cd ~/.dotfiles
vim .aliases
git add . && git commit -m "update" && git push

# Sync on other machines
cd ~/.dotfiles && git pull
```

## Tmux Quick Start

```bash
ts project        # New session
` d               # Detach (backtick + d)
ta project        # Re-attach
```

Symlinks keep everything in sync. No reinstall needed.
