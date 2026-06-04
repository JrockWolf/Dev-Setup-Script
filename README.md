# Linux Machine Setup

Automated setup script for a fresh Linux install. Supports **Debian-based**, **Fedora-based**, and **Arch-based** distros. Applies a **black & purple** theme for i3 + polybar.

## Quick Start

```bash
git clone <this-repo> ~/linux-setup
cd ~/linux-setup
chmod +x install.sh
./install.sh
```

The script auto-detects your distro and asks which desktop environment(s) to install before doing anything.

---

## What Gets Installed

### Desktop Environments (you choose)
| DE | Display Manager | Notes |
|---|---|---|
| **i3** | LightDM | Full config deployed: polybar, picom, rofi |
| **KDE Plasma** | SDDM | Minimal install, apply purple theme manually |
| **XFCE** | LightDM | Minimal install, apply theme manually |
| **Cinnamon** | LightDM | Minimal install, apply theme manually |

### Browsers
- **Firefox** — native package
- **Brave** — official repo (all distros)
- **Librewolf** — Flatpak

### Editors
- **Neovim** — latest stable
- **Helix** — latest stable
- **VSCode** — official Microsoft repo

### Communication
- **Discord** — native deb (Debian) / Flatpak (Fedora/Arch)
- **Telegram** — Flatpak

### Media
- **OBS Studio** — native package
- **VLC** — native package
- **Spotify** — Flatpak
- **Dopamine** — Flatpak (or see manual note below)

### Productivity
- **Obsidian** — Flatpak

### Full-Stack Dev Tools
| Tool | Method |
|---|---|
| Node.js (LTS) | nvm |
| Python 3 + pip | native |
| Docker + Compose | get.docker.com script |
| Rust + Cargo | rustup |
| Go | native / go.dev binary |
| PostgreSQL client | native |
| tmux | native |
| jq + httpie + curl + wget | native |
| Beekeeper Studio | Flatpak |
| Opencode CLI | npm / opencode.ai installer |

### System
- **Flatpak + Flathub**
- **fastfetch** — with custom wolf ASCII art (Blazej Kozlowski)

---

## i3 Theme (Black & Purple)

Configs are deployed automatically when you select i3:

```
~/.config/i3/config          # i3 WM configuration
~/.config/polybar/config.ini # Bar (purple, top of screen)
~/.config/polybar/launch.sh  # Multi-monitor launch script
~/.config/picom/picom.conf   # Compositor (shadows, blur, rounded corners)
~/.config/rofi/launcher.rasi # App launcher theme
~/.config/fastfetch/         # System info + wolf ASCII art
```

### Color Palette
| Name | Hex | Use |
|---|---|---|
| Background | `#0a0a0a` | Window/bar background |
| Dark purple | `#130020` | Active window bg, panel bg |
| Purple | `#9b30ff` | Focused borders, active WS |
| Glow purple | `#bf5fff` | Icons, highlights |
| Indigo | `#4b0082` | Inactive borders |
| Text | `#e2d9f3` | Foreground text |

### Key Bindings (i3)
| Key | Action |
|---|---|
| `Super + Enter` | Open terminal |
| `Super + D` | Rofi app launcher |
| `Super + Tab` | Rofi window switcher |
| `Super + Q` | Kill focused window |
| `Super + H/J/K/L` | Focus left/down/up/right |
| `Super + Shift + H/J/K/L` | Move window |
| `Super + F` | Fullscreen toggle |
| `Super + R` | Resize mode |
| `Super + 1–0` | Switch workspace |
| `Super + Shift + 1–0` | Move to workspace |
| `Print` | Full screenshot → ~/Pictures/ |
| `Super + Print` | Window screenshot |
| `Shift + Print` | Region screenshot |
| `Super + Shift + R` | Restart i3 |
| `Super + Shift + E` | Exit i3 |

### Wallpaper
Place a wallpaper at `~/.config/i3/wallpaper.jpg` — it will be applied automatically on i3 start. Swap `feh` for `nitrogen` in the i3 config if you prefer a GUI picker.

---

## Applying Themes for KDE / XFCE / Cinnamon

For non-i3 DEs, apply the purple theme manually after first login:

### KDE Plasma
1. System Settings → Appearance → Global Theme → **Breeze Dark**
2. Install **Kvantum** theme manager, apply **KvArcDark** or **Nightfall**
3. System Settings → Colors → set accent color to `#9b30ff`
4. Taskbar → right-click → Edit Panel → set panel color to dark

### XFCE
1. Appearance → Style: install **Materia-Dark** or **Orchis-Purple**
2. Window Manager → Style: match or use Materia
3. Panel Preferences → Appearance → Background: custom color `#130020`

### Cinnamon
1. System Settings → Themes → install **Orchis-Purple-Dark** or similar
2. Panel → Panel Settings → set panel color

---

## Manual Notes

**Dopamine**: If Flatpak install fails (package not yet on Flathub), download the AppImage/deb/rpm directly from  
https://github.com/digimezzo/dopamine/releases

**Docker group**: After install you must log out and back in (or run `newgrp docker`) for the group change to take effect.

**nvm / Rust**: Both are added to your shell RC file. Run `source ~/.bashrc` (or `~/.zshrc`) or open a new terminal.

**Go (Debian)**: The binary is placed at `/usr/local/go/bin/go`. This path is added to `~/.profile` (takes effect on next login).

**Network module (polybar)**: Edit `~/.config/polybar/config.ini` and set `interface-type = wired` if you're on ethernet, or change the interface name to match `ip a` output.
