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

## CI/CD Workflows

### Pull Request Checks

All PRs to `master` branch run the following automated checks:

#### 1. Shell Quality Validation
**Workflow**: `.github/workflows/shell-quality.yml`

Validates shell scripts using:
- **ShellCheck**: Syntax errors, dangerous patterns, best practices
- **shfmt**: Formatting consistency (4-space indent, canonical indentation)

**Files checked**:
- `install.sh`
- `generate-shortcuts.sh`
- `tests/*.sh`

**Run locally**:
```bash
# ShellCheck
shellcheck install.sh generate-shortcuts.sh tests/*.sh

# shfmt (check)
shfmt -d -i 4 -ci -sr install.sh generate-shortcuts.sh tests/*.sh

# shfmt (fix)
shfmt -w -i 4 -ci -sr install.sh generate-shortcuts.sh tests/*.sh
```

---

#### 2. Conventional Commit Format
**Workflow**: `.github/workflows/commit-format.yml`

Enforces conventional commit message format:
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation changes
- `style:` - Code style changes
- `refactor:` - Code refactoring
- `test:` - Test additions/changes
- `chore:` - Maintenance tasks
- `perf:` - Performance improvements
- `ci:` - CI/CD changes
- `build:` - Build system changes
- `revert:` - Revert previous commits

**Examples**:
```bash
git commit -m "feat: add support for Arch Linux"
git commit -m "fix: correct symlink path for .zshrc"
git commit -m "docs: update installation instructions"
```

**Run locally**: Pre-commit hook validates commits automatically

---

#### 3. Block AI Attribution
**Workflow**: `.github/workflows/block-ai-attribution.yml`

Prevents AI/agent attribution markers in commits per CLAUDE.md policy:
- Blocks `Co-authored-by: Claude` or similar
- Blocks "Generated with Claude Code" messages
- Ensures clean commit history

**Note**: This is automatically enforced; no local command needed.

---

#### 4. Pre-commit Hooks
**Workflow**: `.github/workflows/pre-commit-check.yml`

Validates that pre-commit hooks were not bypassed with `--no-verify`:
- Runs all pre-commit hooks in CI
- Catches issues that might have been skipped locally
- Ensures consistent code quality

---

### Pre-commit Hooks vs CI

**Pre-commit** (local):
- Runs on every commit
- Fast feedback (<5 seconds)
- Can be bypassed with `--no-verify` (NOT RECOMMENDED)
- Developer-focused

**GitHub Actions** (CI):
- Runs on every PR
- Enforcement layer (catches `--no-verify` bypasses)
- Cannot be bypassed
- Production-focused

**Best Practice**: Let pre-commit fix issues automatically, CI validates

---

### Running All Checks Locally

```bash
# Install pre-commit
pip install pre-commit
pre-commit install

# Run all checks
pre-commit run --all-files

# ShellCheck only
pre-commit run shellcheck --all-files

# shfmt only (check)
shfmt -d -i 4 -ci -sr $(find . -name "*.sh")

# shfmt only (fix)
shfmt -w -i 4 -ci -sr $(find . -name "*.sh")
```

---

### Workflow Status

Check workflow status in GitHub:
- PR page → "Checks" tab
- Click workflow name for details
- Expand failed steps for error messages

---

### Troubleshooting Failed Checks

**ShellCheck failures**:
1. Read error message (includes SC code)
2. Look up SC code: https://www.shellcheck.net/wiki/
3. Fix issue in code
4. Re-run locally to verify
5. Push fix

**shfmt failures**:
1. Run `shfmt -d -i 4 -ci -sr <file>` to see diff
2. Run `shfmt -w -i 4 -ci -sr <file>` to auto-fix
3. Commit formatted file
4. Push

**Commit format failures**:
1. Amend commit message: `git commit --amend`
2. Use conventional format: `<type>: <description>`
3. Force push: `git push --force-with-lease`

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
