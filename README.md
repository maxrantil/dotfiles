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

## Development & Testing

### Quick Testing (30 seconds)

```bash
# Run automated tests
./tests/docker-test.sh

# Interactive shell for debugging
./tests/docker-test.sh --interactive
```

**Tests include:**
- Shell startup verification
- Starship caching validation
- Dotfiles symlink creation
- Performance measurements

### Full Integration Testing

For comprehensive VM-based testing, see the [vm-infra repository](https://github.com/maxrantil/vm-infra).

```bash
# Test with local dotfiles (from vm-infra repo)
./provision-vm.sh test-vm --test-dotfiles ../dotfiles
```

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
