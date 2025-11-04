#!/bin/zsh
# ABOUTME: Interactive shell configuration with vi-mode, FZF integration, and compinit caching
# .zshrc - Interactive shell configuration
# Runs for every shell session

# Safe source function - verify ownership and permissions before sourcing files
# Protects against sourcing files with insecure ownership/permissions
# Note: Small TOCTOU window exists between checks and sourcing (microseconds)
safe_source() {
    local file="$1"
    local owner perms parent_dir parent_owner realfile

    # Normalize path to absolute
    [[ "$file" =~ ^/ ]] || file="$PWD/$file"

    # Reject shell metacharacters in path
    [[ ! "$file" =~ [\;\|\&\$\`] ]] || return 1

    # Verify file exists and is regular file (not device, socket, etc.)
    [[ -f "$file" ]] || return 1
    [[ ! -c "$file" && ! -b "$file" && ! -p "$file" && ! -S "$file" ]] || return 1

    # Resolve symlinks to actual file
    if [[ -L "$file" ]]; then
        realfile=$(readlink -f "$file" 2>/dev/null)
        [[ -n "$realfile" && -f "$realfile" ]] || return 1
        file="$realfile"
    fi

    # Validate stat is available (fail closed)
    if ! command -v stat >/dev/null 2>&1; then
        echo "Warning: Cannot validate $file security (stat unavailable)" >&2
        return 1
    fi

    # Get file metadata
    owner=$(stat -c '%U' "$file" 2>/dev/null || \
            stat -f '%Su' "$file" 2>/dev/null)
    perms=$(stat -c '%a' "$file" 2>/dev/null || \
            stat -f '%Lp' "$file" 2>/dev/null)

    # Validate stat output format
    if [[ ! "$owner" =~ ^[a-zA-Z0-9_-]+$ ]] || [[ ! "$perms" =~ ^[0-7]{3,4}$ ]]; then
        echo "Warning: Invalid stat output for $file" >&2
        return 1
    fi

    # Validate USER environment variable
    local actual_user=$(id -un)
    [[ "$USER" == "$actual_user" ]] || USER="$actual_user"

    # Check file ownership
    if [[ "$owner" != "$USER" ]]; then
        echo "Warning: $file not owned by $USER (owner: $owner)" >&2
        return 1
    fi

    # Check parent directory ownership
    parent_dir=$(dirname "$file")
    parent_owner=$(stat -c '%U' "$parent_dir" 2>/dev/null || \
                   stat -f '%Su' "$parent_dir" 2>/dev/null)

    if [[ "$parent_owner" != "$USER" ]] && [[ "$parent_owner" != "root" ]]; then
        echo "Warning: Parent directory of $file not owned by $USER or root" >&2
        return 1
    fi

    # Check permissions (reject world/group writable, setuid/setgid)
    if [[ "$perms" =~ [2367]$ ]] || (( 10#$perms > 644 )); then
        echo "Warning: $file has insecure permissions ($perms)" >&2
        return 1
    fi

    # Source the file (small TOCTOU window here, but acceptable for dotfiles)
    source "$file"
    return $?
}

# Enable colors
autoload -U colors && colors

# Use Starship prompt if available, otherwise fall back to custom prompt
if command -v starship > /dev/null 2>&1; then
    # Cache starship init to avoid subprocess on every startup
    STARSHIP_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/starship/init.zsh"
    if [[ ! -f "$STARSHIP_CACHE" ]] || [[ $(command -v starship) -nt "$STARSHIP_CACHE" ]]; then
        mkdir -p "$(dirname "$STARSHIP_CACHE")"
        starship init zsh > "$STARSHIP_CACHE"
    fi
    source "$STARSHIP_CACHE"
else
    PS1="%B%{$fg[red]%}[%{$fg[yellow]%}%n%{$fg[green]%}@%{$fg[blue]%}%M %{$fg[magenta]%}%~%{$fg[red]%}]%{$reset_color%}$%b "
fi

# Basic options
setopt AUTO_CD                 # Automatically cd into typed directory
setopt CORRECT                 # Suggest corrections for typos
setopt NO_BEEP                 # No beep
setopt INTERACTIVE_COMMENTS    # Allow comments in interactive shells

# History configuration
HISTFILE="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/history"
HISTSIZE=10000000
SAVEHIST=10000000
setopt HIST_SAVE_NO_DUPS       # Don't write duplicate entries
setopt INC_APPEND_HISTORY      # Write to history file immediately
setopt SHARE_HISTORY           # Share history between sessions
setopt HIST_IGNORE_SPACE       # Don't save commands starting with space

# Disable ctrl-s to freeze terminal
stty stop undef

# Auto-completion with menu select
autoload -U compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
# Only rebuild cache once per day
if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit
else
    compinit -C  # Skip security check
fi
_comp_options+=(globdots)      # Include hidden files in completions

# Vi mode
bindkey -v
export KEYTIMEOUT=1

# Enhanced keybindings
bindkey '^R' history-incremental-search-backward
bindkey '^S' history-incremental-search-forward
bindkey '^A' beginning-of-line
bindkey '^E' end-of-line
bindkey '^[[P' delete-char

# Use vim keys in tab complete menu
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -v '^?' backward-delete-char

# Change cursor shape for different vi modes
function zle-keymap-select () {
    case $KEYMAP in
        vicmd) echo -ne '\e[1 q';;      # block
        viins|main) echo -ne '\e[5 q';; # beam
    esac
}
zle -N zle-keymap-select
zle-line-init() {
    zle -K viins
    echo -ne "\e[5 q"
}
zle -N zle-line-init
echo -ne '\e[5 q'                # Use beam shape cursor on startup
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt

# Edit line in vim with ctrl-e (in normal mode)
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line
bindkey -M vicmd '^e' edit-command-line

# lf file manager integration - Ctrl+O to browse and cd
lfcd () {
    tmp="$(mktemp -uq)"
    trap 'rm -f $tmp >/dev/null 2>&1 && trap - HUP INT QUIT TERM PWR EXIT' HUP INT QUIT TERM PWR EXIT
    lf -last-dir-path="$tmp" "$@"
    if [ -f "$tmp" ]; then
        dir="$(cat "$tmp")"
        [ -d "$dir" ] && [ "$dir" != "$(pwd)" ] && cd "$dir"
    fi
}
bindkey -s '^o' '^ulfcd\n'

# fzf-based cd to directory containing selected file - Ctrl+F
bindkey -s '^f' '^ucd "$(dirname "$(fzf)")"\n'

# FZF integration (if installed)
if [ -f /usr/share/fzf/key-bindings.zsh ]; then
    safe_source /usr/share/fzf/key-bindings.zsh
    safe_source /usr/share/fzf/completion.zsh
elif [ -f ~/.fzf.zsh ]; then
    safe_source ~/.fzf.zsh
fi

# NVM (Node Version Manager) lazy loading
export NVM_DIR="$HOME/.config/nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    # Create stub functions that load NVM on first use
    nvm() {
        unset -f nvm node npm npx
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        nvm "$@"
    }
    node() { nvm >/dev/null 2>&1; command node "$@"; }
    npm() { nvm >/dev/null 2>&1; command npm "$@"; }
    npx() { nvm >/dev/null 2>&1; command npx "$@"; }
fi

# Load universal aliases
[ -f ~/.aliases ] && safe_source ~/.aliases

# Load bookmark shortcuts (cf, sc, etc.)
[ -f ~/.config/shell/shortcutrc ] && safe_source ~/.config/shell/shortcutrc

# Load distro-specific aliases
if [[ ! -f "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/distro" ]]; then
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        mkdir -p "${XDG_CACHE_HOME:-$HOME/.cache}/zsh"
        echo "$ID" > "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/distro"
    fi
fi

if [ -f "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/distro" ]; then
    DISTRO=$(cat "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/distro")
    case "$DISTRO" in
        ubuntu|debian|pop)
            [ -f ~/.dotfiles/distro/debian/.aliases_debian ] && safe_source ~/.dotfiles/distro/debian/.aliases_debian
            ;;
        arch|artix|manjaro)
            [ -f ~/.dotfiles/distro/arch/.aliases_arch ] && safe_source ~/.dotfiles/distro/arch/.aliases_arch
            ;;
    esac
fi

# Syntax highlighting (if installed via apt)
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    safe_source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Auto-suggestions (if installed via apt)
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    safe_source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

# Display keyboard shortcuts help
keybindings_help() {
    cat << 'EOF'
ZSH KEYBOARD SHORTCUTS:
  Ctrl+R    - Search backward through history
  Ctrl+S    - Search forward through history
  Ctrl+A    - Jump to beginning of line
  Ctrl+E    - Jump to end of line (or edit in vim in normal mode)
  Ctrl+O    - Open lf file manager and cd to selected directory
  Ctrl+F    - Use fzf to select file and cd to its directory
  Delete    - Delete character under cursor

VI MODE INDICATORS:
  Beam cursor    - Insert mode
  Block cursor   - Normal mode

Tab Completion:
  h/j/k/l   - Navigate completion menu (vim-style)
EOF
}
alias help='keybindings_help'
alias keys='keybindings_help'
