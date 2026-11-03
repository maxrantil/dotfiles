# Dotfiles

Minimal symlink-based dotfiles for SSH development. XDG-compliant, distro-aware, ~10ms shell startup.

## What's Inside

**Shell Environment:**
- `.zshenv` - Environment for every zsh (XDG paths, ZDOTDIR, PATH, EDITOR)
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
- `bm-files` - File bookmarks (cfz → $ZDOTDIR/.zshrc)
- `generate-shortcuts.sh` - Auto-generate shortcuts from bookmarks

**Management:**
- `install.sh` - Symlink installer with automatic backups (safe to re-run, `--dry-run`)
- `rollback.sh` - Restore files from the latest backup to their original paths
- `lib/common.sh` - Link list shared by install and rollback
- `tests/` - Install, rollback and zsh config suites, plus Docker fresh-machine tests

## Quick Install

Needs `git` and `zsh` (plus optionally `neovim tmux fzf starship`):

```bash
git clone https://github.com/maxrantil/dotfiles.git ~/.dotfiles && ~/.dotfiles/install.sh
chsh -s "$(command -v zsh)"   # then log out and back in

# Preview first if you like: ~/.dotfiles/install.sh --dry-run

# Set your git identity
cp .gitconfig.local.example ~/.gitconfig.local
vim ~/.gitconfig.local  # Add name, email, GPG key
```

## Daily Usage

```bash
# Edit dotfiles (auto-tracked via symlinks)
cfz             # Edit .zshrc
vim ~/.dotfiles/.aliases
git -C ~/.dotfiles add . && git -C ~/.dotfiles commit -m "update" && git -C ~/.dotfiles push

# Sync on other machines
git -C ~/.dotfiles pull

# Tmux sessions
ts project      # New session
` d             # Detach (backtick + d)
ta project      # Re-attach

# Rollback if needed
./rollback.sh   # Interactive restore from backup (--dry-run to preview, -y in scripts)
```

## Testing

```bash
# Local suites (need zsh)
./tests/installation-test.sh
./tests/roundtrip-test.sh      # install -> rollback restores files in place
./tests/rollback-test.sh
./tests/zsh-config-test.sh     # safe_source checks, env hygiene, startup budget

# Fresh machine in Docker (Ubuntu 24.04 or Arch), as a non-root user
./tests/docker-test.sh --distro ubuntu
./tests/docker-test.sh --distro arch --interactive

# VM integration test (5min, from vm-infra repo)
./provision-vm.sh test-vm --test-dotfiles ../dotfiles
```

**CI automatically runs:** ShellCheck, shfmt, all test suites, and the Docker fresh-machine install on Ubuntu and Arch on every PR that touches shell files.

## Key Features

- **Fast** - ~10ms shell startup: no external processes at startup, cached prompt and completions
- **Secure** - Files are only sourced after ownership/permission checks; pre-commit hooks (shellcheck, gitleaks); CI actions pinned to commit SHAs
- **Vi everywhere** - Consistent keybindings (zsh/tmux/vim)
- **Tmux ready** - Sessions persist through SSH disconnects
- **XDG compliant** - .zshrc and .zprofile live in $XDG_CONFIG_HOME/zsh (ZDOTDIR)

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues and solutions.

---

_Minimal by design. Personal use only._
