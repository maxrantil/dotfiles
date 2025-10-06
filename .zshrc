#!/bin/zsh
# .zshrc - Interactive shell configuration
# Runs for every shell session

# Enable colors
autoload -U colors && colors

# Use Starship prompt if available, otherwise fall back to custom prompt
if command -v starship > /dev/null 2>&1; then
    eval "$(starship init zsh)"
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

# FZF integration (if installed)
if [ -f /usr/share/fzf/key-bindings.zsh ]; then
    source /usr/share/fzf/key-bindings.zsh
    source /usr/share/fzf/completion.zsh
elif [ -f ~/.fzf.zsh ]; then
    source ~/.fzf.zsh
fi

# NVM (Node Version Manager) support
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# Load universal aliases
[ -f ~/.aliases ] && source ~/.aliases

# Load bookmark shortcuts (cf, sc, etc.)
[ -f ~/.config/shell/shortcutrc ] && source ~/.config/shell/shortcutrc

# Load distro-specific aliases
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case "$ID" in
        ubuntu|debian|pop)
            [ -f ~/.dotfiles/distro/debian/.aliases_debian ] && source ~/.dotfiles/distro/debian/.aliases_debian
            ;;
        arch|artix|manjaro)
            [ -f ~/.dotfiles/distro/arch/.aliases_arch ] && source ~/.dotfiles/distro/arch/.aliases_arch
            ;;
    esac
fi

# Syntax highlighting (if installed via apt)
if [ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]; then
    source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi

# Auto-suggestions (if installed via apt)
if [ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
    source /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
fi
