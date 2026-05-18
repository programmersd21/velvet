#!/usr/bin/env bash

SELECTION=$(rofimoji \
    --selector rofi \
    --selector-args="-theme ~/.config/rofi/velvet.rasi" \
    --skin-tone neutral \
    --action print)

if [ -n "$SELECTION" ]; then
    # Copy to clipboard
    echo -n "$SELECTION" | wl-copy

    # Give rofi a split second to close
    sleep 0.15
    
    # Force your compositor to send a hardware Ctrl+V to the active window
    hyprctl dispatch sendshortcut CTRL, v
fi
