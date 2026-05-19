#!/usr/bin/env bash
# ┌──────────────────────────────────────────────────────────────────────────────┐
# │  velvet noir · installer                                                    │
# │  arch linux + hyprland                                                      │
# └──────────────────────────────────────────────────────────────────────────────┘

set -euo pipefail

# ── colors ───────────────────────────────────────────────────────────────────
R='\033[0m'
B='\033[1m'
D='\033[2m'
V='\033[38;5;141m'  # violet
T='\033[38;5;116m'  # teal
P='\033[38;5;175m'  # rose
Y='\033[38;5;222m'  # gold
RD='\033[38;5;210m' # red
G='\033[38;5;151m'  # green

# ── helpers ──────────────────────────────────────────────────────────────────
log()  { echo -e "  ${V}·${R} $1"; }
ok()   { echo -e "  ${G}✓${R} $1"; }
warn() { echo -e "  ${Y}!${R} $1"; }
err()  { echo -e "  ${RD}✗${R} $1"; }
ask()  { echo -ne "  ${T}?${R} $1 ${D}[y/n]${R} "; read -r ans; [[ "$ans" =~ ^[yY] ]]; }

header() {
    echo ""
    echo -e "  ${V}${B}velvet noir${R} ${D}· installer${R}"
    echo -e "  ${D}────────────────────────────${R}"
    echo ""
}

# ── preflight ────────────────────────────────────────────────────────────────
check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        local detected
        detected=$(grep ^NAME /etc/os-release 2>/dev/null | cut -d= -f2 || echo 'unknown')
        err "this installer is designed for arch linux (and derivatives like CachyOS)"
        err "detected: $detected"
        if ! ask "continue anyway?"; then
            exit 1
        fi
    else
        local distro
        distro=$(grep ^NAME /etc/os-release 2>/dev/null | cut -d= -f2 | tr -d '"' || echo 'Arch Linux')
        ok "detected ${B}${distro}${R}"
    fi
}

check_aur_helper() {
    if command -v yay &>/dev/null; then
        AUR="yay"
    elif command -v paru &>/dev/null; then
        AUR="paru"
    else
        warn "no aur helper found (yay or paru)"
        if ask "install yay?"; then
            log "installing yay..."
            sudo pacman -S --needed --noconfirm git base-devel
            tmpdir=$(mktemp -d)
            git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
            (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
            rm -rf "$tmpdir"
            AUR="yay"
            ok "yay installed"
        else
            err "an aur helper is required. install yay or paru and try again."
            exit 1
        fi
    fi
    ok "using ${B}$AUR${R} as aur helper"
}

# ── packages ─────────────────────────────────────────────────────────────────

# official repos
PACMAN_PKGS=(
    # compositor & wm
    hyprland
    xdg-desktop-portal-hyprland

    # bar & notifications
    waybar

    # terminal
    kitty

    # system tools
    btop
    fastfetch
    rsync

    # media & input
    brightnessctl
    playerctl
    wireplumber

    # network & bluetooth
    networkmanager
    blueman

    # auth
    polkit-gnome

    # fonts
    ttf-jetbrains-mono-nerd
    inter-font

    # emoji menu
    rofimoji

    # icons
    papirus-icon-theme

    # general
    git
    base-devel
    grim
    slurp
    cliphist
    wl-clipboard
    ydotool

    # utilities & dependencies
    ffmpeg
    p7zip
    jq
    poppler
    fd
    ripgrep
    fzf
    zoxide
    imagemagick
)

# aur
AUR_PKGS=(
    # launcher
    rofi-wayland

    # notification center
    swaync

    # wallpaper daemon
    awww

    # color generation
    matugen-bin

    # shell prompt
    starship

    # visualizer
    cava

    # file manager
    yazi-nightly-bin

    # power menu
    wlogout

    # screenshots
    hyprshot

    # lock & idle
    hyprlock
    hypridle

    # gtk theme
    adw-gtk-theme

    # cursor
    bibata-cursor-theme-bin
)

install_packages() {
    log "updating system..."
    sudo pacman -Syu --noconfirm

    log "installing official packages..."
    if ! sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"; then
        warn "some official packages may have failed — check the output above"
    fi
    ok "official packages done"

    log "installing aur packages..."
    for pkg in "${AUR_PKGS[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            echo -e "    ${D}skip${R} $pkg ${D}(installed)${R}"
        else
            echo -e "    ${V}install${R} $pkg"
            if ! $AUR -S --needed --noconfirm "$pkg"; then
                warn "failed to install $pkg — you may need to install it manually"
            fi
        fi
    done
    ok "aur packages done"
}

# ── dotfiles ─────────────────────────────────────────────────────────────────
setup_dotfiles() {
    log "syncing dotfiles using rsync..."

    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local src_dir="$script_dir"

    mkdir -p "$HOME/.config"

    rsync -a --progress \
        --exclude="install.sh" \
        --exclude=".git/" \
        --exclude=".github/" \
        --exclude="README.md" \
        --exclude="LICENSE" \
        "$src_dir/" "$HOME/.config/"

    ok "dotfiles synced to ~/.config"

    # copy ../dot_bashrc (relative to this script) → ~/.bashrc
    if [[ -f "$script_dir/../dot_bashrc" ]]; then
        cp "$script_dir/../dot_bashrc" "$HOME/.bashrc"
        ok "dot_bashrc copied to ~/.bashrc"
    else
        warn "../dot_bashrc not found — skipping"
    fi
}

# ── directories ──────────────────────────────────────────────────────────────
setup_directories() {
    log "creating directories..."
    mkdir -p ~/Pictures/Screenshots
    mkdir -p "$HOME/.config/wallpapers/calm"
    mkdir -p "$HOME/.config/wallpapers/others"
    ok "directories ready"
}

# ── shell & config verification ──────────────────────────────────────────────
setup_shell() {
    log "verifying shell and config deployment..."

    # .bashrc
    if [[ -f "$HOME/.bashrc" ]] && grep -q 'starship init' "$HOME/.bashrc"; then
        ok ".bashrc deployed (includes starship, fastfetch, aliases)"
    else
        warn ".bashrc may not have been applied — check ~/.config/.bashrc or re-run rsync"
    fi

    # starship.toml
    if [[ -f "$HOME/.config/starship/starship.toml" ]]; then
        ok "starship.toml in place"
    else
        warn "starship.toml missing — check your repo structure"
    fi

    # scripts
    if [[ -f "$HOME/.config/scripts/theme-switch.sh" ]]; then
        chmod +x "$HOME/.config/scripts/theme-switch.sh"
        ok "theme-switch.sh ready"
    else
        warn "theme-switch.sh missing — check your repo structure"
    fi

    # wallpapers
    local wp_count
    wp_count=$(find "$HOME/.config/wallpapers" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" -o -name "*.jpeg" \) 2>/dev/null | wc -l)
    if [[ "$wp_count" -gt 0 ]]; then
        ok "wallpaper collection ready ($wp_count images in ~/.config/wallpapers/)"
    else
        warn "no wallpapers found in ~/.config/wallpapers/"
    fi
}

# ── wallpaper stack: awww + matugen ─────────────────────────────────────────
set_wallpaper() {
    local img="$1"

    if ! command -v awww &>/dev/null; then
        warn "awww not found — skipping wallpaper"
        return
    fi

    # kill any stale daemon before starting fresh
    pkill awww-daemon 2>/dev/null || true
    sleep 0.2

    # start daemon detached — survives installer exit
    awww-daemon >/dev/null 2>&1 & disown

    # give socket time to come up
    sleep 0.3

    awww img "$img" \
        --transition-type grow \
        --transition-duration 1.2 \
        --transition-fps 60 \
        --transition-step 6

    ok "wallpaper set: $(basename "$img")"

    if command -v matugen &>/dev/null; then
        matugen image "$img" -m dark --source-color-index 0
        ok "matugen theme generated"
    else
        warn "matugen not installed — skipping theme generation"
    fi
}

bootstrap_colors() {
    log "bootstrapping wallpaper + color scheme..."

    local seed_wallpaper=""

    # prefer specific default if it exists
    if [[ -f "$HOME/.config/wallpapers/calm/a_beach_with_trees_on_the_side.jpg" ]]; then
        seed_wallpaper="$HOME/.config/wallpapers/calm/a_beach_with_trees_on_the_side.jpg"
    elif [[ -f "$HOME/.config/wallpapers/others/default.jpg" ]]; then
        seed_wallpaper="$HOME/.config/wallpapers/others/default.jpg"
    else
        seed_wallpaper=$(find "$HOME/.config/wallpapers" -type f \
            \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" -o -name "*.jpeg" \) \
            2>/dev/null | head -n 1)
    fi

    if [[ -z "$seed_wallpaper" ]]; then
        warn "no wallpaper found to seed colors"
        warn "add images to ~/.config/wallpapers/ then run:"
        warn "  ~/.config/scripts/theme-switch.sh <image>"
        return
    fi

    log "seeding from: ${B}$(basename "$seed_wallpaper")${R}"
    set_wallpaper "$seed_wallpaper"

    ok "wallpaper + colors bootstrapped"
}

# ── ydotool ──────────────────────────────────────────────────────────────────
setup_ydotool() {
    log "configuring ydotool..."

    if id -nG "$USER" | grep -qw input; then
        ok "user already in input group"
    else
        sudo usermod -aG input "$USER"
        ok "added $USER to input group"
    fi

    echo "uinput" | sudo tee /etc/modules-load.d/uinput.conf >/dev/null
    sudo modprobe uinput 2>/dev/null || true
    sudo udevadm control --reload-rules >/dev/null 2>&1 || true
    sudo udevadm trigger >/dev/null 2>&1 || true

    local override_dir="$HOME/.config/systemd/user/ydotool.service.d"
    local override_file="$override_dir/override.conf"
    mkdir -p "$override_dir"
    cat > "$override_file" <<'EOF'
[Service]
ExecStart=
ExecStart=/usr/bin/ydotoold --socket-path=%h/.ydotool_socket
Environment=YDOTOOL_SOCKET=%h/.ydotool_socket
EOF
    ok "wrote ydotool socket override"

    systemctl --user daemon-reload

    if systemctl --user list-unit-files | grep -q "^ydotool.service"; then
        systemctl --user stop ydotool.service >/dev/null 2>&1 || true
        systemctl --user reset-failed ydotool.service >/dev/null 2>&1 || true
        rm -f /run/user/"${UID}"/.ydotool_socket "$HOME"/.ydotool_socket
        systemctl --user enable --now ydotool.service >/dev/null 2>&1 || true
        ok "enabled ydotool.service"
    else
        warn "ydotool.service not found — skipping"
    fi

    sleep 0.5
    if pgrep -x ydotoold >/dev/null; then
        ok "ydotoold running"
    else
        warn "ydotoold not running yet — a reboot may be required"
    fi
}

# ── post-install ─────────────────────────────────────────────────────────────
post_install() {
    log "running post-install setup..."

    if command -v gsettings &>/dev/null; then
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
        gsettings set org.gnome.desktop.interface font-name 'Inter 11' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
        ok "gtk settings applied"
    fi

    chmod +x ~/.config/rofi/wallpaper-picker 2>/dev/null || true
    chmod +x ~/.config/scripts/theme-switch.sh 2>/dev/null || true
    chmod +x ~/.config/scripts/clipboard.sh 2>/dev/null || true
    chmod +x ~/.config/scripts/mpris.sh 2>/dev/null || true

    ok "post-install done"
}

# ── summary ──────────────────────────────────────────────────────────────────
finish() {
    echo ""
    echo -e "  ${V}${B}velvet noir${R} ${G}installed${R}"
    echo -e "  ${D}────────────────────────────${R}"
    echo ""
    echo -e "  ${D}next steps:${R}"
    echo -e "    1. log out and select ${B}hyprland${R} from your display manager"
    echo -e "    2. press ${B}super+w${R} to pick a wallpaper and sync colors"
    echo -e "    3. reboot once for ${B}ydotool${R} permissions"
    echo ""
    echo -e "  ${D}useful commands:${R}"
    echo -e "    ${D}hyprctl reload${R}          reload compositor"
    echo -e "    ${D}rsync -a <repo>/ ~/.config/${R}  re-sync dotfiles"
    echo ""
}

# ── main ─────────────────────────────────────────────────────────────────────
main() {
    header
    check_arch
    check_aur_helper

    echo ""
    log "this will install velvet noir and its dependencies."
    log "packages will be installed via pacman and $AUR."
    echo ""

    if ! ask "proceed with installation?"; then
        log "cancelled."
        exit 0
    fi

    echo ""
    install_packages
    echo ""
    setup_ydotool
    echo ""
    setup_directories
    echo ""
    setup_dotfiles
    echo ""
    setup_shell
    echo ""
    bootstrap_colors
    echo ""
    post_install
    echo ""
    finish
}

main "$@"
