#!/bin/bash
# ABOUTME: Generates shell shortcuts from bookmark files with input validation
# Run this after editing bm-dirs or bm-files

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT="${HOME}/.config/shell/shortcutrc"

mkdir -p "$(dirname "$OUTPUT")"

# Build in a temp file next to the target and move it into place at the end, so a
# failure never leaves a half-written file for the shell to source.
TMP_OUTPUT="$(mktemp "${OUTPUT}.XXXXXX")"
trap 'rm -f "$TMP_OUTPUT"' EXIT

cat > "$TMP_OUTPUT" << 'EOF'
# vim: filetype=sh
# Auto-generated shortcuts from bm-dirs and bm-files
# Regenerate with: ~/.dotfiles/generate-shortcuts.sh

EOF

# Alias names: start with a letter, then letters, digits, underscore, hyphen
validate_alias_name() {
    [[ "$1" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]
}

# Paths are expanded when the alias runs, so only allow plain path characters and
# simple variable references ($VAR, ${VAR}, ${VAR:-default}). Anything that could run
# a command ($(...), backticks, ; | & < > quotes, globs) is rejected.
validate_path() {
    local path="$1"
    [[ "$path" =~ ^[a-zA-Z0-9_./~:{}\$\ +@%,=-]+$ ]] || return 1
    [[ "$path" != *'$('* ]] || return 1
    return 0
}

# process_bookmarks <file> <template>   (template gets the quoted path via %s)
process_bookmarks() {
    local file="$1" template="$2" line alias_name path

    [ -f "$file" ] || return 0

    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line//[[:space:]]/}" ]] && continue

        if [[ "$line" =~ ^([a-zA-Z0-9_-]+)[[:space:]]+(.+[^[:space:]])[[:space:]]*$ ]]; then
            alias_name="${BASH_REMATCH[1]}"
            path="${BASH_REMATCH[2]}"
        else
            echo "Warning: Malformed line in $(basename "$file"): $line" >&2
            continue
        fi

        if ! validate_alias_name "$alias_name"; then
            echo "Warning: Invalid alias name '$alias_name' in $(basename "$file"), skipping" >&2
            continue
        fi

        if ! validate_path "$path"; then
            echo "Warning: Unsafe path for '$alias_name' in $(basename "$file"), skipping" >&2
            continue
        fi

        # "~" does not expand inside quotes, so spell it out
        # shellcheck disable=SC2088  # comparing against a literal tilde on purpose
        if [[ "$path" == "~" || "$path" == "~/"* ]]; then
            path="\$HOME${path#\~}"
        fi

        # Double quotes keep variables expandable at run time and survive spaces
        # shellcheck disable=SC2059  # template is a fixed format string from this file
        printf "alias %s='$template'\n" "$alias_name" "\"$path\"" >> "$TMP_OUTPUT"
    done < "$file"
}

# Directory shortcuts (cd + ls) and file shortcuts (edit)
process_bookmarks "$DOTFILES_DIR/bm-dirs" 'cd %s && ls -A'
process_bookmarks "$DOTFILES_DIR/bm-files" '$EDITOR %s'

# 644 so safe_source in .zshrc accepts it
chmod 644 "$TMP_OUTPUT"
mv -f "$TMP_OUTPUT" "$OUTPUT"
trap - EXIT

echo "[SUCCESS] Generated shortcuts at $OUTPUT"
