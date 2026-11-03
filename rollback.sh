#!/bin/bash
# ABOUTME: Automated rollback script for dotfiles installation failures
# Removes symlinks into this repo and restores files from the latest backup to their
# original locations (backups keep paths relative to $HOME).

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
. "$DOTFILES_DIR/lib/common.sh"

DRY_RUN=false
AUTO_YES=false

for arg in "$@"; do
    case $arg in
        --dry-run | -n)
            DRY_RUN=true
            ;;
        -y | --yes)
            AUTO_YES=true
            ;;
        -h | --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Rollback dotfiles installation from latest backup"
            echo ""
            echo "Options:"
            echo "  -y, --yes          Skip confirmation prompt"
            echo "  -n, --dry-run      Show what would be done without making changes"
            echo "  -h, --help         Show this help message"
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

# Find latest backup directory (names sort chronologically)
LATEST_BACKUP=$(find "$HOME" -maxdepth 1 -name "${BACKUP_PREFIX}*" -type d 2> /dev/null | sort -r | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "ERROR: No backup found" >&2
    echo "Looked for directories matching: $HOME/${BACKUP_PREFIX}*" >&2
    exit 1
fi

backup_name=$(basename "$LATEST_BACKUP")
if ! [[ "$backup_name" =~ $BACKUP_NAME_REGEX ]]; then
    echo "ERROR: Invalid backup directory format: $backup_name" >&2
    echo "Expected format: ${BACKUP_PREFIX}YYYYMMDD_HHMMSS" >&2
    exit 1
fi

if [ -z "$(ls -A "$LATEST_BACKUP")" ]; then
    echo "ERROR: Backup directory is empty: $LATEST_BACKUP" >&2
    echo "Cannot perform rollback from empty backup" >&2
    exit 1
fi

ZSH_CONFIG_DIR="$(resolve_zdotdir "$DOTFILES_DIR")"

# Map of managed targets, used to restore files from older flat backups
# (before paths were preserved) to the right place, e.g. init.vim -> ~/.config/nvim/
declare -A FLAT_TARGET=()
MANAGED_TARGETS=()
while IFS=$'\t' read -r _src target; do
    MANAGED_TARGETS+=("$target")
    name=$(basename "$target")
    # Only map names that never live directly in $HOME
    if [ "$(dirname "$target")" != "$HOME" ] && [ "$name" != ".zshrc" ]; then
        FLAT_TARGET["$name"]="$target"
    fi
done < <(dotfiles_links "$ZSH_CONFIG_DIR")

# Work out where a backed-up item goes
restore_target_for() {
    local rel="$1"
    if [[ "$rel" != */* ]] && [ -n "${FLAT_TARGET[$rel]:-}" ]; then
        printf '%s\n' "${FLAT_TARGET[$rel]}"
    else
        printf '%s\n' "$HOME/$rel"
    fi
}

# Items to restore: files and symlinks at any depth, relative to the backup root
mapfile -d '' BACKUP_ITEMS < <(cd "$LATEST_BACKUP" && find . -mindepth 1 \( -type f -o -type l \) -print0 | sort -z)

echo "=========================================="
echo "  Dotfiles Rollback"
echo "=========================================="
echo ""
echo "Latest backup found: $backup_name"
echo "Location: $LATEST_BACKUP"
echo ""

if [ "$DRY_RUN" = true ]; then
    echo "[DRY RUN] Would restore the following files:"
    for item in "${BACKUP_ITEMS[@]}"; do
        rel="${item#./}"
        echo "  $rel -> $(restore_target_for "$rel")"
    done
    echo ""
    echo "[DRY RUN] No changes made"
    exit 0
fi

echo "Backup contents:"
for item in "${BACKUP_ITEMS[@]}"; do
    echo "  ${item#./}"
done
echo ""

if [ "$AUTO_YES" = false ]; then
    echo "WARNING: This will:"
    echo "  1. Remove current dotfiles symlinks"
    echo "  2. Restore files from backup"
    echo "  3. Delete the backup directory once it is empty"
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

echo "Removing current symlinks..."
for symlink in "${MANAGED_TARGETS[@]}"; do
    if [ -L "$symlink" ]; then
        rm -f "$symlink" || {
            echo "  [WARNING] Failed to remove symlink: $symlink" >&2
            continue
        }
        echo "  [REMOVED] ${symlink#"$HOME"/}"
    fi
done
echo ""

echo "Restoring files from backup..."
FAILED=0
for item in "${BACKUP_ITEMS[@]}"; do
    rel="${item#./}"
    case "/$rel/" in
        */../*)
            echo "  [SKIPPED] $rel (unsafe path)" >&2
            FAILED=$((FAILED + 1))
            continue
            ;;
    esac
    target=$(restore_target_for "$rel")

    if [ -e "$target" ] || [ -L "$target" ]; then
        echo "  [SKIPPED] $rel: $target already exists (left in backup)" >&2
        FAILED=$((FAILED + 1))
        continue
    fi

    mkdir -p "$(dirname "$target")"
    # mv preserves permissions and timestamps
    mv "$LATEST_BACKUP/$rel" "$target"
    echo "  [RESTORED] $rel -> ${target#"$HOME"/}"
done
echo ""

# Remove now-empty directories inside the backup, then the backup itself
find "$LATEST_BACKUP" -mindepth 1 -depth -type d -empty -delete 2> /dev/null || true
if [ -d "$LATEST_BACKUP" ] && [ -z "$(ls -A "$LATEST_BACKUP")" ]; then
    rmdir "$LATEST_BACKUP"
    echo "[CLEANUP] Removed empty backup directory"
else
    echo "[WARNING] Backup directory not empty, keeping: $LATEST_BACKUP"
fi

echo ""
echo "=========================================="
if [ "$FAILED" -eq 0 ]; then
    echo "[SUCCESS] Rollback complete!"
else
    echo "[WARNING] Rollback finished with $FAILED item(s) skipped"
fi
echo "=========================================="
echo ""
echo "Files have been restored from backup"
echo ""
