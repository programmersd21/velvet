## Description
Provide a clear description of the changes introduced by this Pull Request. If this PR closes or resolves an open issue, link it here (e.g., `Closes #12`).

## Why is this change needed?
Explain the rationale for these modifications. What benefit does it bring to the **Velvet Noir** experience?

## Affected Components
Check all that apply:
- [ ] **Installer** (`install.sh`, pacman/AUR package lists)
- [ ] **Compositor/Layout** (Hyprland window rules, keybinds, layout settings)
- [ ] **Visual Elements** (Waybar modules, SwayNC notifications, Rofi launcher/picker)
- [ ] **Shell Prompt / Term** (Starship config, Kitty terminal, bash aliases)
- [ ] **Scripts & Utilities** (Theme-switch, clipboard, emoji scripts, wallpaper-picker)

## Verification & Testing

### 1. Manual Testing
Explain how you tested this change locally on your machine.
* **Distro/Architecture tested on:** e.g., Arch Linux (x86_64), CachyOS
* **Display Server/Compositor:** Hyprland
* **Steps taken to test:**

### 2. Chezmoi & Script Check
- [ ] I ran `chezmoi apply --dry-run` locally and verified that the templates compiled with no syntax errors.
- [ ] I ran `shellcheck` on all modified or new shell scripts and resolved all severe syntax/lint warnings.
- [ ] If I added new packages or dependencies, I added them to the appropriate list (`PACMAN_PKGS` or `AUR_PKGS`) in `dot_config/install.sh`.

## Design Aesthetics (Strict Rule)
- [ ] My changes fully adhere to the **Velvet Noir premium glass-forward design guidelines** (e.g., 14px rounding, proper 4-pass blur layers, sleek dark mode matching the dynamic matugen palette, no harsh/raw default colors).

## Media (Required for Visual Changes)
If your PR modifies any visual components (Waybar modules, Rofi menus, Hyprland layouts, window aesthetics), please attach a screenshot or screen recording demonstrating your changes.
*(Paste screenshots/animations here)*
