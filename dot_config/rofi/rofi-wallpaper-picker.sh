#!/usr/bin/env bash
# Rofi Wallpaper Picker with Image Previews
# Usage: rofi-wallpaper-picker

WALLPAPER_DIR="$HOME/.config/wallpapers"

find "$WALLPAPER_DIR" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) | \
  rofi -dmenu -i -p "Select Wallpaper" -theme ~/.config/rofi/velvet.rasi | \
  while read -r wallpaper; do
    [ -n "$wallpaper" ] || continue
    # Replace with your actual wallpaper setting tool (e.g., matugen)
    # matugen wallpaper "$wallpaper"
    echo "Selected: $wallpaper"
  done
