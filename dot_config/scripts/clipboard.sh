#!/usr/bin/env bash
# velvet noir · clipboard manager

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
                cliphist decode <<< "$id" > /tmp/raw_img_clip.png 2>/dev/null
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
# extract the id (first field)
id=$(echo "$selection" | cut -f1)
cliphist decode <<< "$id" | wl-copy

# 5. wait to ensure clipboard is ready
sleep 0.2

# 6. paste
wtype -M ctrl -k v -m ctrl
