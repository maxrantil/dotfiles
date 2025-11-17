# shellcheck shell=bash
# ABOUTME: Environment variables for all zsh shells (login and non-login)
# .zshenv - Sourced for ALL zsh shells (login, interactive, non-interactive)
# Keep this minimal - only essential environment setup

# XDG Base Directory specification
# These must be set here (not .zprofile) because non-login shells need them
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

# Set ZDOTDIR so zsh looks for .zshrc in the right place
# This is critical for XDG compliance - without it, zsh looks for .zshrc in $HOME
export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"

# Default programs (needed for aliases like v=$EDITOR, e=$EDITOR)
# Must be here (not .zprofile) so non-login shells have them
export EDITOR="nvim"
export VISUAL="nvim"

# BROWSER: Auto-detect available browser
# Priority: librewolf (VMs) > firefox > chromium-browser > chromium > xdg-open
if command -v librewolf >/dev/null 2>&1; then
    export BROWSER="librewolf"
elif command -v firefox >/dev/null 2>&1; then
    export BROWSER="firefox"
elif command -v chromium-browser >/dev/null 2>&1; then
    export BROWSER="chromium-browser"
elif command -v chromium >/dev/null 2>&1; then
    export BROWSER="chromium"
elif command -v xdg-open >/dev/null 2>&1; then
    export BROWSER="xdg-open"
fi

# Add ~/.local/bin to PATH
# Required for non-login shells to find user scripts
export PATH="$HOME/.local/bin:$PATH"
