# Contributing to Velvet Noir

First off, thank you for taking the time to contribute! 🎉 

Velvet Noir is built on a foundation of speed, minimalist aesthetics, and dynamic automation. We welcome contributions that improve stability, clean up configuration files, optimize performance, or add gorgeous, glass-forward features.

This document outlines the workflow and style guides to help you get started.

---

## 🛠️ Repository & Chezmoi Architecture

This repository is managed by [chezmoi](https://www.chezmoi.io/). Do not edit your home folder files directly and copy them over; instead, follow the chezmoi git workflow.

### 1. File Structure & Mappings
All dotfiles in this repository use the chezmoi mapping convention:
- Files and directories starting with `dot_` correspond to dot-prefixed targets in your `$HOME` directory.
  - `dot_config/` maps to `~/.config/`
  - `dot_local/` maps to `~/.local/`
  - `dot_bashrc` maps to `~/.bashrc`
- Plain directories represent normal folders in your `$HOME`.

### 2. Local Development Workflow
The standard process to edit and propose changes is:

1. **Clone & Setup**:
   ```bash
   git clone https://github.com/programmersd21/velvet.git
   cd velvet
   ```
2. **Make Changes**:
   You can either edit files directly inside the repository (`~/.local/share/chezmoi/`) or edit them in your home directory (`~/.config/...`) and copy/add them using chezmoi:
   ```bash
   # Add an edited file to your chezmoi repository
   chezmoi add ~/.config/hypr/hyprland.conf
   ```
3. **Verify Your Changes**:
   Always run a dry-run to preview what will change on your system:
   ```bash
   chezmoi diff
   chezmoi apply --dry-run
   ```
4. **Test Compilation**:
   Ensure chezmoi compiles all templates correctly:
   ```bash
   chezmoi apply
   ```

---

## 🎨 Coding & Design Standards

To maintain the premium look and feel of **Velvet Noir**, please adhere to these strict rules:

### 1. Visual Aesthetics (Glassmorphism)
All UI additions (Waybar widgets, Rofi lists, notification boxes) must match the dark-glass rice aesthetic:
- **Opacity**: Terminal / floating elements should target around `0.82` (active) to `0.88` (inactive).
- **Corners**: Use exactly `14px` (or `16px` for larger cards) border-radius for windows/menus.
- **Blur**: Enable 4-pass blur layers in Hyprland configs where applicable:
  ```ini
  layerrule = blur, rofi|swaync
  ```
- **Typography**: Prefer **Inter** or **JetBrainsMono Nerd Font** for text and icons. Do not use generic sans-serif fonts.

### 2. Dynamic Colors (Matugen Integration)
Velvet Noir uses [Matugen](https://github.com/InkoHX/matugen) to generate system-wide color palettes on the fly.
- **Never hardcode static HEX colors** (like `#ff0000` or `#333333`) in theme stylesheets (Rofi `.rasi`, Waybar `.css`, Kitty configs).
- Always import or template colors from the generated Matugen colorsheet:
  - In Rofi: Import `@import "colors.rasi"`
  - In Waybar: Import `@import "colors.css"`
  - In Starship: Reference the matugen environmental/system palette colors.

### 3. Shell Scripting Guidelines
All custom shell scripts located in `dot_config/scripts/` must:
- Start with a proper shebang: `#!/usr/bin/env bash`.
- Utilize strict error handling: `set -euo pipefail` where applicable.
- Pass `shellcheck` linting with no critical warnings or syntax errors.
- Have correct file permissions. (Chezmoi tracks permissions automatically: files in `dot_config/scripts/` will be rendered executable on deployment if they are executable in the repository).

---

## 🚀 Submitting a Pull Request

1. **Commit Messages**: Write meaningful commit messages. Explain *why* you made a change, not just *what* changed.
2. **Check for Duplicates**: Search open and closed issues/PRs to ensure someone else isn't already working on the same thing.
3. **Verify locally**: Make sure `chezmoi apply --dry-run` and `shellcheck` pass perfectly.
4. **Fill out the Template**: Follow the checkboxes and explain your testing steps in the Pull Request template.
5. **UI Screenshots**: If you changed Waybar, Rofi, swaync, fastfetch, or Hyprland aesthetics, **you must** include a screenshot or screen recording in your PR description.

Thank you for keeping Velvet Noir gorgeous and high-performance! 🌌
