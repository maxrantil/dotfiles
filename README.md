# Dotfiles

Minimal symlink-based dotfiles for SSH development. XDG-compliant, distro-aware, <100ms startup.

## What's Inside

**Shell Environment:**
- `.zshrc` - Zsh config with vi mode, starship prompt, fzf integration
- `.zprofile` - Zsh profile (login shell setup)
- `.aliases` - Shell aliases with distro detection (Debian/Arch)
- `distro/` - Distro-specific aliases (apt/pacman)
- `inputrc` - Readline configuration

**Development Tools:**
- `init.vim` - Neovim config (Gruvbox, git, FZF, linting)
- `.tmux.conf` - Tmux config (backtick prefix, vim nav, persistence)
- `.gitconfig` - Git config with delta pager, shortcuts (gs, ga, gc)
- `.gitconfig.local.example` - Template for personal git info
- `starship.toml` - Starship prompt configuration

**Bookmark System:**
- `bm-dirs` - Directory bookmarks (cf → ~/.config)
- `bm-files` - File bookmarks (ez → ~/.zshrc)
- `generate-shortcuts.sh` - Auto-generate shortcuts from bookmarks

**Management:**
- `install.sh` - Symlink installer with automatic backups
- `rollback.sh` - Restore from backup
- `tests/` - Docker-based automated testing

## Quick Install

```bash
git clone https://github.com/maxrantil/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh

# Set your git identity
cp .gitconfig.local.example ~/.gitconfig.local
vim ~/.gitconfig.local  # Add name, email, GPG key
```

## Daily Usage

```bash
# Edit dotfiles (auto-tracked via symlinks)
ez              # Edit .zshrc
vim ~/.dotfiles/.aliases
git -C ~/.dotfiles add . && git -C ~/.dotfiles commit -m "update" && git -C ~/.dotfiles push

# Sync on other machines
git -C ~/.dotfiles pull

# Tmux sessions
ts project      # New session
` d             # Detach (backtick + d)
ta project      # Re-attach

# Rollback if needed
./rollback.sh   # Interactive restore from backup
```

## Testing

```bash
# Quick Docker test (30s)
./tests/docker-test.sh

# Interactive debugging
./tests/docker-test.sh --interactive

# VM integration test (5min, from vm-infra repo)
./provision-vm.sh test-vm --test-dotfiles ../dotfiles
```

**CI automatically runs:** ShellCheck, shfmt, installation tests on every PR.

## Key Features

- **Fast** - <100ms shell startup with prompt caching
- **Secure** - Pre-commit hooks (shellcheck, shfmt, gitleaks)
- **Vi everywhere** - Consistent keybindings (zsh/tmux/vim)
- **Tmux ready** - Sessions persist through SSH disconnects
- **XDG compliant** - .zshrc lives in $XDG_CONFIG_HOME/zsh

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

---

_Minimal by design. Personal use only._
