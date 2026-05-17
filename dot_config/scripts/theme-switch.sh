#!/usr/bin/env bash
# chezmoi source: scripts/theme-switch.sh
# chezmoi destination: ~/scripts/theme-switch.sh

# // Ricer's Log
# // 1. Automation: Single-command wallpaper and color theme synchronization.
# // 2. Triggering: Seamless reloads for all UI components.

if [ -z "$1" ]; then
    echo "Usage: theme-switch.sh <path_to_wallpaper>"
    exit 1
fi

awww img "$1" --transition-type grow --transition-duration 1.2
matugen image "$1" -m dark --source-color-index 0

# Maintain wallpaper reference for hyprlock
cp -f "$1" "$HOME/.config/hypr/current_wallpaper" 2>/dev/null || true

pkill -SIGUSR2 waybar
swaync-client -rs
hyprctl reload
