# Troubleshooting Guide

This guide covers common issues and their solutions for the dotfiles repository.

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [Shell Issues](#shell-issues)
3. [Tmux Issues](#tmux-issues)
4. [Neovim Issues](#neovim-issues)
5. [Git Issues](#git-issues)
6. [Bookmark Issues](#bookmark-issues)
7. [FZF Issues](#fzf-issues)
8. [Performance Issues](#performance-issues)
9. [General Debugging](#general-debugging)

---

## Installation Issues

### Problem: `./install.sh` shows "Permission denied"

**Solution:**
```bash
chmod +x ~/.dotfiles/install.sh
./install.sh
```

### Problem: Installation fails with "ln: failed to create symbolic link"

**Cause:** Target files already exist and weren't backed up properly.

**Solution:**
```bash
# Manually backup existing files
mkdir -p ~/.dotfiles-backup
mv ~/.zshrc ~/.dotfiles-backup/
mv ~/.tmux.conf ~/.dotfiles-backup/
mv ~/.aliases ~/.dotfiles-backup/

# Re-run installation
cd ~/.dotfiles
./install.sh
```

### Problem: "command not found: git" during clone

**Cause:** Git not installed on system.

**Solution:**
```bash
# Debian/Ubuntu
sudo apt-get update && sudo apt-get install -y git

# Arch Linux
sudo pacman -S git
```

### Problem: Install succeeds but configs don't load

**Cause:** Shell not restarted or wrong shell active.

**Solution:**
```bash
# Check current shell
echo $SHELL

# If not zsh, set as default
chsh -s $(which zsh)

# Logout and login again, or:
exec zsh
```

---

## Shell Issues

### Problem: Zsh configuration not loading

**Symptoms:** No custom prompt, aliases don't work, vi-mode missing.

**Solution:**
```bash
# 1. Verify .zshrc is linked correctly
ls -la ~/.zshrc
# Should show: .zshrc -> /path/to/.dotfiles/.zshrc

# 2. Manually source to check for errors
source ~/.zshrc

# 3. Check for syntax errors
zsh -n ~/.zshrc

# 4. Reload shell
exec zsh
```

**Reference:** `.zshrc` (main configuration file)

### Problem: Vi-mode not working in zsh

**Symptoms:** Escape key doesn't enter normal mode, can't use vim motions.

**Solution:**
```bash
# 1. Verify vi-mode is enabled
grep "bindkey -v" ~/.zshrc

# 2. Check key timeout (should be low for responsive mode switching)
grep "KEYTIMEOUT" ~/.zshrc

# 3. Test manually
bindkey -v
```

**Reference:** `.zshrc:14` (vi-mode configuration)

### Problem: Prompt not showing or showing wrong information

**Cause:** Starship not installed or not in PATH.

**Solution:**
```bash
# 1. Check if starship is installed
command -v starship

# 2. If not found, install starship
# Via cargo (recommended):
cargo install starship

# Via package manager:
# Debian/Ubuntu: Download from https://starship.rs
# Arch: pacman -S starship

# 3. Verify starship cache exists
ls -la ~/.cache/starship/

# 4. Reload configuration
source ~/.zshrc
```

**Reference:** `.zshrc:10` (starship initialization), `starship.toml` (prompt configuration)

### Problem: Distro-specific aliases not loading

**Symptoms:** Package manager aliases missing (e.g., `i`, `s`, `up`).

**Solution:**
```bash
# 1. Check distro detection
cat ~/.cache/zsh/distro

# 2. If wrong or missing, regenerate
rm ~/.cache/zsh/distro
source ~/.zshrc

# 3. Verify distro files exist
ls -la ~/.dotfiles/distro/debian/.aliases_debian
ls -la ~/.dotfiles/distro/arch/.aliases_arch

# 4. Check if correct file is sourced
grep "aliases_debian\|aliases_arch" ~/.zshrc
```

**Reference:** `.zshrc:99-109` (distro detection and loading)

---

## Tmux Issues

### Problem: Tmux plugins not working

**Cause:** TPM (Tmux Plugin Manager) not installed.

**Solution:**
```bash
# 1. Install TPM
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# 2. Start tmux
tmux

# 3. Install plugins (inside tmux)
# Press: ` + I (backtick, then capital I)

# 4. Verify plugins loaded
ls -la ~/.tmux/plugins/
```

**Reference:** `.tmux.conf:59-65` (plugin configuration)

### Problem: Colors look wrong in tmux

**Cause:** Terminal not reporting 256-color support.

**Solution:**
```bash
# 1. Check color support outside tmux
echo $TERM
# Should be: xterm-256color or similar

# 2. Start tmux with correct TERM
tmux -2

# 3. Inside tmux, verify colors
echo $TERM
# Should be: screen-256color or tmux-256color

# 4. Add to .zshrc if needed:
export TERM=xterm-256color
```

**Reference:** `.tmux.conf:1` (default terminal setting)

### Problem: Backtick prefix not working

**Symptoms:** Can't use tmux commands with ` (backtick).

**Solution:**
```bash
# 1. Verify prefix is set
tmux show-options -g prefix
# Should show: prefix `

# 2. If wrong, reload tmux config
tmux source-file ~/.tmux.conf

# 3. Alternative: use default Ctrl+B temporarily
# Press: Ctrl+B, then : (colon)
# Type: source-file ~/.tmux.conf
```

**Reference:** `.tmux.conf:4` (prefix configuration)

### Problem: Tmux sessions not persisting

**Cause:** tmux-resurrect plugin not installed or not working.

**Solution:**
```bash
# 1. Verify plugin is listed
grep "resurrect" ~/.tmux.conf

# 2. Install plugins (see "Tmux plugins not working" above)

# 3. Save session manually
# Inside tmux: ` + Ctrl+s

# 4. Restore session
# Inside tmux: ` + Ctrl+r

# 5. Check saved sessions
ls -la ~/.tmux/resurrect/
```

**Reference:** `.tmux.conf:60` (tmux-resurrect plugin)

---

## Neovim Issues

### Problem: Neovim plugins missing

**Cause:** vim-plug not installed or plugins not installed.

**Solution:**
```bash
# 1. Check if vim-plug exists
ls -la ~/.config/nvim/autoload/plug.vim

# 2. If missing, init.vim should auto-download on first run
nvim +PlugInstall +qall

# 3. Manually install vim-plug if needed
curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

# 4. Install plugins
nvim +PlugInstall +qall
```

**Reference:** `init.vim:9-11` (vim-plug auto-installation)

### Problem: vim-plug shows errors

**Symptoms:** PlugInstall fails, plugins won't download.

**Solution:**
```bash
# 1. Check internet connectivity
curl -I https://github.com

# 2. Clean plugin directory
rm -rf ~/.config/nvim/plugged/*

# 3. Reinstall plugins
nvim +PlugInstall +qall

# 4. Check for specific plugin errors
nvim +checkhealth
```

**Reference:** `init.vim:16-23` (plugin definitions)

### Problem: Gruvbox colorscheme not working

**Cause:** Plugin not installed or terminal doesn't support colors.

**Solution:**
```bash
# 1. Verify gruvbox plugin installed
ls -la ~/.config/nvim/plugged/gruvbox/

# 2. Install if missing
nvim +PlugInstall +qall

# 3. Check terminal colors (see Tmux color issues above)

# 4. Force gruvbox in init.vim
nvim ~/.config/nvim/init.vim
# Verify line: colorscheme gruvbox
```

**Reference:** `init.vim:17` (gruvbox plugin), `init.vim:26` (colorscheme activation)

---

## Git Issues

### Problem: Delta pager not working

**Symptoms:** Git diff shows plain text without syntax highlighting.

**Cause:** Delta not installed or not in PATH.

**Solution:**
```bash
# 1. Check if delta is installed
command -v delta

# 2. Install delta
# Via cargo:
cargo install git-delta

# Via package manager:
# Debian/Ubuntu: Download from https://github.com/dandavison/delta/releases
# Arch: pacman -S git-delta

# 3. Verify git config
git config --get core.pager
# Should show: delta

# 4. Test delta
git diff
```

**Reference:** `.gitconfig:2-3` (delta pager configuration)

### Problem: Git aliases not working

**Symptoms:** Commands like `gs`, `ga`, `gc` show "command not found".

**Solution:**
```bash
# 1. Verify .gitconfig is linked
ls -la ~/.gitconfig
# Should show: .gitconfig -> /path/to/.dotfiles/.gitconfig

# 2. Check git config loaded
git config --get alias.s
# Should show: status

# 3. If not linked, reinstall
cd ~/.dotfiles
./install.sh

# 4. Test aliases
git s  # Should run git status
```

**Reference:** `.gitconfig:7-32` (git alias definitions)

### Problem: Git colors not showing

**Cause:** Color support disabled in git config.

**Solution:**
```bash
# 1. Enable colors
git config --global color.ui auto

# 2. Verify delta configuration
git config --list | grep delta

# 3. Check terminal colors (see Tmux section above)
```

**Reference:** `.gitconfig:34-48` (delta color configuration)

---

## Bookmark Issues

### Problem: Bookmark shortcuts not working

**Symptoms:** Commands like `cf`, `sc`, `dt` show "command not found".

**Cause:** Shortcuts not generated or not sourced.

**Solution:**
```bash
# 1. Generate shortcuts
cd ~/.dotfiles
./generate-shortcuts.sh

# 2. Verify output file exists
ls -la ~/.config/shell/shortcuts

# 3. Check if sourced in .zshrc
grep "shortcuts" ~/.zshrc

# 4. Manually source
source ~/.config/shell/shortcuts

# 5. Reload shell
source ~/.zshrc
```

**Reference:** `generate-shortcuts.sh` (shortcut generator), `.zshrc:95` (shortcuts sourcing)

### Problem: Bookmark paths are wrong

**Cause:** Paths in `bm-files` or `bm-dirs` don't match actual file locations.

**Solution:**
```bash
# 1. Edit bookmark files
vim ~/.dotfiles/bm-files
vim ~/.dotfiles/bm-dirs

# 2. Update paths to actual locations
# Example:
# cfz  ~/.dotfiles/.aliases  # Not ~/.config/shell/aliasrc

# 3. Regenerate shortcuts
cd ~/.dotfiles
./generate-shortcuts.sh

# 4. Reload shell
source ~/.zshrc
```

**Reference:** `bm-files`, `bm-dirs` (bookmark definitions)

### Problem: Changes to bookmarks don't take effect

**Cause:** Shortcuts not regenerated after editing bookmark files.

**Solution:**
```bash
# Always regenerate after editing bookmarks
cd ~/.dotfiles
vim bm-files  # Make changes
./generate-shortcuts.sh  # Regenerate
source ~/.zshrc  # Reload
```

**Reference:** `generate-shortcuts.sh:13` (bookmark processing)

---

## FZF Issues

### Problem: Ctrl+R history search not working

**Cause:** FZF not installed or keybinding not loaded.

**Solution:**
```bash
# 1. Check if fzf is installed
command -v fzf

# 2. Install fzf
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install

# 3. Verify fzf.zsh exists and is sourced
ls -la ~/.fzf.zsh
grep "fzf.zsh" ~/.zshrc

# 4. Reload shell
source ~/.zshrc

# 5. Test Ctrl+R
# Press Ctrl+R and start typing
```

**Reference:** `.zshrc:91` (fzf sourcing)

### Problem: FZF preview not showing in functions

**Symptoms:** `ff` function doesn't show file preview.

**Cause:** Preview command failing or bat/cat not available.

**Solution:**
```bash
# 1. Test preview manually
fzf --preview 'cat {}'

# 2. Install bat for better previews (optional)
# Debian/Ubuntu:
sudo apt-get install bat
# Arch:
sudo pacman -S bat

# 3. Update ff function to use bat
vim ~/.dotfiles/.aliases
# Change: --preview 'cat {}' to --preview 'bat --color=always {}'
```

**Reference:** `.aliases:43` (ff function definition)

---

## Performance Issues

### Problem: Shell startup is slow (>1 second)

**Symptoms:** Noticeable delay when opening new terminal.

**Diagnostic:**
```bash
# Measure startup time
time zsh -i -c exit

# Profile startup to find bottlenecks
zsh -i -c 'zmodload zsh/zprof; source ~/.zshrc; zprof'
```

**Solutions:**

**1. Enable compinit caching:**
```bash
# Add to .zshrc before compinit call:
autoload -U compinit
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C
fi
```
**Impact:** 100-200ms improvement

**2. Verify starship caching is enabled:**
```bash
# Check cache directory
ls -la ~/.cache/starship/

# Regenerate if needed
rm -rf ~/.cache/starship/
source ~/.zshrc
```
**Reference:** `.zshrc:10` (starship caching)

**Impact:** 50-100ms improvement

**3. Check distro detection caching:**
```bash
# Verify cache exists
cat ~/.cache/zsh/distro

# Should contain: debian or arch
# If missing, it regenerates on every startup
```
**Reference:** `.zshrc:99-109` (distro caching)

**Impact:** 20-30ms improvement

**4. Lazy-load heavy tools (NVM, if installed):**
```bash
# If you have NVM installed, it can slow startup by 200-400ms
# Consider lazy loading (beyond scope of default config)
```

### Problem: Tmux feels sluggish

**Cause:** Too many plugins or escape-time too high.

**Solution:**
```bash
# 1. Check escape time
tmux show-options -g escape-time
# Should be: 0 or very low

# 2. Reduce if needed
echo "set -sg escape-time 0" >> ~/.tmux.conf
tmux source-file ~/.tmux.conf

# 3. Disable unnecessary plugins
vim ~/.tmux.conf
# Comment out plugins you don't use
```

**Reference:** `.tmux.conf:14` (escape-time configuration)

### Problem: Git operations are slow

**Cause:** Delta processing large diffs or repository issues.

**Solution:**
```bash
# 1. Disable delta temporarily for large repos
git config --local core.pager less

# 2. Or increase delta performance
git config --global delta.max-line-length 1024

# 3. Check repository health
git fsck
git gc
```

---

## General Debugging

### How to find which config file is causing issues

**Method 1: Binary search**
```bash
# 1. Comment out half of .zshrc
vim ~/.zshrc
# Comment lines and reload:
source ~/.zshrc

# 2. If issue persists, problem is in other half
# If issue disappears, problem is in commented section
# Repeat until isolated
```

**Method 2: Start with minimal config**
```bash
# 1. Temporarily rename configs
mv ~/.zshrc ~/.zshrc.backup
mv ~/.zprofile ~/.zprofile.backup

# 2. Create minimal .zshrc
echo "# Minimal test" > ~/.zshrc

# 3. Add back sections one at a time
# Test after each addition:
source ~/.zshrc
```

### How to check if files are properly linked

```bash
# Verify all symlinks
ls -la ~/.zshrc ~/.tmux.conf ~/.aliases ~/.gitconfig ~/.zprofile

# Should all show: file -> /path/to/.dotfiles/file

# If not linked, reinstall
cd ~/.dotfiles
./install.sh
```

### How to completely reset dotfiles

```bash
# 1. Backup current state
mkdir -p ~/dotfiles-backup-$(date +%Y%m%d)
cp -r ~/.dotfiles ~/dotfiles-backup-$(date +%Y%m%d)/

# 2. Remove symlinks
rm -f ~/.zshrc ~/.tmux.conf ~/.aliases ~/.gitconfig ~/.zprofile
rm -f ~/.config/nvim/init.vim

# 3. Remove dotfiles directory
rm -rf ~/.dotfiles

# 4. Fresh install
git clone https://github.com/maxrantil/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh

# 5. Restart shell
exec zsh
```

### How to check for syntax errors

```bash
# Zsh configs
zsh -n ~/.zshrc
zsh -n ~/.zprofile
zsh -n ~/.dotfiles/.aliases

# Shell scripts
bash -n ~/.dotfiles/install.sh
bash -n ~/.dotfiles/generate-shortcuts.sh

# Tmux config
tmux source-file ~/.tmux.conf
# Will show errors if any

# Neovim config
nvim +checkhealth
```

### How to enable verbose logging

```bash
# Zsh startup debugging
zsh -xv ~/.zshrc 2>&1 | less
# Shows every command executed during startup

# Tmux debugging
tmux -vv
# Shows verbose output

# Git debugging
GIT_TRACE=1 git status
# Shows git internals
```

### Where to find log files

```bash
# Zsh history
~/.cache/zsh/history

# Tmux resurrect saves
~/.tmux/resurrect/

# Neovim plugin logs
~/.local/share/nvim/

# Starship cache
~/.cache/starship/

# General shell cache
~/.cache/zsh/
```

---

## Getting Additional Help

If you've tried the solutions above and still have issues:

1. **Check Prerequisites:**
   - Verify all required tools are installed: zsh, tmux, neovim, git, fzf
   - Ensure you have write access to `$HOME` directory
   - Confirm your terminal supports 256 colors

2. **Run Docker Tests:**
   ```bash
   cd ~/.dotfiles
   ./tests/docker-test.sh
   ```
   This validates the dotfiles in a clean environment.

3. **Review Recent Changes:**
   ```bash
   cd ~/.dotfiles
   git log --oneline -10
   git diff HEAD~1
   ```
   Recent changes might have introduced issues.

4. **Create GitHub Issue:**
   Visit https://github.com/maxrantil/dotfiles/issues and provide:
   - Output of `uname -a` (system info)
   - Output of `zsh --version`
   - Output of `time zsh -i -c exit` (startup time)
   - Error messages (full output)
   - Steps to reproduce

---

## Quick Reference

**Essential Commands:**
- Reload zsh: `source ~/.zshrc` or `exec zsh`
- Reload tmux: `tmux source-file ~/.tmux.conf`
- Reinstall dotfiles: `cd ~/.dotfiles && ./install.sh`
- Run tests: `cd ~/.dotfiles && ./tests/docker-test.sh`

**Key Files:**
- `.zshrc` - Main shell configuration
- `.zprofile` - Shell environment variables
- `.aliases` - Shared aliases and functions
- `.tmux.conf` - Tmux configuration
- `init.vim` - Neovim configuration
- `.gitconfig` - Git configuration
- `starship.toml` - Prompt configuration

**Cache Locations:**
- Zsh: `~/.cache/zsh/`
- Starship: `~/.cache/starship/`
- Tmux plugins: `~/.tmux/plugins/`
- Neovim plugins: `~/.config/nvim/plugged/`
