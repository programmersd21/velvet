#!/usr/bin/env bash
# chezmoi source: scripts/mpris.sh
# chezmoi destination: ~/.config/scripts/mpris.sh

status=$(playerctl status 2>/dev/null)

if [ -z "$status" ] || [ "$status" = "Stopped" ]; then
    jq -nc \
        --arg text "󰎆  nothing playing" \
        --arg class "stopped" \
        --arg tooltip "Nothing playing" \
        '{text: $text, class: $class, tooltip: $tooltip}'
    exit 0
fi

player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null)

case "$player" in
    *spotify*) icon="󰓇" ;;
    *firefox*) icon="󰈹" ;;
    *chromium*) icon="󰊯" ;;
    *mpv*) icon="󰐹" ;;
    *) icon="󰎆" ;;
esac

title=$(playerctl metadata title 2>/dev/null)
artist=$(playerctl metadata artist 2>/dev/null)

if [ -z "$title" ] && [ -z "$artist" ]; then
    if [ "$status" = "Playing" ]; then
        text="$icon  $player (Playing)"
        class="playing"
    else
        text="󰏤  $player (Paused)"
        class="paused"
    fi
    tooltip="Player: $player · Status: $status"
else
    if [ -z "$title" ]; then
        title="Unknown Title"
    fi
    if [ -z "$artist" ]; then
        display_text="$title"
    else
        display_text="$title - $artist"
    fi

    if [ "$status" = "Playing" ]; then
        text="$icon  $display_text"
        class="playing"
    elif [ "$status" = "Paused" ]; then
        text="󰏤  $display_text"
        class="paused"
    else
        text="󰎆  nothing playing"
        class="stopped"
    fi
    tooltip="Player: $player · Status: $status · Track: $display_text"
fi

jq -nc \
    --arg text "$text" \
    --arg class "$class" \
    --arg tooltip "$tooltip" \
    '{text: $text, class: $class, tooltip: $tooltip}'
