#!/bin/bash
# ABOUTME: Automated rollback script for dotfiles installation failures
# Restores files from latest backup directory and removes current symlinks

set -e

# Parse command-line arguments
DRY_RUN=false
AUTO_YES=false

for arg in "$@"; do
    case $arg in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -y | --yes)
            AUTO_YES=true
            shift
            ;;
        -h | --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Rollback dotfiles installation from latest backup"
            echo ""
            echo "Options:"
            echo "  -y, --yes      Skip confirmation prompt"
            echo "  --dry-run      Show what would be done without making changes"
            echo "  -h, --help     Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0              # Interactive rollback with confirmation"
            echo "  $0 -y           # Automatic rollback without confirmation"
            echo "  $0 --dry-run    # Preview changes without applying them"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Find latest backup directory
LATEST_BACKUP=$(find "$HOME" -maxdepth 1 -name ".dotfiles_backup_*" -type d 2> /dev/null | sort -r | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "ERROR: No backup found" >&2
    echo "Looked for directories matching: $HOME/.dotfiles_backup_*" >&2
    exit 1
fi

# Validate backup directory name format (YYYYMMDD_HHMMSS)
backup_name=$(basename "$LATEST_BACKUP")
if ! [[ "$backup_name" =~ ^\.dotfiles_backup_[0-9]{8}_[0-9]{6}$ ]]; then
    echo "ERROR: Invalid backup directory format: $backup_name" >&2
    echo "Expected format: .dotfiles_backup_YYYYMMDD_HHMMSS" >&2
    exit 1
fi

# Validate backup directory is not empty
if [ -z "$(ls -A "$LATEST_BACKUP")" ]; then
    echo "ERROR: Backup directory is empty: $LATEST_BACKUP" >&2
    echo "Cannot perform rollback from empty backup" >&2
    exit 1
fi

echo "=========================================="
echo "  Dotfiles Rollback"
echo "=========================================="
echo ""
echo "Latest backup found: $(basename "$LATEST_BACKUP")"
echo "Location: $LATEST_BACKUP"
echo ""
echo "Backup contents:"
ls -lhA "$LATEST_BACKUP"
echo ""

# Dry-run mode
if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would restore the following files:"
    # Include hidden files in glob
    shopt -s dotglob nullglob
    for file in "$LATEST_BACKUP"/*; do
        filename=$(basename "$file")
        target="$HOME/$filename"
        echo "  $filename -> $target"
    done
    shopt -u dotglob nullglob
    echo ""
    echo "[DRY RUN] No changes made"
    exit 0
fi

# Confirmation prompt (skip if -y flag set)
if [ "$AUTO_YES" = false ]; then
    echo "WARNING: This will:"
    echo "  1. Remove current symlinks"
    echo "  2. Restore files from backup"
    echo "  3. Delete the backup directory"
    echo ""
    read -p "Continue with rollback? (y/N): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Rollback cancelled"
        exit 0
    fi
fi

echo ""
echo "Starting rollback..."
echo ""

# Determine ZDOTDIR location (same logic as install.sh)
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ZSH_CONFIG_DIR="$HOME"

if [ -f "$DOTFILES_DIR/.zprofile" ]; then
    export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
    EXTRACTED_ZDOTDIR=$(grep -E '^export ZDOTDIR=' "$DOTFILES_DIR/.zprofile" | head -1 | sed 's/^export ZDOTDIR=//; s/"//g; s/'"'"'//g')

    # Validate extracted value contains only safe characters
    if [[ "$EXTRACTED_ZDOTDIR" =~ ^[a-zA-Z0-9/_\$\{\}\.-]+$ ]]; then
        EXTRACTED_ZDOTDIR="${EXTRACTED_ZDOTDIR//\$\{HOME\}/$HOME}"
        EXTRACTED_ZDOTDIR="${EXTRACTED_ZDOTDIR//\$HOME/$HOME}"
        EXTRACTED_ZDOTDIR="${EXTRACTED_ZDOTDIR//\$\{XDG_CONFIG_HOME\}/$XDG_CONFIG_HOME}"
        EXTRACTED_ZDOTDIR="${EXTRACTED_ZDOTDIR//\$XDG_CONFIG_HOME/$XDG_CONFIG_HOME}"
        ZSH_CONFIG_DIR="${EXTRACTED_ZDOTDIR:-$HOME}"
    else
        echo "WARNING: Invalid ZDOTDIR format detected, using HOME" >&2
        ZSH_CONFIG_DIR="$HOME"
    fi
fi

# List of common symlink locations
SYMLINK_LOCATIONS=(
    "$HOME/.zprofile"
    "$HOME/.aliases"
    "$HOME/.gitconfig"
    "$HOME/.tmux.conf"
    "$HOME/.config/nvim/init.vim"
    "$HOME/.config/starship.toml"
    "$HOME/.config/shell/inputrc"
    "$ZSH_CONFIG_DIR/.zshrc"
)

# Remove current symlinks
echo "Removing current symlinks..."
for symlink in "${SYMLINK_LOCATIONS[@]}"; do
    # Double-check to mitigate TOCTOU race condition
    if [ -L "$symlink" ] && [ -L "$symlink" ]; then
        rm -f "$symlink" || {
            echo "  [WARNING] Failed to remove symlink: $(basename "$symlink")" >&2
            continue
        }
        echo "  [REMOVED] $(basename "$symlink")"
    fi
done
echo ""

# Restore files from backup
echo "Restoring files from backup..."
# Include hidden files in glob
shopt -s dotglob nullglob
for backup_file in "$LATEST_BACKUP"/*; do
    if [ -f "$backup_file" ] || [ -d "$backup_file" ]; then
        filename=$(basename "$backup_file")
        target="$HOME/$filename"

        # Use mv to preserve permissions
        mv "$backup_file" "$target"
        echo "  [RESTORED] $filename"
    fi
done
shopt -u dotglob nullglob
echo ""

# Clean up empty backup directory
if [ -d "$LATEST_BACKUP" ]; then
    # Check if directory is empty
    if [ -z "$(ls -A "$LATEST_BACKUP")" ]; then
        rmdir "$LATEST_BACKUP"
        echo "[CLEANUP] Removed empty backup directory"
    else
        echo "[WARNING] Backup directory not empty, keeping: $LATEST_BACKUP"
    fi
fi

echo ""
echo "=========================================="
echo "[SUCCESS] Rollback complete!"
echo "=========================================="
echo ""
echo "Files have been restored from backup"
echo ""
