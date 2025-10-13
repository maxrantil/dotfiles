#!/bin/bash
# ABOUTME: Symlink-based dotfiles installer with automatic backup and XDG compliance
# Simple dotfiles installer - creates symlinks from home to repo

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

echo "=================================="
echo "  Dotfiles Installation"
echo "=================================="
echo ""
echo "Installing from: $DOTFILES_DIR"
echo ""

# Prerequisite checks
echo "Checking prerequisites..."

# Check write permissions
if [ ! -w "$HOME" ]; then
    echo "[ERROR] No write permission to home directory: $HOME" >&2
    exit 1
fi

# Check required commands
for cmd in ln mkdir mv rm; do
    if ! command -v "$cmd" > /dev/null 2>&1; then
        echo "[ERROR] Required command not found: $cmd" >&2
        exit 1
    fi
done

# Create required directories
for dir in "$HOME/.config" "$HOME/.config/shell" "$HOME/.config/nvim" "$HOME/.cache/zsh"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" || {
            echo "[ERROR] Failed to create directory: $dir" >&2
            exit 1
        }
        echo "[CREATE] Directory: $dir"
    fi
done

echo "[OK] Prerequisites verified"
echo ""

# Backup and link function
link_file() {
    local source="$1"
    local target="$2"

    # Backup if exists and is not a symlink
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mkdir -p "$BACKUP_DIR"
        echo "  Backing up existing $(basename "$target")"
        mv "$target" "$BACKUP_DIR/"
    fi

    # Remove old symlink if exists
    [ -L "$target" ] && rm "$target"

    # Create symlink
    ln -sf "$source" "$target"
    echo "[SUCCESS] Linked $(basename "$target")"
}

# Link dotfiles
link_file "$DOTFILES_DIR/.zprofile" "$HOME/.zprofile"
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.aliases" "$HOME/.aliases"

# Link inputrc for readline (bash, python REPL, etc.)
if [ -f "$DOTFILES_DIR/inputrc" ]; then
    link_file "$DOTFILES_DIR/inputrc" "$HOME/.config/shell/inputrc"
fi

# Link neovim config
if [ -f "$DOTFILES_DIR/init.vim" ]; then
    link_file "$DOTFILES_DIR/init.vim" "$HOME/.config/nvim/init.vim"
fi

# Link gitconfig if exists
if [ -f "$DOTFILES_DIR/.gitconfig" ]; then
    link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
fi

# Link tmux config
if [ -f "$DOTFILES_DIR/.tmux.conf" ]; then
    link_file "$DOTFILES_DIR/.tmux.conf" "$HOME/.tmux.conf"
fi

# Link starship config
if [ -f "$DOTFILES_DIR/starship.toml" ]; then
    link_file "$DOTFILES_DIR/starship.toml" "$HOME/.config/starship.toml"
fi

# Generate shortcuts from bookmarks
if [ -x "$DOTFILES_DIR/generate-shortcuts.sh" ]; then
    echo "Generating bookmark shortcuts"
    "$DOTFILES_DIR/generate-shortcuts.sh"
fi

echo ""
echo "=================================="
echo "[SUCCESS] Installation complete!"
echo "=================================="

[ -d "$BACKUP_DIR" ] && echo "Backups saved to: $BACKUP_DIR"

echo ""
echo "Next steps:"
echo "  1. Install zsh: sudo apt install zsh"
echo "  2. Set zsh as default: chsh -s \$(which zsh)"
echo "  3. Install starship: curl -sS https://starship.rs/install.sh | sh"
echo "  4. Install neovim: sudo apt install neovim"
echo "  5. Restart your shell or run: source ~/.zshrc"
echo ""
