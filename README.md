# velvet noir
### a glass-forward, dynamically themed hyprland experience.

![demo](/screenshots/demo.gif)

*velvet noir in action: dynamic themes, glassmorphism, and smooth animations.*

[about](#about) • [gallery](#gallery) • [features](#features) • [install](#install)

---

### about
velvet noir is a minimalist, dark-glass rice built for speed and aesthetics. it uses **matugen** to generate system-wide color palettes from your wallpaper on the fly, managed entirely by **chezmoi**. 

---

### gallery

| waybar | fastfetch |
| :---: | :---: |
| ![](/screenshots/waybar.png) | ![](/screenshots/fastfetch.png) |
| *floating pill modules* | *minimal system info* |

| terminal | swaync |
| :---: | :---: |
| ![](/screenshots/terminal.png) | ![](/screenshots/swaync.png) |
| *85% kitty glass* | *blurred notification center* |

| yazi | btop |
| :---: | :---: |
| ![](/screenshots/yazi.png) | ![](/screenshots/btop.png) |
| *terminal file manager* | *resource monitor* |

| apps menu | emoji picker |
| :---: | :---: |
| ![](/screenshots/apps_menu.png) | ![](/screenshots/emoji_menu.png) |
| *snappy glass launcher* | *quick unicode selector* |

| wallpaper selector | power menu |
| :---: | :---: |
| ![](/screenshots/wallpaper_menu.png) | ![](/screenshots/wlogout.png) |
| *visual theme switcher* | *glass session control* |

| lock screen | main workspace |
| :---: | :---: |
| ![](/screenshots/hyprlock.png) | ![](/screenshots/main.png) |
| *animated blurred locker* | *static main workspace* |

---

### features

- **hyprland**: 14px rounding, 4-pass blur, and `whooshZap` animations.
- **waybar**: 44px top bar with debossed pill modules and hover-lift effects.
- **starship**: tokyo-night powerline prompt with dynamic matugen colors.
- **rofi**: snappy, expanding glass launcher with blurred backgrounds.
- **kitty**: jetbrainsmono nerd font, 85% opacity, and 64-level blur.
- **automation**: single-command theme syncing via `theme-switch.sh`.

---

### details

**window rules**
```conf
# glass & layout
windowrule = opacity 0.88 0.82, kitty
windowrule = float, pavucontrol|blueman-manager
layerrule = blur, rofi|swaync
```

**core binds**
```conf
$mod = SUPER

bind = $mod, RETURN, exec, kitty
bind = $mod, SPACE,  exec, rofi -show drun
bind = $mod, W,      exec, wallpaper-picker
bind = $mod, W,      exec, emoji.sh
bind = $mod, C,      exec, clipboard-manager
bind = $mod, Q,      killactive
bind = $mod, E,      exec, kitty -e yazi
```

---

### install

**01. bootstrap (arch only)**
```bash
git clone https://github.com/programmersd21/velvet.git
cd velvet && chmod +x dot_config/install.sh && cd dot_config && ./install.sh
```

**02. sync colors**
```bash
# pick a wallpaper to generate the palette
~/.config/scripts/theme-switch.sh ~/.config/wallpapers/others/default.jpg
```

---
<p align="center">voided by <a href="https://github.com/programmersd21">programmersd21</a></p>
