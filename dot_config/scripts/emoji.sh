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

# explicitly restore focus without warping the mouse
if [[ -n "$PREV_WIN" && "$PREV_WIN" != "null" ]]; then
    # Save current states
    WARP_STATE=$(hyprctl getoption cursor:no_warps -j | jq -r '.int')
    FOLLOW_STATE=$(hyprctl getoption input:follow_mouse -j | jq -r '.int')
    
    # Fallback to defaults if empty
    [[ -z "$WARP_STATE" ]] && WARP_STATE=0
    [[ -z "$FOLLOW_STATE" ]] && FOLLOW_STATE=1
    
    # Disable warping and follow-mouse temporarily so focus remains locked on original window
    hyprctl keyword cursor:no_warps 1
    hyprctl keyword input:follow_mouse 0
    
    # Force focus back to original window
    hyprctl dispatch focuswindow "address:0x${PREV_WIN#0x}"
    
    # Wait for focus to settle
    sleep 0.05
fi

ydotool key 29:1 47:1 47:0 29:0

# restore settings
if [[ -n "$PREV_WIN" && "$PREV_WIN" != "null" ]]; then
    sleep 0.05
    hyprctl keyword cursor:no_warps "$WARP_STATE"
    hyprctl keyword input:follow_mouse "$FOLLOW_STATE"
fi

# clear clipboard so emoji doesn't linger in history
sleep 0.1
cliphist list | head -n 1 | cliphist delete
