#!/usr/bin/env bash
# velvet noir · clipboard manager

export YDOTOOL_SOCKET="$HOME/.ydotool_socket"

tmp_dir="/tmp/cliphist"
mkdir -p "$tmp_dir"

# list clipboard items with square image previews
get_list() {
    echo "󰒲 Clear All"
    
    # cliphist list output uses tab separated: ID\tContent
    cliphist list | while IFS=$'\t' read -r id content; do
        
        # detect if the item is an image (based on metadata or content type)
        # binary entries for images show [image/...] in cliphist list
        if [[ "$content" == *"[[ binary data"* ]]; then
            icon_path="$tmp_dir/${id}_thumb.png"
            
            # generate thumbnail if it doesn't exist
            if [[ ! -f "$icon_path" ]]; then
                echo -n "$id" | cliphist decode > /tmp/raw_img_clip.png 2>/dev/null
                # use imagemagick to create a square thumbnail
                convert /tmp/raw_img_clip.png -gravity center -extent 1:1 -resize 128x128 "$icon_path" 2>/dev/null
                rm /tmp/raw_img_clip.png
            fi
            
            # show icon if available
            [[ -f "$icon_path" ]] && echo -e "$id\t$content\0icon\x1f$icon_path" || echo -e "$id\t$content"
        else
            echo -e "$id\t$content"
        fi
    done
}

# 1. capture selection
# note: -dmenu requires tab-separated fields for icon support
PREV_WIN=$(hyprctl activewindow -j | jq -r '.address')
selection=$(get_list | rofi -dmenu -i -p "CLIP" -show-icons -theme ~/.config/rofi/velvet.rasi)

# 2. exit if nothing selected
[[ -z "$selection" ]] && exit 0

# 3. handle "Clear All"
if [[ "$selection" == *"Clear All"* ]]; then
    cliphist wipe
    notify-send "Clipboard" "History cleared"
    exit 0
fi

# 4. decode and copy
echo "$selection" | cliphist decode | wl-copy

# 5. restore focus and wait until compositor confirms it before pasting
if [[ -n "$PREV_WIN" ]]; then
    hyprctl dispatch focuswindow "address:0x${PREV_WIN#0x}"
    for i in {1..20}; do
        current=$(hyprctl activewindow -j | jq -r '.address')
        [[ "${current#0x}" == "${PREV_WIN#0x}" ]] && break
        sleep 0.05
    done
fi

# 6. paste
ydotool key 29:1 47:1 47:0 29:0

# 7. re-lock focus back on original window so next trigger captures correctly
sleep 0.05
[[ -n "$PREV_WIN" ]] && hyprctl dispatch focuswindow "address:0x${PREV_WIN#0x}"
