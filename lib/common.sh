# shellcheck shell=bash
# ABOUTME: Shared helpers for install.sh and rollback.sh (link list, ZDOTDIR resolution)
# Sourced, not executed. Keep install and rollback in sync by defining links here only.

# Resolve the zsh config directory the dotfiles expect (XDG: $XDG_CONFIG_HOME/zsh).
# Reads ZDOTDIR from .zshenv (authoritative) or .zprofile without executing either file,
# then expands only allowlisted variables. Anything unexpected falls back to $HOME.
# Usage: resolve_zdotdir <dotfiles_dir>   -> prints directory
resolve_zdotdir() {
    local dotfiles_dir="$1" src value xdg_config
    xdg_config="${XDG_CONFIG_HOME:-$HOME/.config}"

    for src in "$dotfiles_dir/.zshenv" "$dotfiles_dir/.zprofile"; do
        [ -f "$src" ] || continue
        value=$(grep -E '^export ZDOTDIR=' "$src" | head -1 | sed "s/^export ZDOTDIR=//; s/[\"']//g") || true
        [ -n "$value" ] && break
    done

    if [ -z "${value:-}" ]; then
        printf '%s\n' "$HOME"
        return 0
    fi

    # Only letters, digits and path characters plus the allowlisted variable syntax
    if ! [[ "$value" =~ ^[a-zA-Z0-9/_.{}\$-]+$ ]]; then
        echo "[WARNING] Unexpected ZDOTDIR value '$value', using \$HOME" >&2
        printf '%s\n' "$HOME"
        return 0
    fi

    value="${value//\$\{XDG_CONFIG_HOME\}/$xdg_config}"
    value="${value//\$XDG_CONFIG_HOME/$xdg_config}"
    value="${value//\$\{HOME\}/$HOME}"
    value="${value//\$HOME/$HOME}"

    # Any variable left unexpanded means we can't trust the result
    if [[ "$value" == *\$* ]]; then
        echo "[WARNING] Could not expand ZDOTDIR '$value', using \$HOME" >&2
        printf '%s\n' "$HOME"
        return 0
    fi

    printf '%s\n' "$value"
}

# Print "source<TAB>target" pairs for every file the installer manages.
# Source paths are relative to the dotfiles repo; targets are absolute.
# Usage: dotfiles_links <zsh_config_dir>
dotfiles_links() {
    local zdot="$1"
    printf '%s\t%s\n' \
        .zshenv "$HOME/.zshenv" \
        .zprofile "$zdot/.zprofile" \
        .zshrc "$zdot/.zshrc" \
        .aliases "$HOME/.aliases" \
        inputrc "$HOME/.config/shell/inputrc" \
        init.vim "$HOME/.config/nvim/init.vim" \
        .gitconfig "$HOME/.gitconfig" \
        .tmux.conf "$HOME/.tmux.conf" \
        starship.toml "$HOME/.config/starship.toml"
}

# Paths older versions linked that are no longer used. With ZDOTDIR set (.zshenv), zsh
# reads $ZDOTDIR/.zprofile and never ~/.zprofile, so that link was silently ignored.
# Usage: dotfiles_legacy_links <zsh_config_dir>
dotfiles_legacy_links() {
    local zdot="$1"
    if [ "$zdot" != "$HOME" ]; then
        printf '%s\t%s\n' .zprofile "$HOME/.zprofile"
    fi
}

# Backup directory naming shared by install and rollback
# shellcheck disable=SC2034  # used by the scripts that source this file
BACKUP_PREFIX=".dotfiles_backup_"
# shellcheck disable=SC2034
BACKUP_NAME_REGEX='^\.dotfiles_backup_[0-9]{8}_[0-9]{6}$'
