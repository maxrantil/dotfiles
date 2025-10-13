# Dotfiles

Minimal dotfiles for Ubuntu servers. Optimized for development over SSH.

## Quick Install

```bash
git clone https://github.com/maxrantil/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## Post-Install Setup

### Git User Configuration

The dotfiles include a shared `.gitconfig` but require you to set your personal information:

```bash
# Copy the example template
cp ~/.dotfiles/.gitconfig.local.example ~/.gitconfig.local

# Edit with your information
vim ~/.gitconfig.local
# Set: name, email, and optionally GPG signingkey
```

This keeps your personal information private and out of the tracked repository.

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

### Automated CI Testing

Every pull request automatically runs:
- **ShellCheck** - Linting for shell scripts
- **shfmt** - Shell formatting validation
- **Installation Test** - Verifies install.sh creates all required symlinks (~30 seconds)

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

### Maintaining CI Tests

When modifying `install.sh`:

**Adding critical symlinks** (required for shell function):
1. Add symlink creation to `install.sh`
2. Update `.github/workflows/shell-quality.yml` verification step
3. Document why it's critical in workflow comments

**Adding optional symlinks** (enhancements):
1. Add symlink creation to `install.sh`
2. No CI update needed (tested in VM tier)
3. Document as optional in workflow comments

**Critical vs Optional:**
- **Critical**: Shell won't function without it (.zshrc, .aliases, nvim, tmux, starship)
- **Optional**: Nice-to-have enhancements (.gitconfig, .zprofile, inputrc, shortcuts)

### Troubleshooting Installation Test Failures

**CI Error: "ERROR: .zshrc not linked"**
- **Cause**: install.sh failed to create expected symlink
- **Debug**: Run `bash install.sh` in clean test directory
- **Check**: Verify source file exists in repository

**CI Error: "ERROR: Found broken symlinks"**
- **Cause**: Symlink points to non-existent file
- **Debug**: Check if target file was renamed/removed in recent commits
- **Fix**: Update install.sh symlink path or restore missing file

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

## Troubleshooting

Having issues? See the [Troubleshooting Guide](TROUBLESHOOTING.md) for solutions to common problems.

---

_Last updated: 2025-10-13_
