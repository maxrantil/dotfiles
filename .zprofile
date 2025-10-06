# ABOUTME: Login shell configuration with XDG Base Directory and PATH setup
# .zprofile - Runs once at login
# Environment variables and PATH configuration

# Add ~/.local/bin to PATH (including subdirectories)
export PATH="$PATH:$HOME/.local/bin"

# Default programs
export EDITOR="nvim"
export VISUAL="nvim"
export BROWSER="firefox"

# XDG Base Directory specification
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"

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
export LESS_TERMCAP_mb="$(printf '%b' '[1;31m')"
export LESS_TERMCAP_md="$(printf '%b' '[1;36m')"
export LESS_TERMCAP_me="$(printf '%b' '[0m')"
export LESS_TERMCAP_so="$(printf '%b' '[01;44;33m')"
export LESS_TERMCAP_se="$(printf '%b' '[0m')"
export LESS_TERMCAP_us="$(printf '%b' '[1;32m')"
export LESS_TERMCAP_ue="$(printf '%b' '[0m')"

# FZF configuration
export FZF_DEFAULT_OPTS="--layout=reverse --height 40%"

# GPG fix
export GPG_TTY=$(tty)

# Fix locale
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
