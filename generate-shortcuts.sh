#!/bin/bash
# ABOUTME: Generates shell shortcuts from bookmark files with input validation
# Run this after editing bm-dirs or bm-files

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="${HOME}/.config/shell/shortcutrc"

mkdir -p "$(dirname "$OUTPUT")"

cat > "$OUTPUT" << 'EOF'
# vim: filetype=sh
# Auto-generated shortcuts from bm-dirs and bm-files
# Regenerate with: ~/.dotfiles/generate-shortcuts.sh

EOF

# Validate and sanitize alias name
# Must start with letter, contain only alphanumeric, underscore, hyphen
validate_alias_name() {
    local name="$1"
    [[ "$name" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]
}

# Generate directory shortcuts (cd + ls)
if [ -f "$DOTFILES_DIR/bm-dirs" ]; then
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue

        # Parse line with regex for security
        if [[ "$line" =~ ^([a-zA-Z0-9_-]+)[[:space:]]+(.+)$ ]]; then
            alias_name="${BASH_REMATCH[1]}"
            path="${BASH_REMATCH[2]}"

            # Validate alias name
            if ! validate_alias_name "$alias_name"; then
                echo "Warning: Invalid alias name '$alias_name' in bm-dirs, skipping" >&2
                continue
            fi

            # Use printf %q for safe shell escaping
            printf "alias %s='cd %q && ls -A'\n" "$alias_name" "$path" >> "$OUTPUT"
        else
            echo "Warning: Malformed line in bm-dirs: $line" >&2
        fi
    done < "$DOTFILES_DIR/bm-dirs"
fi

# Generate file shortcuts (edit)
if [ -f "$DOTFILES_DIR/bm-files" ]; then
    while IFS= read -r line; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$line" ]] && continue

        # Parse line with regex for security
        if [[ "$line" =~ ^([a-zA-Z0-9_-]+)[[:space:]]+(.+)$ ]]; then
            alias_name="${BASH_REMATCH[1]}"
            path="${BASH_REMATCH[2]}"

            # Validate alias name
            if ! validate_alias_name "$alias_name"; then
                echo "Warning: Invalid alias name '$alias_name' in bm-files, skipping" >&2
                continue
            fi

            # Use printf %q for safe shell escaping
            printf "alias %s='\$EDITOR %q'\n" "$alias_name" "$path" >> "$OUTPUT"
        else
            echo "Warning: Malformed line in bm-files: $line" >&2
        fi
    done < "$DOTFILES_DIR/bm-files"
fi

echo "✓ Generated shortcuts at $OUTPUT"
