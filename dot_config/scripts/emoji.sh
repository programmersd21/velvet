#!/usr/bin/env bash

export YDOTOOL_SOCKET="$HOME/.ydotool_socket"

PREV_WIN=$(hyprctl activewindow -j | jq -r '.address')

SELECTION=$(rofimoji \
    --selector rofi \
    --selector-args="-theme ~/.config/rofi/velvet.rasi" \
    --skin-tone neutral \
    --action print)

[ -z "$SELECTION" ] && exit 0

EMOJI=$(echo "$SELECTION" | awk '{print $1}')

echo -n "$EMOJI" | wl-copy

# rofimoji takes slightly longer to close than plain rofi — wait before polling
sleep 0.2

if [[ -n "$PREV_WIN" ]]; then
    hyprctl dispatch focuswindow "address:0x${PREV_WIN#0x}"
    for i in {1..20}; do
        current=$(hyprctl activewindow -j | jq -r '.address')
        [[ "${current#0x}" == "${PREV_WIN#0x}" ]] && break
        sleep 0.05
    done
fi

ydotool key 29:1 47:1 47:0 29:0

# re-lock focus back on original window so next trigger captures correctly
sleep 0.05
[[ -n "$PREV_WIN" ]] && hyprctl dispatch focuswindow "address:0x${PREV_WIN#0x}"

# clear clipboard so emoji doesn't linger in history
sleep 0.1
cliphist list | head -n 1 | cliphist delete
