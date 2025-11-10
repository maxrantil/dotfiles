# Troubleshooting

Quick fixes for common issues.

## Installation

**Permission denied:**
```bash
chmod +x ~/.dotfiles/install.sh && ./install.sh
```

**Symlink creation fails:**
```bash
# Manually backup and retry
mkdir -p ~/.dotfiles-backup
mv ~/.zshrc ~/.tmux.conf ~/.aliases ~/.dotfiles-backup/
cd ~/.dotfiles && ./install.sh
```

**Configs don't load after install:**
```bash
# Verify shell
echo $SHELL  # Should be /bin/zsh or /usr/bin/zsh

# Switch if needed
chsh -s $(which zsh)
exec zsh
```

## Shell Issues

**Zsh config not loading:**
```bash
# Check symlink
ls -la ~/.zshrc  # Should point to ~/.dotfiles/.zshrc

# Test for errors
zsh -n ~/.zshrc
source ~/.zshrc

# Verify XDG path
echo $ZDOTDIR  # Should be ~/.config/zsh or empty
```

**Starship prompt missing:**
```bash
# Install starship
curl -sS https://starship.rs/install.sh | sh

# Or via package manager
# Arch: pacman -S starship
# Debian: download from https://starship.rs

# Verify cache exists
ls -la ~/.cache/starship/
```

**Distro aliases not working:**
```bash
# Check detection
cat ~/.cache/zsh/distro  # Should show "debian" or "arch"

# Regenerate if wrong
rm ~/.cache/zsh/distro && source ~/.zshrc
```

**Bookmark shortcuts not found:**
```bash
# Regenerate shortcuts
cd ~/.dotfiles && ./generate-shortcuts.sh

# Verify output
ls -la ~/.config/shell/shortcuts

# Reload
source ~/.zshrc
```

## Tmux

**Backtick prefix not working:**
```bash
# Reload config
tmux source-file ~/.tmux.conf

# Or use default prefix temporarily
# Ctrl+B, then : (colon), then type: source-file ~/.tmux.conf
```

**Colors look wrong:**
```bash
# Check TERM outside tmux
echo $TERM  # Should be xterm-256color

# Start tmux with color support
tmux -2

# Inside tmux, verify
echo $TERM  # Should be screen-256color or tmux-256color
```

**Plugins not working:**
```bash
# Install TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Inside tmux, press: ` + I (capital I)
```

## Neovim

**Plugins missing:**
```bash
# Auto-install vim-plug and plugins
nvim +PlugInstall +qall

# Or manually install vim-plug first
curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
```

**Colorscheme broken:**
```bash
# Reinstall gruvbox
nvim +PlugInstall +qall

# Check terminal colors (see Tmux section above)
```

## Git

**Delta pager not working:**
```bash
# Install delta
cargo install git-delta

# Or via package manager
# Arch: pacman -S git-delta
# Debian: download from https://github.com/dandavison/delta/releases

# Verify config
git config --get core.pager  # Should show "delta"
```

**Git aliases not working:**
```bash
# Verify symlink
ls -la ~/.gitconfig  # Should point to ~/.dotfiles/.gitconfig

# Test specific alias
git config --get alias.s  # Should show "status"

# Reinstall if broken
cd ~/.dotfiles && ./install.sh
```

## Performance

**Measure startup time:**
```bash
time zsh -i -c exit
# Target: <100ms

# Profile to find bottlenecks
zsh -i -c 'zmodload zsh/zprof; source ~/.zshrc; zprof'
```

**Slow startup fixes:**
```bash
# 1. Verify starship cache exists
ls -la ~/.cache/starship/

# 2. Check distro detection cache
cat ~/.cache/zsh/distro

# 3. Enable compinit caching (if not already)
# Add to .zshrc before compinit:
autoload -U compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
```

**Tmux sluggish:**
```bash
# Check escape time (should be 0)
tmux show-options -g escape-time

# Reduce if needed
echo "set -sg escape-time 0" >> ~/.tmux.conf
tmux source-file ~/.tmux.conf
```

## Debugging

**Find problematic config:**
```bash
# Binary search: comment out half of .zshrc, reload, repeat
vim ~/.zshrc
source ~/.zshrc

# Or start minimal
mv ~/.zshrc ~/.zshrc.backup
echo "# Test" > ~/.zshrc
# Add sections back one at a time
```

**Check syntax errors:**
```bash
# Zsh
zsh -n ~/.zshrc
zsh -n ~/.zprofile
zsh -n ~/.dotfiles/.aliases

# Shell scripts
bash -n ~/.dotfiles/install.sh

# Tmux
tmux source-file ~/.tmux.conf

# Neovim
nvim +checkhealth
```

**Verify symlinks:**
```bash
ls -la ~/.zshrc ~/.tmux.conf ~/.aliases ~/.gitconfig ~/.zprofile
# All should point to ~/.dotfiles/[file]

# Reinstall if broken
cd ~/.dotfiles && ./install.sh
```

**Verbose debugging:**
```bash
# Zsh startup trace
zsh -xv ~/.zshrc 2>&1 | less

# Tmux verbose
tmux -vv

# Git trace
GIT_TRACE=1 git status
```

## Complete Reset

```bash
# 1. Backup
mkdir -p ~/dotfiles-backup-$(date +%Y%m%d)
cp -r ~/.dotfiles ~/dotfiles-backup-$(date +%Y%m%d)/

# 2. Remove everything
rm -f ~/.zshrc ~/.tmux.conf ~/.aliases ~/.gitconfig ~/.zprofile
rm -f ~/.config/nvim/init.vim
rm -rf ~/.dotfiles

# 3. Fresh install
git clone https://github.com/maxrantil/dotfiles.git ~/.dotfiles
cd ~/.dotfiles && ./install.sh

# 4. Restart
exec zsh
```

## Quick Reference

**Reload configs:**
- `source ~/.zshrc` or `exec zsh`
- `tmux source-file ~/.tmux.conf`

**Test environment:**
- `cd ~/.dotfiles && ./tests/docker-test.sh`

**Key cache locations:**
- Zsh: `~/.cache/zsh/`
- Starship: `~/.cache/starship/`
- Tmux plugins: `~/.tmux/plugins/`
- Neovim plugins: `~/.config/nvim/plugged/`

---

_Most issues are fixed by: `cd ~/.dotfiles && ./install.sh && exec zsh`_
