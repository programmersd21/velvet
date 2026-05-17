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

    # media & input
    brightnessctl
    playerctl
    wireplumber

    # network & bluetooth
    network-manager-applet
    blueman

    # auth
    polkit-gnome

    # fonts
    ttf-jetbrains-mono-nerd
    inter-font

    # icons
    papirus-icon-theme

    # general
    git
    base-devel
    jq
    imagemagick
    grim
    slurp
)

# aur
AUR_PKGS=(
    # launcher
    rofi-wayland

    # notification center
    sway-notification-center

    # wallpaper
    swww

    # color generation
    matugen-bin

    # shell prompt
    starship

    # visualizer
    cava

    # file manager
    yazi

    # power menu
    wlogout

    # screenshots
    hyprshot

    # lock & idle
    hyprlock
    hypridle

    # gtk theme
    adw-gtk3

    # cursor
    bibata-cursor-theme-bin

    # dotfile management
    chezmoi
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
REPO="https://github.com/programmersd21/velvet.git"

setup_dotfiles() {
    log "setting up dotfiles with chezmoi..."

    if [[ -d "$HOME/.local/share/chezmoi" ]]; then
        warn "chezmoi source directory already exists"
        if ask "overwrite existing dotfiles?"; then
            chezmoi init --apply --force "$REPO"
        else
            log "skipping dotfiles. you can apply later with: chezmoi init --apply $REPO"
            return
        fi
    else
        chezmoi init --apply --force "$REPO"
    fi

    ok "dotfiles applied"
}

# ── machine config ───────────────────────────────────────────────────────────
setup_machine_data() {
    local datafile="$HOME/.local/share/chezmoi/.chezmoidata.yaml"

    if [[ -f "$datafile" ]]; then
        ok "chezmoidata.yaml already exists"
        return
    fi

    log "setting up machine-specific config..."
    echo ""

    # detect primary monitor
    local mon_name mon_res mon_rate
    if command -v hyprctl &>/dev/null && hyprctl monitors &>/dev/null 2>&1; then
        mon_name=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].name // "eDP-1"')
        mon_res=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0] | "\(.width)x\(.height)"')
        mon_rate=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].refreshRate | floor')
        log "detected monitor: ${B}$mon_name${R} at ${B}$mon_res@${mon_rate}hz${R}"
    else
        mon_name="eDP-1"
        mon_res="1920x1080"
        mon_rate="60"
        warn "could not detect monitor. using defaults: $mon_name $mon_res@${mon_rate}hz"
    fi

    # laptop detection
    local is_laptop="false"
    if [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]; then
        is_laptop="true"
        log "detected: laptop (battery present)"
    else
        log "detected: desktop (no battery)"
    fi

    echo -ne "  ${T}?${R} accept these values? ${D}[y/n]${R} "
    read -r confirm

    if [[ "$confirm" =~ ^[yY] ]]; then
        true  # use detected values
    else
        echo -ne "  ${T}?${R} monitor name ${D}[$mon_name]${R}: "
        read -r input; [[ -n "$input" ]] && mon_name="$input"

        echo -ne "  ${T}?${R} resolution ${D}[$mon_res]${R}: "
        read -r input; [[ -n "$input" ]] && mon_res="$input"

        echo -ne "  ${T}?${R} refresh rate ${D}[$mon_rate]${R}: "
        read -r input; [[ -n "$input" ]] && mon_rate="$input"

        echo -ne "  ${T}?${R} is laptop ${D}[$is_laptop]${R}: "
        read -r input; [[ -n "$input" ]] && is_laptop="$input"
    fi

    cat > "$datafile" <<EOF
machine:
  monitor_name: "$mon_name"
  monitor_res: "$mon_res"
  monitor_rate: "$mon_rate"
  is_laptop: $is_laptop
EOF

    ok "wrote $datafile"

    # re-apply with new data
    log "re-applying dotfiles with machine data..."
    chezmoi apply --force
    ok "dotfiles re-applied"
}

# ── directories ──────────────────────────────────────────────────────────────
setup_directories() {
    log "creating directories..."
    mkdir -p ~/Pictures/Screenshots
    ok "directories ready"
}

# ── shell & config verification ──────────────────────────────────────────────
setup_shell() {
    log "verifying shell and config deployment..."

    # .bashrc — managed by chezmoi (dot_bashrc → ~/.bashrc)
    if [[ -f "$HOME/.bashrc" ]] && grep -q 'starship init' "$HOME/.bashrc"; then
        ok ".bashrc deployed (includes starship, fastfetch, aliases)"
    else
        warn ".bashrc may not have been applied — run 'chezmoi apply' to fix"
    fi

    # starship.toml — managed by chezmoi (dot_config/starship/starship.toml → ~/.config/starship/starship.toml)
    if [[ -f "$HOME/.config/starship/starship.toml" ]]; then
        ok "starship.toml in place"
    else
        warn "starship.toml missing — run 'chezmoi apply' to fix"
    fi

    # scripts — managed by chezmoi (dot_config/scripts/ → ~/.config/scripts/)
    if [[ -f "$HOME/.config/scripts/theme-switch.sh" ]]; then
        chmod +x "$HOME/.config/scripts/theme-switch.sh"
        ok "theme-switch.sh ready"
    else
        warn "theme-switch.sh missing — run 'chezmoi apply' to fix"
    fi

    # wallpapers — managed by chezmoi (dot_config/wallpapers/ → ~/.config/wallpapers/)
    local wp_count
    wp_count=$(find "$HOME/.config/wallpapers" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" -o -name "*.jpeg" \) 2>/dev/null | wc -l)
    if [[ "$wp_count" -gt 0 ]]; then
        ok "wallpaper collection ready ($wp_count images in ~/.config/wallpapers/)"
    else
        warn "no wallpapers found in ~/.config/wallpapers/"
    fi
}

# ── bootstrap matugen colors ─────────────────────────────────────────────────
bootstrap_colors() {
    log "bootstrapping color scheme with matugen..."

    if ! command -v matugen &>/dev/null; then
        warn "matugen not found — skipping color bootstrap"
        warn "run theme-switch.sh manually after installing matugen"
        return
    fi

    # find a wallpaper to seed the initial palette from ~/.config/wallpapers/
    local seed_wallpaper=""

    # prefer a file named default.* if it exists
    if [[ -f "$HOME/.config/wallpapers/others/default.jpg" ]]; then
        seed_wallpaper="$HOME/.config/wallpapers/others/default.jpg"
    else
        # pick the first wallpaper from the shipped collection
        seed_wallpaper=$(find "$HOME/.config/wallpapers" -type f \( -name "*.jpg" -o -name "*.png" -o -name "*.webp" -o -name "*.jpeg" \) 2>/dev/null | head -n 1)
    fi

    if [[ -z "$seed_wallpaper" ]]; then
        warn "no wallpaper found to seed colors"
        warn "add images to ~/.config/wallpapers/ then run:"
        warn "  ~/.config/scripts/theme-switch.sh ~/.config/wallpapers/<image>"
        return
    fi

    log "seeding palette from: ${B}$(basename "$seed_wallpaper")${R}"
    matugen image "$seed_wallpaper" -m dark 2>&1 || {
        warn "matugen failed — you can re-run later with theme-switch.sh"
        return
    }

    ok "color scheme generated — waybar, rofi, kitty, etc. are ready"
}

# ── post-install ─────────────────────────────────────────────────────────────
post_install() {
    log "running post-install setup..."

    # set gtk theme
    if command -v gsettings &>/dev/null; then
        gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
        gsettings set org.gnome.desktop.interface font-name 'Inter 11' 2>/dev/null || true
        gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
        ok "gtk settings applied"
    fi

    # ensure all scripts are executable
    chmod +x ~/.config/rofi/wallpaper-picker 2>/dev/null || true
    chmod +x ~/.config/scripts/theme-switch.sh 2>/dev/null || true
    chmod +x ~/.config/rofi/rofi-wallpaper-picker.sh 2>/dev/null || true

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
    echo ""
    echo -e "  ${D}useful commands:${R}"
    echo -e "    ${D}hyprctl reload${R}          reload compositor"
    echo -e "    ${D}chezmoi apply${R}           re-apply dotfiles"
    echo -e "    ${D}chezmoi diff${R}            preview changes"
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
    setup_directories
    echo ""
    setup_dotfiles
    echo ""
    setup_machine_data
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
