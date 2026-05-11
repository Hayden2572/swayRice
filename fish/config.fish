# ==========================================================
# WEXP FISH CONFIG
# ==========================================================

if status is-interactive
    set -gx EDITOR nano
    set -gx VISUAL nano
    set -gx TERMINAL kitty
    set -gx BROWSER firefox
    set -gx COLORTERM truecolor

    fish_add_path $HOME/.local/bin
    fish_add_path $HOME/go/bin

    # Disable default fish greeting
    set fish_greeting

    # Vi-like controls
    fish_default_key_bindings

    # Aliases
    alias cls='clear'
    alias ll='ls -lah'
    alias la='ls -la'
    alias gs='git status'
    alias gc='git commit'
    alias gp='git push'
    alias gl='git log --oneline --graph --decorate --all'
    alias ..='cd ..'
    alias ...='cd ../..'

    # Starship prompt
    if type -q starship
        starship init fish | source
    end
end
alias ff='fastfetch'
