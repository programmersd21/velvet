#!/usr/bin/env bash

export YDOTOOL_SOCKET="$HOME/.ydotool_socket"

TMP_DIR="/tmp/cliphist"
mkdir -p "$TMP_DIR"

get_list() {
    echo "󰒲 Clear All"

    cliphist list | while IFS=$'\t' read -r id content; do
        if [[ "$content" == *"binary data"* ]]; then
            icon="$TMP_DIR/${id}.png"

            if [[ ! -f "$icon" ]]; then
                echo "$id" | cliphist decode > /tmp/cliphist_raw 2>/dev/null

                magick /tmp/cliphist_raw \
                    -thumbnail 128x128^ \
                    -gravity center \
                    -extent 128x128 \
                    "$icon" 2>/dev/null

                rm -f /tmp/cliphist_raw
            fi

            if [[ -f "$icon" ]]; then
                printf "%s\t%s\0icon\x1f%s\n" "$id" "$content" "$icon"
            else
                printf "%s\t%s\n" "$id" "$content"
            fi
        else
            printf "%s\t%s\n" "$id" "$content"
        fi
    done
}

PREV_WIN=$(hyprctl activewindow -j | jq -r '.address')

SELECTION=$(get_list | rofi \
    -dmenu \
    -i \
    -show-icons \
    -theme ~/.config/rofi/velvet.rasi \
    -p "CLIP")

[[ -z "$SELECTION" ]] && exit 0

if [[ "$SELECTION" == *"Clear All"* ]]; then
    cliphist wipe
    notify-send "Clipboard" "History cleared"
    exit 0
fi

ID=$(printf '%s\n' "$SELECTION" | cut -f1)

printf '%s' "$ID" | cliphist decode | wl-copy

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

# 6. paste
ydotool key 29:1 47:1 47:0 29:0

# 7. restore settings
if [[ -n "$PREV_WIN" && "$PREV_WIN" != "null" ]]; then
    sleep 0.05
    hyprctl keyword cursor:no_warps "$WARP_STATE"
    hyprctl keyword input:follow_mouse "$FOLLOW_STATE"
fi
