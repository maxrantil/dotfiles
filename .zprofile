# shellcheck shell=bash
# ABOUTME: Login shell configuration with XDG Base Directory and PATH setup
# .zprofile - Runs once at login
# Environment variables and PATH configuration

# NOTE: Essential variables (EDITOR, VISUAL, BROWSER, PATH, XDG_*) are now in .zshenv
# This ensures they're available in both login and non-login shells (e.g., SSH sessions)

# Additional XDG Base Directory paths (less critical, can stay here)

# Clean up home directory by setting XDG paths
export LESSHISTFILE="-"
export WGETRC="${XDG_CONFIG_HOME}/wget/wgetrc"
export INPUTRC="${XDG_CONFIG_HOME}/shell/inputrc"
export ZDOTDIR="${XDG_CONFIG_HOME}/zsh"
export CARGO_HOME="${XDG_DATA_HOME}/cargo"
export GOPATH="${XDG_DATA_HOME}/go"
export ANSIBLE_CONFIG="${XDG_CONFIG_HOME}/ansible/ansible.cfg"
export HISTFILE="${XDG_CACHE_HOME}/zsh/history"
export PASSWORD_STORE_DIR="${XDG_DATA_HOME}/password-store"

# Add cargo bin to PATH if it exists
[ -d "${CARGO_HOME}/bin" ] && export PATH="$PATH:${CARGO_HOME}/bin"

# Add go bin to PATH if it exists
[ -d "${GOPATH}/bin" ] && export PATH="$PATH:${GOPATH}/bin"

# Less colors for man pages
export LESS=-R
LESS_TERMCAP_mb="$(printf '%b' '[1;31m')"
export LESS_TERMCAP_mb
LESS_TERMCAP_md="$(printf '%b' '[1;36m')"
export LESS_TERMCAP_md
LESS_TERMCAP_me="$(printf '%b' '[0m')"
export LESS_TERMCAP_me
LESS_TERMCAP_so="$(printf '%b' '[01;44;33m')"
export LESS_TERMCAP_so
LESS_TERMCAP_se="$(printf '%b' '[0m')"
export LESS_TERMCAP_se
LESS_TERMCAP_us="$(printf '%b' '[1;32m')"
export LESS_TERMCAP_us
LESS_TERMCAP_ue="$(printf '%b' '[0m')"
export LESS_TERMCAP_ue

# FZF configuration
export FZF_DEFAULT_OPTS="--layout=reverse --height 40%"

# GPG fix
GPG_TTY=$(tty)
export GPG_TTY

# Fix locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
