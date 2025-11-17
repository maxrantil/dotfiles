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
