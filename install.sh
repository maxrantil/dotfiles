#!/bin/bash
# ABOUTME: Symlink-based dotfiles installer with automatic backup and XDG compliance
# Creates symlinks from $HOME to this repo. Safe to re-run: correct links are left alone,
# anything else at a target path is moved into a timestamped backup (path preserved).

set -euo pipefail
umask 022

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$DOTFILES_DIR/lib/common.sh"

DRY_RUN=false

usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Symlink dotfiles from $DOTFILES_DIR into \$HOME.

Options:
  -n, --dry-run   Show what would change without touching anything
  -h, --help      Show this help

Existing files are moved to ~/${BACKUP_PREFIX}<timestamp>/ (restore with ./rollback.sh).
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        -n | --dry-run) DRY_RUN=true ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo "[ERROR] Unknown option: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
    shift
done

# Run a command, or just describe it in dry-run mode
run() {
    if [ "$DRY_RUN" = true ]; then
        echo "  [DRY RUN] $*"
    else
        "$@"
    fi
}

on_error() {
    echo "[ERROR] Installation failed at line $1. Nothing after this point was changed." >&2
    if [ -n "${BACKUP_DIR:-}" ] && [ -d "$BACKUP_DIR" ]; then
        echo "        Files moved so far are in $BACKUP_DIR (restore with ./rollback.sh)" >&2
    fi
}
trap 'on_error $LINENO' ERR

echo "=================================="
echo "  Dotfiles Installation"
echo "=================================="
echo ""
echo "Installing from: $DOTFILES_DIR"
[ "$DRY_RUN" = true ] && echo "Mode: dry run (no changes will be made)"
echo ""

echo "Checking prerequisites..."

if [ -z "${HOME:-}" ] || [ ! -d "$HOME" ]; then
    echo "[ERROR] HOME is not set to an existing directory" >&2
    exit 1
fi

if [ ! -w "$HOME" ]; then
    echo "[ERROR] No write permission to home directory: $HOME" >&2
    exit 1
fi

if [ "$(id -u)" -eq 0 ]; then
    echo "[WARNING] Running as root: dotfiles will be installed for root ($HOME)." >&2
fi

for cmd in ln mkdir mv rm readlink date; do
    if ! command -v "$cmd" > /dev/null 2>&1; then
        echo "[ERROR] Required command not found: $cmd" >&2
        exit 1
    fi
done

ZSH_CONFIG_DIR="$(resolve_zdotdir "$DOTFILES_DIR")"
case "$ZSH_CONFIG_DIR" in
    "$HOME" | "$HOME"/*) ;;
    *)
        echo "[ERROR] ZDOTDIR resolves outside \$HOME: $ZSH_CONFIG_DIR" >&2
        exit 1
        ;;
esac

for dir in "$HOME/.config" "$HOME/.config/shell" "$HOME/.config/nvim" "$HOME/.cache/zsh" "$ZSH_CONFIG_DIR"; do
    if [ ! -d "$dir" ]; then
        run mkdir -p "$dir"
        echo "[CREATE] Directory: $dir"
    fi
done

echo "[OK] Prerequisites verified"
echo ""

BACKUP_DIR="$HOME/${BACKUP_PREFIX}$(date +%Y%m%d_%H%M%S)"
BACKED_UP=0

# Move an existing target into the backup dir, keeping its path relative to $HOME
backup_target() {
    local target="$1" rel dest
    rel="${target#"$HOME"/}"
    dest="$BACKUP_DIR/$rel"

    if [ -e "$dest" ] || [ -L "$dest" ]; then
        echo "[ERROR] Backup destination already exists: $dest" >&2
        return 1
    fi

    echo "  Backing up existing $rel"
    run mkdir -p "$(dirname "$dest")"
    run mv "$target" "$dest"
    BACKED_UP=$((BACKED_UP + 1))
}

link_file() {
    local source="$1" target="$2" current

    if [ ! -e "$source" ]; then
        echo "[SKIP] $(basename "$source") not present in repo"
        return 0
    fi

    if [ -L "$target" ]; then
        current="$(readlink "$target")"
        if [ "$current" = "$source" ]; then
            echo "[OK] $(basename "$target") already linked"
            return 0
        fi
        # A link into another checkout of this repo (same file name, next to an
        # install.sh) is ours and gets replaced; any other symlink is backed up.
        if [ "$(basename "$current")" = "$(basename "$source")" ] &&
            [ -f "$(dirname "$current")/install.sh" ]; then
            run rm "$target"
        else
            backup_target "$target"
        fi
    elif [ -e "$target" ]; then
        if [ -d "$target" ]; then
            echo "[ERROR] $target is a directory; move it away and re-run" >&2
            return 1
        fi
        backup_target "$target"
    fi

    run ln -s "$source" "$target"
    echo "[SUCCESS] Linked $(basename "$target")"
}

while IFS=$'\t' read -r rel_source target; do
    link_file "$DOTFILES_DIR/$rel_source" "$target"
done < <(dotfiles_links "$ZSH_CONFIG_DIR")

# Remove links from older versions that point into a dotfiles checkout
while IFS=$'\t' read -r rel_source target; do
    if [ -L "$target" ] && [ "$(basename "$(readlink "$target")")" = "$rel_source" ] &&
        [ -f "$(dirname "$(readlink "$target")")/install.sh" ]; then
        run rm "$target"
        echo "[CLEANUP] Removed obsolete link ${target#"$HOME"/}"
    fi
done < <(dotfiles_legacy_links "$ZSH_CONFIG_DIR")

if [ -x "$DOTFILES_DIR/generate-shortcuts.sh" ]; then
    echo "Generating bookmark shortcuts"
    run "$DOTFILES_DIR/generate-shortcuts.sh"
fi

echo ""
echo "=================================="
if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] No changes were made"
else
    echo "[SUCCESS] Installation complete!"
fi
echo "=================================="

if [ "$BACKED_UP" -gt 0 ]; then
    if [ "$DRY_RUN" = true ]; then
        echo "Would back up $BACKED_UP item(s) to: $BACKUP_DIR"
    else
        echo "Backups saved to: $BACKUP_DIR ($BACKED_UP item(s))"
    fi
fi

missing=()
for tool in zsh nvim tmux starship fzf git; do
    command -v "$tool" > /dev/null 2>&1 || missing+=("$tool")
done

echo ""
if [ ${#missing[@]} -gt 0 ]; then
    echo "Not installed yet: ${missing[*]}"
    echo "  Debian/Ubuntu: sudo apt install zsh neovim tmux fzf git"        # pragma: allowlist sudo-install-doc
    echo "  Arch:          sudo pacman -S zsh neovim tmux fzf git starship" # pragma: allowlist sudo-install-doc
    echo "  Starship:      https://starship.rs/guide/#step-1-install-starship"
    echo ""
fi
echo "Next steps:"
echo "  1. Set zsh as default: chsh -s \$(command -v zsh)"
echo "  2. Restart your shell (logout/login or exec zsh)" # pragma: allowlist exec-zsh-doc
if [ "$ZSH_CONFIG_DIR" != "$HOME" ]; then
    echo ""
    echo "Note: .zshrc installed to $ZSH_CONFIG_DIR/.zshrc (ZDOTDIR)"
fi
