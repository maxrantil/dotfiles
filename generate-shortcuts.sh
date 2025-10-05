#!/bin/bash
# Generate shell shortcuts from bookmark files
# Run this after editing bm-dirs or bm-files

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="${HOME}/.config/shell/shortcutrc"

mkdir -p "$(dirname "$OUTPUT")"

cat > "$OUTPUT" << 'EOF'
# vim: filetype=sh
# Auto-generated shortcuts from bm-dirs and bm-files
# Regenerate with: ~/.dotfiles/generate-shortcuts.sh

EOF

# Generate directory shortcuts (cd + ls)
if [ -f "$DOTFILES_DIR/bm-dirs" ]; then
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue

        # Extract alias and path
        alias_name=$(echo "$line" | awk '{print $1}')
        path=$(echo "$line" | cut -d' ' -f2-)

        echo "alias $alias_name=\"cd $path && ls -A\"" >> "$OUTPUT"
    done < "$DOTFILES_DIR/bm-dirs"
fi

# Generate file shortcuts (edit)
if [ -f "$DOTFILES_DIR/bm-files" ]; then
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue

        # Extract alias and path
        alias_name=$(echo "$line" | awk '{print $1}')
        path=$(echo "$line" | cut -d' ' -f2-)

        echo "alias $alias_name=\"\$EDITOR $path\"" >> "$OUTPUT"
    done < "$DOTFILES_DIR/bm-files"
fi

echo "✓ Generated shortcuts at $OUTPUT"
