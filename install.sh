#!/usr/bin/env bash

set -euo pipefail

DOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.rice-backup/$(date +%F-%H-%M-%S)"

log() {
    printf "\033[1;36m[rice]\033[0m %s\n" "$1"
}

warn() {
    printf "\033[1;33m[warn]\033[0m %s\n" "$1"
}

die() {
    printf "\033[1;31m[error]\033[0m %s\n" "$1"
    exit 1
}

need_cmd() {
    command -v "$1" >/dev/null 2>&1 || die "Missing command: $1"
}

backup_path() {
    local path="$1"

    if [ -e "$path" ] || [ -L "$path" ]; then
        mkdir -p "$BACKUP_DIR/$(dirname "${path#$HOME/}")"
        mv "$path" "$BACKUP_DIR/${path#$HOME/}"
        log "Backed up: $path -> $BACKUP_DIR/${path#$HOME/}"
    fi
}

copy_dir() {
    local name="$1"
    local src="$DOT_DIR/$name"
    local dst="$HOME/.config/$name"

    if [ -d "$src" ]; then
        backup_path "$dst"
        mkdir -p "$HOME/.config"
        cp -a "$src" "$dst"
        log "Installed: ~/.config/$name"
    fi
}

copy_file() {
    local src="$1"
    local dst="$2"

    if [ -f "$src" ]; then
        backup_path "$dst"
        mkdir -p "$(dirname "$dst")"
        cp -a "$src" "$dst"
        log "Installed: $dst"
    fi
}

install_packages() {
    log "Installing apt packages"

    sudo apt update

    sudo apt install -y \
        sway swaybg swayidle swaylock \
        waybar kitty fish tmux rofi dunst \
        ranger \
        fastfetch \
        grim slurp wl-clipboard \
        brightnessctl playerctl pavucontrol \
        network-manager-gnome \
        polkit-kde-agent-1 \
        fonts-jetbrains-mono fonts-font-awesome fonts-noto-color-emoji \
        curl unzip jq bc \
        python3-i3ipc python3-pil python3-pygments \
        highlight atool mediainfo poppler-utils ffmpegthumbnailer file \
        bluez blueman rfkill \
        lm-sensors \
        imagemagick \
        pciutils lshw \
        libnotify-bin \
        xdg-utils
}

install_nerd_font() {
    log "Installing JetBrainsMono Nerd Font"

    local font_dir="$HOME/.local/share/fonts/JetBrainsMonoNerd"
    local zip="/tmp/JetBrainsMonoNerd.zip"

    mkdir -p "$font_dir"

    curl -L -o "$zip" \
        https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip

    unzip -o "$zip" -d "$font_dir" >/dev/null
    fc-cache -fv >/dev/null

    log "Nerd Font installed"
}

install_starship() {
    if command -v starship >/dev/null 2>&1; then
        log "Starship already installed"
        return
    fi

    log "Installing Starship"
    curl -sS https://starship.rs/install.sh | sh -s -- -y
}

install_dotfiles() {
    log "Installing dotfiles from $DOT_DIR"

    mkdir -p "$HOME/.config" "$HOME/.local/bin"

    copy_dir "sway"
    copy_dir "waybar"
    copy_dir "kitty"
    copy_dir "rofi"
    copy_dir "fastfetch"
    copy_dir "fish"
    copy_dir "ranger"
    copy_dir "dunst"

    copy_file "$DOT_DIR/starship.toml" "$HOME/.config/starship.toml"
    copy_file "$DOT_DIR/tmux.conf" "$HOME/.tmux.conf"

    if [ -d "$DOT_DIR/scripts" ]; then
        mkdir -p "$HOME/.local/bin"
        cp -a "$DOT_DIR/scripts/." "$HOME/.local/bin/"
        chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
        log "Installed scripts to ~/.local/bin"
    fi
}

fix_paths() {
    log "Fixing hardcoded paths"

    local files=()

    while IFS= read -r -d '' f; do
        files+=("$f")
    done < <(
        find "$HOME/.config" "$HOME/.local/bin" "$HOME" \
            \( -path "$HOME/.config/sway/*" \
            -o -path "$HOME/.config/waybar/*" \
            -o -path "$HOME/.config/kitty/*" \
            -o -path "$HOME/.config/rofi/*" \
            -o -path "$HOME/.config/fastfetch/*" \
            -o -path "$HOME/.config/fish/*" \
            -o -path "$HOME/.config/ranger/*" \
            -o -path "$HOME/.config/dunst/*" \
            -o -path "$HOME/.local/bin/*" \
            -o -path "$HOME/.config/starship.toml" \
            -o -path "$HOME/.tmux.conf" \) \
            -type f -print0 2>/dev/null
    )

    for f in "${files[@]}"; do
        sed -i "s|/home/wexp|$HOME|g" "$f" 2>/dev/null || true
    done
}

setup_shell() {
    log "Configuring shell helpers"

    touch "$HOME/.bashrc"

    grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' "$HOME/.bashrc" || cat >> "$HOME/.bashrc" <<'BASHRC'

# User local binaries
export PATH="$HOME/.local/bin:$PATH"
BASHRC

    grep -qxF 'eval "$(starship init bash)"' "$HOME/.bashrc" || cat >> "$HOME/.bashrc" <<'BASHRC'

# Starship prompt
eval "$(starship init bash)"
BASHRC

    grep -qxF "alias ff='fastfetch --logo-color-1 white'" "$HOME/.bashrc" || cat >> "$HOME/.bashrc" <<'BASHRC'

# Fastfetch
alias ff='fastfetch --logo-color-1 white'
BASHRC

    if command -v fish >/dev/null 2>&1; then
        fish -c 'fish_add_path -U ~/.local/bin' 2>/dev/null || true
    fi
}

setup_services() {
    log "Configuring services"

    sudo systemctl enable --now bluetooth 2>/dev/null || true
    rfkill unblock bluetooth 2>/dev/null || true

    if command -v nm-applet >/dev/null 2>&1; then
        log "NetworkManager applet installed"
    fi
}

fix_permissions() {
    log "Fixing permissions"

    chmod +x "$HOME/.local/bin/"* 2>/dev/null || true
    chmod +x "$HOME/.config/waybar/scripts/"* 2>/dev/null || true
    chmod +x "$HOME/.config/ranger/scope.sh" 2>/dev/null || true
}

reload_sway() {
    if [ -n "${SWAYSOCK:-}" ] && command -v swaymsg >/dev/null 2>&1; then
        log "Reloading Sway"
        swaymsg reload >/dev/null 2>&1 || true

        log "Restarting Waybar"
        pkill waybar 2>/dev/null || true
        nohup waybar >/tmp/waybar.log 2>&1 &
        disown || true
    else
        warn "Sway is not running or SWAYSOCK is empty. Login to Sway and run: swaymsg reload"
    fi
}

post_check() {
    log "Post-install check"

    printf "\nInstalled commands:\n"
    for cmd in sway waybar kitty rofi fish tmux ranger fastfetch starship swaylock grim slurp; do
        if command -v "$cmd" >/dev/null 2>&1; then
            printf "  [ok] %s\n" "$cmd"
        else
            printf "  [missing] %s\n" "$cmd"
        fi
    done

    printf "\nUseful hotkeys from this rice:\n"
    printf "  Mod + Enter          Kitty\n"
    printf "  Mod + Shift + Enter  Kitty + tmux\n"
    printf "  Mod + D              Rofi launcher\n"
    printf "  Mod + E              Ranger file manager\n"
    printf "  Mod + Shift + W      Wi-Fi menu\n"
    printf "  Mod + Shift + B      Bluetooth menu\n"
    printf "  Mod + Escape         Lockscreen\n"
    printf "  Mod + S              Screenshot active screen\n"
    printf "  Mod + Shift + S      Screenshot region\n"

    printf "\nBackup dir:\n  %s\n" "$BACKUP_DIR"
}

main() {
    [ -d "$DOT_DIR" ] || die "dotFile directory not found"

    install_packages
    install_nerd_font
    install_starship
    install_dotfiles
    fix_paths
    setup_shell
    setup_services
    fix_permissions
    reload_sway
    post_check

    log "Done"
    warn "This script does NOT install Wi-Fi passwords, netplan files, SSH keys, .env files, or private data."
    warn "Relogin may be required for shell/font/group changes."
}

main "$@"
