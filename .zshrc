#!/bin/zsh
# ABOUTME: Interactive shell configuration with vi-mode, FZF integration, and compinit caching
# .zshrc - Interactive shell configuration
# Runs for every shell session

# Safe source function - verify ownership and permissions before sourcing files
# Protects against sourcing files with insecure ownership/permissions.
# Uses zsh builtins only (zsh/stat, path modifiers): no external processes, so it
# costs well under a millisecond per file instead of ~14ms.
# Note: Small TOCTOU window exists between checks and sourcing (microseconds)
zmodload -F zsh/stat b:zstat 2>/dev/null
safe_source() {
    # No "emulate -L" here: sourced files must be able to set options for the shell
    local file="$1" parent
    local -A st pst

    # Normalize path to absolute
    [[ "$file" = /* ]] || file="$PWD/$file"

    # Reject shell metacharacters in path
    [[ "$file" != *[\;\|\&\$\`]* ]] || return 1

    # Must be an existing regular file (-f follows symlinks; devices, fifos, sockets fail)
    [[ -f "$file" ]] || return 1

    # Resolve symlinks to the real file
    file="${file:A}"
    [[ -f "$file" ]] || return 1

    # Fail closed if we cannot inspect the file
    if ! (( ${+builtins[zstat]} )); then
        print -u2 "Warning: Cannot validate $file security (zsh/stat unavailable)"
        return 1
    fi
    zstat -H st -- "$file" 2>/dev/null || return 1
    parent="${file:h}"
    zstat -H pst -- "$parent" 2>/dev/null || return 1

    # Owner must be us, or root for system files under /usr/share (zsh plugins, fzf)
    if (( st[uid] != EUID )); then
        if (( st[uid] == 0 )) && [[ "$file" == /usr/share/* ]]; then
            : # Allow root-owned system files
        else
            print -u2 "Warning: $file not owned by $USERNAME (uid ${st[uid]})"
            return 1
        fi
    fi

    # Parent directory must be owned by us or root
    if (( pst[uid] != EUID && pst[uid] != 0 )); then
        print -u2 "Warning: Parent directory of $file not owned by $USERNAME or root"
        return 1
    fi

    # Reject world-writable files and setuid/setgid/sticky bits; group-writable (664) is fine
    local -i perms=$(( st[mode] & 8#7777 ))
    if (( perms & 8#7002 )); then
        print -u2 "Warning: $file has insecure permissions ($(( [##8] perms )))"
        return 1
    fi

    # Source the file (small TOCTOU window here, but acceptable for dotfiles)
    source "$file"
}

# Enable colors
autoload -U colors && colors

# Use Starship prompt if available, otherwise fall back to custom prompt
if (( $+commands[starship] )); then
    # Cache starship init to avoid subprocess on every startup
    STARSHIP_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/starship/init.zsh"
    if [[ ! -s "$STARSHIP_CACHE" || "$commands[starship]" -nt "$STARSHIP_CACHE" ]]; then
        mkdir -p "${STARSHIP_CACHE:h}"
        starship init zsh >| "$STARSHIP_CACHE"
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

# Disable ctrl-s to freeze terminal (only meaningful on a real terminal)
[[ -t 0 ]] && stty stop undef 2>/dev/null

# Auto-completion with menu select
autoload -Uz compinit
zstyle ':completion:*' menu select
zmodload zsh/complist
# Full compinit (with security audit) at most once a day; otherwise trust the dump.
# The glob must run outside [[ ]] (no globbing there), which is why the old check
# always ran the slow path.
_zcompdump="${ZDOTDIR:-$HOME}/.zcompdump"
_zcompdump_stale=( "$_zcompdump"(N.mh+24) )
if [[ ! -s "$_zcompdump" ]] || (( $#_zcompdump_stale )); then
    # -i: skip completion code from insecure (group/world-writable) directories instead
    # of prompting, which aborted compinit entirely when no terminal could answer
    autoload -Uz compaudit
    _zinsecure=( ${(f)"$(compaudit 2>/dev/null)"} )
    if (( $#_zinsecure )) && [[ -t 2 ]]; then
        print -u2 "zsh: ignoring completions from insecure directories: ${(j:, :)_zinsecure}"
    fi
    unset _zinsecure
    compinit -i -d "$_zcompdump"
    touch "$_zcompdump"            # compinit only rewrites the dump if something changed
else
    compinit -C -d "$_zcompdump"
fi
# Compile the dump in the background so later shells load it faster
if [[ ! "$_zcompdump.zwc" -nt "$_zcompdump" ]]; then
    { zcompile "$_zcompdump" } &!
fi
unset _zcompdump _zcompdump_stale
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
[[ -t 1 ]] && echo -ne '\e[5 q'  # Use beam shape cursor on startup
preexec() { echo -ne '\e[5 q' ;} # Use beam shape cursor for each new prompt

# Edit line in vim with ctrl-e (in normal mode)
autoload edit-command-line; zle -N edit-command-line
bindkey '^e' edit-command-line
bindkey -M vicmd '^e' edit-command-line

# lf file manager integration - Ctrl+O to browse and cd
lfcd () {
    local tmp dir
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

# FZF integration (if installed). Key bindings need the line editor, which only
# exists on a terminal; loading them without one prints "can't change option: zle".
if [[ -o zle && -t 0 ]]; then
    if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then                 # Arch
        safe_source /usr/share/fzf/key-bindings.zsh
        safe_source /usr/share/fzf/completion.zsh
    elif [[ -f /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then  # Debian/Ubuntu
        safe_source /usr/share/doc/fzf/examples/key-bindings.zsh
        [[ -f /usr/share/zsh/vendor-completions/_fzf ]] || \
            safe_source /usr/share/doc/fzf/examples/completion.zsh
    elif [[ -f ~/.fzf.zsh ]]; then
        safe_source ~/.fzf.zsh
    fi
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

# Load distro-specific aliases (distro ID cached once; /etc/os-release is parsed, not
# sourced, so its NAME/VERSION/ID variables don't leak into the interactive shell)
_distro_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/distro"
if [[ ! -s "$_distro_cache" && -r /etc/os-release ]]; then
    () {
        local line id
        while IFS= read -r line; do
            [[ "$line" == ID=* ]] && { id="${${line#ID=}//[\"\']/}"; break; }
        done < /etc/os-release
        [[ -n "$id" ]] && mkdir -p "${_distro_cache:h}" && print -r -- "$id" >| "$_distro_cache"
    }
fi

if [[ -s "$_distro_cache" ]]; then
    DISTRO="$(<"$_distro_cache")"
    case "$DISTRO" in
        ubuntu|debian|pop)
            [ -f ~/.dotfiles/distro/debian/.aliases_debian ] && safe_source ~/.dotfiles/distro/debian/.aliases_debian
            ;;
        arch|artix|manjaro)
            [ -f ~/.dotfiles/distro/arch/.aliases_arch ] && safe_source ~/.dotfiles/distro/arch/.aliases_arch
            ;;
    esac
fi
unset _distro_cache

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
