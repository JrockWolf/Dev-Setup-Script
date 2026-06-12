# Linux Setup

My personal script for setting up a fresh Linux install the way I like it. Run it once on a new machine and everything is configured and ready to go.

Supports **Debian-based**, **Fedora-based**, and **Arch-based** distros. Black & purple theme throughout.

## Usage

```bash
git clone https://github.com/JrockWolf/Dev-Setup-Script.git ~/linux-setup
cd ~/linux-setup
sudo bash install.sh
```

The script auto-detects your distro, asks which WM/DE you want, and asks about optional hardware drivers before touching anything.

---

## What Gets Installed

### Window Managers / Desktop Environments
Pick one or more at the prompt:

| WM / DE | Type | Bar | Display Manager |
|---|---|---|---|
| **i3** | X11 tiling | i3status | LightDM |
| **bspwm** | X11 tiling | Polybar | LightDM |
| **AwesomeWM** | X11 dynamic | wibox | LightDM |
| **Qtile** | X11 tiling | built-in | LightDM |
| **Fluxbox** | X11 stacking | built-in toolbar | LightDM |
| **dwm** | X11 minimal | built-in | LightDM |
| **Sway** | Wayland tiling | Waybar | SDDM |
| **Hyprland** | Wayland compositor | Waybar | SDDM |
| **KDE Plasma** | Full DE | Plasma panel | SDDM |
| **XFCE** | Full DE | XFCE panel | LightDM |
| **Cinnamon** | Full DE | Cinnamon panel | LightDM |

All WM configs are deployed automatically from the `configs/` directory to `~/.config/`.

### Optional Hardware
- Bluetooth (bluez + blueman)
- WiFi / NetworkManager
- Mouse / pointer drivers (libinput)
- GPU drivers — NVIDIA (proprietary), AMD, or Intel
- PipeWire (replaces PulseAudio)

### Browsers
- **Firefox** — native package, Flatpak fallback
- **Brave** — official repo, Flatpak fallback
- **Librewolf** — Flatpak, native repo fallback

### Editors
- **Neovim** — latest stable binary
- **Helix** — latest stable binary
- **VSCode** — official Microsoft repo

### Communication
- **Discord** — native deb on Debian, Flatpak on Fedora/Arch
- **Telegram** — Flatpak

### Media
- **OBS Studio** — native package
- **VLC** — native package (RPM Fusion auto-enabled on Fedora)
- **Spotify** — Flatpak
- **Dopamine** — Flatpak

### Productivity
- **Obsidian** — Flatpak

### Dev Tools
| Tool | How |
|---|---|
| Node.js LTS | nvm |
| Python 3 + pip + venv | native |
| Docker + Compose | get.docker.com |
| Rust + Cargo | rustup |
| Go | go.dev binary (Debian) / native (Fedora/Arch) |
| Java 21 LTS | SDKMAN (Temurin) |
| PostgreSQL client | native |
| tmux | native |
| jq + httpie + curl + wget | native |
| Beekeeper Studio | Flatpak |
| Opencode CLI | npm / opencode.ai |
| Git LFS | native + `git lfs install` |

### System
- **Flatpak + Flathub** (system-wide)
- **fastfetch** with custom wolf ASCII art

---

## Theme

Everything uses a black & purple palette:

| Role | Hex |
|---|---|
| Background | `#0a0a0a` |
| Panel / active bg | `#130020` |
| Accent / focused borders | `#9b30ff` |
| Highlights / icons | `#bf5fff` |
| Inactive borders | `#4b0082` |
| Text | `#e2d9f3` |

Config files are in `configs/` and deployed automatically by the installer.

---

## Notes

**Reboot/re-login required for:** Docker group membership, nvm, Cargo PATH, Go PATH (Debian).

**Hyprland on Debian:** Not officially supported — the script installs the Wayland tooling but Hyprland itself must be built from source. See the [Hyprland wiki](https://wiki.hyprland.org/Getting-Started/Installation/).

**Dopamine:** If the Flatpak isn't on Flathub yet, grab the release from [GitHub](https://github.com/digimezzo/dopamine/releases).

**Polybar network module:** Edit `~/.config/polybar/config.ini` and set the interface name to match `ip a` output.
