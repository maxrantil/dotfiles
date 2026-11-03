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
export CARGO_HOME="${XDG_DATA_HOME}/cargo"
export GOPATH="${XDG_DATA_HOME}/go"
export ANSIBLE_CONFIG="${XDG_CONFIG_HOME}/ansible/ansible.cfg"
export HISTFILE="${XDG_CACHE_HOME}/zsh/history"
export PASSWORD_STORE_DIR="${XDG_DATA_HOME}/password-store"

# Add cargo bin to PATH if it exists
[ -d "${CARGO_HOME}/bin" ] && export PATH="$PATH:${CARGO_HOME}/bin"

# Add go bin to PATH if it exists
[ -d "${GOPATH}/bin" ] && export PATH="$PATH:${GOPATH}/bin"

# Less colors for man pages (ANSI-C quoting: real escape bytes, no subshells)
export LESS=-R
export LESS_TERMCAP_mb=$'\e[1;31m'
export LESS_TERMCAP_md=$'\e[1;36m'
export LESS_TERMCAP_me=$'\e[0m'
export LESS_TERMCAP_so=$'\e[01;44;33m'
export LESS_TERMCAP_se=$'\e[0m'
export LESS_TERMCAP_us=$'\e[1;32m'
export LESS_TERMCAP_ue=$'\e[0m'

# FZF configuration
export FZF_DEFAULT_OPTS="--layout=reverse --height 40%"

# GPG fix (zsh sets $TTY; fall back to tty(1) elsewhere)
GPG_TTY="${TTY:-$(tty)}"
export GPG_TTY

# Fix locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
