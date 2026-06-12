#!/usr/bin/env bash
# ================================================================
#  Linux Machine Setup Script
#  Auto-detects: Debian-based | Fedora-based | Arch-based
#  Desktop Envs: i3, KDE Plasma, XFCE, Cinnamon (pick one or more)
#  Optional:     Bluetooth, WiFi, mouse/input, GPU drivers, PipeWire
# ================================================================

set -euo pipefail

# ── Output helpers ───────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[ OK ]${NC}  $*"; }
warn()    { echo -e "${PURPLE}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERR ]${NC}  $*" >&2; exit 1; }
header()  { echo -e "\n${BOLD}${PURPLE}══ $* ══${NC}"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Detect the real user even when called via sudo ────────────────
# $HOME and $USER are root's when the script runs under sudo.
# SUDO_USER is preserved by sudo and gives us the actual caller.
if [ -n "${SUDO_USER:-}" ] && [ "${SUDO_USER}" != "root" ]; then
    REAL_USER="$SUDO_USER"
    REAL_HOME="$(getent passwd "$SUDO_USER" | cut -d: -f6)"
else
    REAL_USER="${USER:-root}"
    REAL_HOME="${HOME}"
fi

# ── Prevent apt interactive prompts (causes silent freezes) ───────
export DEBIAN_FRONTEND=noninteractive
export APT_LISTCHANGES_FRONTEND=none
export APT_LISTBUGS_FRONTEND=none

# ── Unix/Linux guard ─────────────────────────────────────────────
check_unix() {
    local kernel
    kernel="$(uname -s 2>/dev/null)" || error "Cannot determine OS — is 'uname' installed?"
    case "$kernel" in
        Linux)  ;;
        Darwin) error "macOS detected — this script targets Linux only." ;;
        *)      error "Unsupported OS: ${kernel}. Only Linux is supported." ;;
    esac
    [ "$(id -u)" -eq 0 ] || error "Run this script with sudo (e.g. sudo bash install.sh)."
    success "Running on Linux — all pre-flight checks passed"
}

# ── Detect or select distro base ─────────────────────────────────
detect_distro() {
    header "Detecting distro"

    if [ -f /etc/os-release ]; then
        # shellcheck source=/dev/null
        . /etc/os-release
        DISTRO_ID="${ID:-unknown}"
        DISTRO_ID_LIKE="${ID_LIKE:-}"
    else
        error "/etc/os-release not found — cannot detect distro."
    fi

    local combined="${DISTRO_ID} ${DISTRO_ID_LIKE}"

    if echo "$combined" | grep -qiE "debian|ubuntu|mint|pop|elementary|kali|parrot"; then
        BASE="debian"
    elif echo "$combined" | grep -qiE "fedora|rhel|centos|rocky|alma|nobara"; then
        BASE="fedora"
    elif echo "$combined" | grep -qiE "arch|manjaro|endeavouros|garuda|artix"; then
        BASE="arch"
    else
        echo -e "${PURPLE}Could not auto-detect distro base for '${DISTRO_ID}'.${NC}"
        echo "Please select your distro base:"
        select base_choice in "Debian-based" "Fedora-based" "Arch-based" "Quit"; do
            case $base_choice in
                "Debian-based") BASE="debian"; break ;;
                "Fedora-based") BASE="fedora"; break ;;
                "Arch-based")   BASE="arch";   break ;;
                "Quit")         exit 0 ;;
            esac
        done
    fi

    case $BASE in
        debian)
            PM_INSTALL="sudo apt-get install -y -q"
            ;;
        fedora)
            PM_INSTALL="sudo dnf install -y"
            ;;
        arch)
            PM_INSTALL="sudo pacman -S --noconfirm --needed"
            AUR_HELPER=""
            ;;
    esac

    success "Distro base: ${BASE} (${DISTRO_ID})"
}

# ── Desktop environment selection ────────────────────────────────
select_de() {
    header "Desktop Environment Setup"

    # ── Initialise ALL flags — missing ones caused 'unbound variable' abort ──
    INSTALL_I3=false
    INSTALL_BSPWM=false
    INSTALL_AWESOME=false
    INSTALL_QTILE=false
    INSTALL_FLUXBOX=false
    INSTALL_DWM=false
    INSTALL_SWAY=false
    INSTALL_HYPRLAND=false
    INSTALL_KDE=false
    INSTALL_XFCE=false
    INSTALL_CINNAMON=false

    echo "Which desktop environment / window manager would you like to install?"
    echo "  1)  i3        (X11 tiling WM — i3bar + i3status, purple themed)"
    echo "  2)  Sway      (Wayland tiling WM — waybar, purple themed)"
    echo "  3)  Hyprland  (Wayland compositor — waybar, purple themed)"
    echo "  4)  bspwm     (X11 tiling WM — polybar)"
    echo "  5)  AwesomeWM (X11 dynamic WM — wibox)"
    echo "  6)  Qtile     (X11 tiling WM — built-in bar)"
    echo "  7)  Fluxbox   (X11 stacking WM — built-in toolbar)"
    echo "  8)  dwm       (X11 minimal WM — compiled from source)"
    echo "  9)  KDE Plasma"
    echo "  10) XFCE"
    echo "  11) Cinnamon"
    echo "  12) Multiple  (choose below)"
    echo ""
    read -rp "Enter choice [1-12]: " de_choice

    case $de_choice in
        1)  INSTALL_I3=true ;;
        2)  INSTALL_SWAY=true ;;
        3)  INSTALL_HYPRLAND=true ;;
        4)  INSTALL_BSPWM=true ;;
        5)  INSTALL_AWESOME=true ;;
        6)  INSTALL_QTILE=true ;;
        7)  INSTALL_FLUXBOX=true ;;
        8)  INSTALL_DWM=true ;;
        9)  INSTALL_KDE=true ;;
        10) INSTALL_XFCE=true ;;
        11) INSTALL_CINNAMON=true ;;
        12)
            echo ""
            read -rp "  Install i3?       [y/N] " r; [[ "$r" =~ ^[Yy] ]] && INSTALL_I3=true
            read -rp "  Install Sway?     [y/N] " r; [[ "$r" =~ ^[Yy] ]] && INSTALL_SWAY=true
            read -rp "  Install Hyprland? [y/N] " r; [[ "$r" =~ ^[Yy] ]] && INSTALL_HYPRLAND=true
            read -rp "  Install bspwm?    [y/N] " r; [[ "$r" =~ ^[Yy] ]] && INSTALL_BSPWM=true
            read -rp "  Install Awesome?  [y/N] " r; [[ "$r" =~ ^[Yy] ]] && INSTALL_AWESOME=true
            read -rp "  Install Qtile?    [y/N] " r; [[ "$r" =~ ^[Yy] ]] && INSTALL_QTILE=true
            read -rp "  Install Fluxbox?  [y/N] " r; [[ "$r" =~ ^[Yy] ]] && INSTALL_FLUXBOX=true
            read -rp "  Install dwm?      [y/N] " r; [[ "$r" =~ ^[Yy] ]] && INSTALL_DWM=true
            read -rp "  Install KDE?      [y/N] " r; [[ "$r" =~ ^[Yy] ]] && INSTALL_KDE=true
            read -rp "  Install XFCE?     [y/N] " r; [[ "$r" =~ ^[Yy] ]] && INSTALL_XFCE=true
            read -rp "  Install Cinnamon? [y/N] " r; [[ "$r" =~ ^[Yy] ]] && INSTALL_CINNAMON=true
            ;;
        *)
            warn "Invalid choice; defaulting to i3."
            INSTALL_I3=true
            ;;
    esac

    echo ""
    if $INSTALL_I3;       then info "Will install: i3 (i3bar + i3status)"; fi
    if $INSTALL_SWAY;     then info "Will install: Sway (waybar)"; fi
    if $INSTALL_HYPRLAND; then info "Will install: Hyprland (waybar)"; fi
    if $INSTALL_BSPWM;    then info "Will install: bspwm (polybar)"; fi
    if $INSTALL_AWESOME;  then info "Will install: AwesomeWM"; fi
    if $INSTALL_QTILE;    then info "Will install: Qtile"; fi
    if $INSTALL_FLUXBOX;  then info "Will install: Fluxbox"; fi
    if $INSTALL_DWM;      then info "Will install: dwm (compiled from source)"; fi
    if $INSTALL_KDE;      then info "Will install: KDE Plasma"; fi
    if $INSTALL_XFCE;     then info "Will install: XFCE"; fi
    if $INSTALL_CINNAMON; then info "Will install: Cinnamon"; fi
    return 0
}

# ── Optional driver / service selection ─────────────────────────
select_optional_drivers() {
    header "Optional Hardware Drivers & Services"

    INSTALL_BLUETOOTH=false
    INSTALL_WIFI=false
    INSTALL_MOUSE_DRIVERS=false
    INSTALL_GPU_DRIVERS=false
    GPU_TYPE=""
    INSTALL_PIPEWIRE=false

    echo "After your DE/WM installs, the following hardware drivers can be set up."
    echo "Press Enter to skip any option (defaults to No)."
    echo ""

    read -rp "  Bluetooth support? (bluez + blueman)          [y/N] " r
    [[ "$r" =~ ^[Yy] ]] && INSTALL_BLUETOOTH=true

    read -rp "  WiFi / NetworkManager?                        [y/N] " r
    [[ "$r" =~ ^[Yy] ]] && INSTALL_WIFI=true

    read -rp "  Mouse / pointer input drivers? (libinput)     [y/N] " r
    [[ "$r" =~ ^[Yy] ]] && INSTALL_MOUSE_DRIVERS=true

    read -rp "  GPU drivers? (will ask for vendor next)       [y/N] " r
    if [[ "$r" =~ ^[Yy] ]]; then
        INSTALL_GPU_DRIVERS=true
        local detected=""
        detected=$(lspci 2>/dev/null | grep -iE "vga|3d|display" | head -1 || true)
        [ -n "$detected" ] && info "Auto-detected GPU: ${detected}"
        echo ""
        echo "  Select GPU driver type:"
        echo "    1) NVIDIA (proprietary)"
        echo "    2) AMD   (open-source, mesa)"
        echo "    3) Intel (open-source, mesa)"
        echo "    4) Skip  (no GPU driver changes)"
        read -rp "  Enter choice [1-4]: " gpu_choice
        case $gpu_choice in
            1) GPU_TYPE="nvidia" ;;
            2) GPU_TYPE="amd" ;;
            3) GPU_TYPE="intel" ;;
            *) INSTALL_GPU_DRIVERS=false; warn "Skipping GPU drivers." ;;
        esac
    fi

    read -rp "  Replace PulseAudio with PipeWire?             [y/N] " r
    [[ "$r" =~ ^[Yy] ]] && INSTALL_PIPEWIRE=true

    echo ""
    if $INSTALL_BLUETOOTH;     then info "Will install: Bluetooth"; fi
    if $INSTALL_WIFI;          then info "Will install: WiFi / NetworkManager"; fi
    if $INSTALL_MOUSE_DRIVERS; then info "Will install: Mouse / input drivers (libinput)"; fi
    if $INSTALL_GPU_DRIVERS;   then info "Will install: ${GPU_TYPE^^} GPU drivers"; fi
    if $INSTALL_PIPEWIRE;      then info "Will install: PipeWire (replaces PulseAudio)"; fi
}

# ── Bluetooth ────────────────────────────────────────────────────
install_bluetooth() {
    header "Installing Bluetooth (bluez + blueman)"
    case $BASE in
        debian) $PM_INSTALL bluez bluez-tools blueman ;;
        fedora) $PM_INSTALL bluez bluez-tools blueman ;;
        arch)   $PM_INSTALL bluez bluez-utils blueman ;;
    esac
    sudo systemctl enable --now bluetooth
    success "Bluetooth installed and enabled"
}

# ── WiFi / NetworkManager ────────────────────────────────────────
install_wifi() {
    header "Installing WiFi / NetworkManager"
    case $BASE in
        debian)
            $PM_INSTALL network-manager network-manager-gnome \
                wireless-tools wpasupplicant
            ;;
        fedora)
            $PM_INSTALL NetworkManager NetworkManager-wifi \
                wireless-tools wpa_supplicant NetworkManager-applet
            ;;
        arch)
            $PM_INSTALL networkmanager network-manager-applet \
                wireless_tools wpa_supplicant
            ;;
    esac
    sudo systemctl enable --now NetworkManager
    success "NetworkManager installed and enabled"
    info "Use 'nmtui' (terminal) or nm-applet (system tray) to manage connections."
}

# ── Mouse / pointer input drivers ───────────────────────────────
install_mouse_drivers() {
    header "Installing mouse / pointer input drivers (libinput)"
    case $BASE in
        debian) $PM_INSTALL xserver-xorg-input-libinput xinput ;;
        fedora) $PM_INSTALL xorg-x11-drv-libinput xinput ;;
        arch)   $PM_INSTALL xf86-input-libinput libinput xinput ;;
    esac
    success "libinput / mouse drivers installed"
}

# ── GPU drivers ──────────────────────────────────────────────────
install_gpu_drivers() {
    header "Installing ${GPU_TYPE^^} GPU drivers"
    case "$GPU_TYPE" in
        nvidia)
            case $BASE in
                debian)
                    # Enable non-free repos (required for NVIDIA proprietary driver)
                    grep -qE '\bnon-free\b' /etc/apt/sources.list \
                        || sudo sed -i 's/^\(deb[[:space:]][^#]*main\)/\1 contrib non-free non-free-firmware/' \
                            /etc/apt/sources.list
                    sudo apt-get update -qq
                    $PM_INSTALL nvidia-driver firmware-misc-nonfree nvidia-settings
                    ;;
                fedora)
                    $PM_INSTALL akmod-nvidia xorg-x11-drv-nvidia nvidia-settings
                    ;;
                arch)
                    $PM_INSTALL nvidia nvidia-utils nvidia-settings
                    ;;
            esac
            success "NVIDIA drivers installed — reboot required to load the kernel module"
            warn "Wayland users: add 'nvidia_drm.modeset=1' as a kernel parameter."
            ;;
        amd)
            case $BASE in
                debian)
                    # Enable non-free-firmware (required for AMD firmware blobs)
                    grep -qE '\bnon-free\b' /etc/apt/sources.list \
                        || sudo sed -i 's/^\(deb[[:space:]][^#]*main\)/\1 contrib non-free non-free-firmware/' \
                            /etc/apt/sources.list
                    sudo apt-get update -qq
                    $PM_INSTALL xserver-xorg-video-amdgpu \
                        firmware-amd-graphics mesa-vulkan-drivers
                    ;;
                fedora)
                    $PM_INSTALL xorg-x11-drv-amdgpu \
                        mesa-vulkan-drivers mesa-dri-drivers
                    ;;
                arch)
                    $PM_INSTALL xf86-video-amdgpu mesa vulkan-radeon \
                        libva-mesa-driver
                    ;;
            esac
            success "AMD GPU drivers installed"
            ;;
        intel)
            case $BASE in
                debian)
                    $PM_INSTALL xserver-xorg-video-intel \
                        intel-media-va-driver mesa-vulkan-drivers
                    ;;
                fedora)
                    $PM_INSTALL xorg-x11-drv-intel \
                        intel-media-driver mesa-vulkan-drivers
                    ;;
                arch)
                    $PM_INSTALL xf86-video-intel mesa vulkan-intel \
                        intel-media-driver
                    ;;
            esac
            success "Intel GPU drivers installed"
            ;;
    esac
}

# ── PipeWire (replaces PulseAudio) ───────────────────────────────
install_pipewire() {
    header "Installing PipeWire (replacing PulseAudio)"
    case $BASE in
        debian)
            $PM_INSTALL pipewire pipewire-audio-client-libraries \
                pipewire-pulse wireplumber gstreamer1.0-pipewire \
                libspa-0.2-bluetooth
            sudo -u "$REAL_USER" systemctl --user --now disable \
                pulseaudio.service pulseaudio.socket 2>/dev/null || true
            sudo -u "$REAL_USER" systemctl --user --now enable \
                pipewire pipewire-pulse wireplumber 2>/dev/null || true
            ;;
        fedora)
            $PM_INSTALL pipewire pipewire-pulseaudio wireplumber \
                pipewire-alsa pipewire-jack-audio-connection-kit
            sudo -u "$REAL_USER" systemctl --user --now enable \
                pipewire pipewire-pulse wireplumber 2>/dev/null || true
            ;;
        arch)
            $PM_INSTALL pipewire pipewire-pulse wireplumber \
                pipewire-alsa pipewire-jack
            sudo -u "$REAL_USER" systemctl --user --now enable \
                pipewire pipewire-pulse wireplumber 2>/dev/null || true
            ;;
    esac
    success "PipeWire installed"
    warn "Log out and back in (or reboot) for PipeWire to fully replace PulseAudio."
}

# ── System update ────────────────────────────────────────────────
update_system() {
    header "Updating system packages"
    info "Running package manager update (this may take a moment)..."
    case $BASE in
        debian)
            sudo apt-get update -qq
            sudo apt-get upgrade -y -q
            ;;
        fedora)
            sudo dnf upgrade -y
            ;;
        arch)
            sudo pacman -Syu --noconfirm
            ;;
    esac
    success "System up to date"
}

# ── Base dependencies ────────────────────────────────────────────
install_base_deps() {
    header "Installing base dependencies"

    case $BASE in
        debian)
            $PM_INSTALL \
                curl wget git gnupg2 apt-transport-https ca-certificates \
                xorg xinit xdg-utils \
                flatpak pulseaudio pulseaudio-utils
            ;;
        fedora)
            $PM_INSTALL \
                curl wget git gnupg2 dnf-plugins-core \
                xorg-x11-server-Xorg xinit xdg-utils \
                flatpak pulseaudio pulseaudio-utils
            ;;
        arch)
            $PM_INSTALL \
                curl wget git gnupg xorg-server xorg-xinit xdg-utils \
                flatpak pulseaudio pulseaudio-alsa
            ;;
    esac

    success "Base dependencies installed"
}

# ── AUR helper (Arch only) ───────────────────────────────────────
install_aur_helper() {
    [ "$BASE" != "arch" ] && return

    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
        return
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
        return
    fi

    header "Installing paru (AUR helper)"
    $PM_INSTALL base-devel
    local build_dir
    build_dir="$(mktemp -d /tmp/paru-build.XXXXXX)"
    git clone --depth=1 https://aur.archlinux.org/paru.git "$build_dir"
    chown -R "$REAL_USER:$REAL_USER" "$build_dir"
    sudo -u "$REAL_USER" bash -c "cd '$build_dir' && makepkg -si --noconfirm"
    rm -rf "$build_dir"
    AUR_HELPER="paru"
    success "paru installed"
}

aur_install() {
    [ "$BASE" = "arch" ] && sudo -u "$REAL_USER" ${AUR_HELPER:-paru} -S --noconfirm --needed "$@"
}

# ── Flatpak setup ────────────────────────────────────────────────
setup_flatpak() {
    header "Setting up Flatpak + Flathub"
    # --system makes Flathub available to ALL users, not just the installer (root)
    flatpak remote-add --if-not-exists --system flathub \
        https://dl.flathub.org/repo/flathub.flatpakrepo
    success "Flathub configured (system-wide)"
}

# ── i3 (minimal: wm + bar + launcher + compositor + wallpaper) ───
install_i3() {
    header "Installing i3"

    case $BASE in
        debian)
            $PM_INSTALL \
                i3 i3status rofi picom feh nitrogen alacritty dunst \
                lightdm lightdm-gtk-greeter \
                fonts-font-awesome fonts-noto-color-emoji \
                pavucontrol lxappearance maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
        fedora)
            $PM_INSTALL \
                i3 i3status rofi picom feh nitrogen alacritty dunst \
                lightdm lightdm-gtk-greeter \
                fontawesome-fonts google-noto-emoji-color-fonts \
                pavucontrol lxappearance maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
        arch)
            $PM_INSTALL \
                i3-wm i3status rofi picom feh nitrogen alacritty dunst \
                lightdm lightdm-gtk-greeter \
                ttf-font-awesome noto-fonts-emoji \
                pavucontrol lxappearance maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
    esac

    # Deploy configs to the real user's home (not /root)
    info "Deploying configs to ${REAL_HOME}..."
    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/i3"
    cp "${SCRIPT_DIR}/configs/i3/config" "$REAL_HOME/.config/i3/config"
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/i3/config"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/picom"
    cp "${SCRIPT_DIR}/configs/picom.conf" "$REAL_HOME/.config/picom/picom.conf"
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/picom/picom.conf"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/rofi"
    cp "${SCRIPT_DIR}/configs/rofi/launcher.rasi" "$REAL_HOME/.config/rofi/launcher.rasi"
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/rofi/launcher.rasi"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/alacritty"
    cp "${SCRIPT_DIR}/configs/alacritty/alacritty.toml" "$REAL_HOME/.config/alacritty/alacritty.toml"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/alacritty"

    # Set Alacritty as the default x-terminal-emulator
    if command -v update-alternatives &>/dev/null && command -v alacritty &>/dev/null; then
        sudo update-alternatives --install /usr/bin/x-terminal-emulator x-terminal-emulator \
            "$(command -v alacritty)" 50
        sudo update-alternatives --set x-terminal-emulator "$(command -v alacritty)"
    fi

    success "i3 + Alacritty installed and configured for user: ${REAL_USER}"
    info "i3bar uses i3status — theme colors defined in ~/.config/i3/config"
}

# ── Sway (Wayland tiling WM + waybar) ─────────────────────────────
install_sway() {
    header "Installing Sway (Wayland)"

    case $BASE in
        debian)
            $PM_INSTALL \
                sway waybar rofi alacritty \
                swaybg swaylock swayidle \
                grim slurp mako-notifier \
                sddm xwayland \
                fonts-font-awesome fonts-noto-color-emoji \
                pavucontrol lxappearance brightnessctl
            sudo systemctl enable sddm
            ;;
        fedora)
            $PM_INSTALL \
                sway waybar rofi alacritty \
                swaybg swaylock swayidle \
                grim slurp mako \
                sddm xorg-x11-server-Xwayland \
                fontawesome-fonts google-noto-emoji-color-fonts \
                pavucontrol lxappearance brightnessctl
            sudo systemctl enable sddm
            ;;
        arch)
            $PM_INSTALL \
                sway waybar rofi alacritty \
                swaybg swaylock swayidle \
                grim slurp mako \
                sddm xorg-xwayland \
                ttf-font-awesome noto-fonts-emoji \
                pavucontrol lxappearance brightnessctl
            sudo systemctl enable sddm
            ;;
    esac

    info "Deploying Sway + Waybar configs to ${REAL_HOME}..."

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/sway"
    cp "${SCRIPT_DIR}/configs/sway/config" "$REAL_HOME/.config/sway/config"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/sway"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/waybar"
    cp "${SCRIPT_DIR}/configs/waybar/config.jsonc" "$REAL_HOME/.config/waybar/config.jsonc"
    cp "${SCRIPT_DIR}/configs/waybar/style.css"    "$REAL_HOME/.config/waybar/style.css"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/waybar"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/rofi"
    cp "${SCRIPT_DIR}/configs/rofi/launcher.rasi" "$REAL_HOME/.config/rofi/launcher.rasi"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/rofi"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/alacritty"
    cp "${SCRIPT_DIR}/configs/alacritty/alacritty.toml" "$REAL_HOME/.config/alacritty/alacritty.toml"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/alacritty"

    success "Sway + Waybar installed and configured for user: ${REAL_USER}"
    warn "Waybar uses Font Awesome icons — ensure a patched or FA font is active."
    info "Drop a wallpaper at ~/.config/sway/wallpaper.jpg to enable it."
}

# ── bspwm (X11 tiling WM + polybar) ─────────────────────────────
install_bspwm() {
    header "Installing bspwm"

    case $BASE in
        debian)
            $PM_INSTALL \
                bspwm sxhkd picom rofi feh nitrogen alacritty \
                polybar dunst \
                lightdm lightdm-gtk-greeter \
                fonts-font-awesome fonts-noto-color-emoji \
                pavucontrol lxappearance maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
        fedora)
            $PM_INSTALL \
                bspwm sxhkd picom rofi feh nitrogen alacritty \
                polybar dunst \
                lightdm lightdm-gtk-greeter \
                fontawesome-fonts google-noto-emoji-color-fonts \
                pavucontrol lxappearance maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
        arch)
            $PM_INSTALL \
                bspwm sxhkd picom rofi feh nitrogen alacritty \
                polybar dunst \
                lightdm lightdm-gtk-greeter \
                ttf-font-awesome noto-fonts-emoji \
                pavucontrol lxappearance maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
    esac

    info "Deploying bspwm configs to ${REAL_HOME}..."

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/bspwm"
    cp "${SCRIPT_DIR}/configs/bspwm/bspwmrc" "$REAL_HOME/.config/bspwm/bspwmrc"
    chmod +x "$REAL_HOME/.config/bspwm/bspwmrc"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/bspwm"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/sxhkd"
    cp "${SCRIPT_DIR}/configs/sxhkd/sxhkdrc" "$REAL_HOME/.config/sxhkd/sxhkdrc"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/sxhkd"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/picom"
    cp "${SCRIPT_DIR}/configs/picom.conf" "$REAL_HOME/.config/picom/picom.conf"
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/picom/picom.conf"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/polybar"
    cp "${SCRIPT_DIR}/configs/polybar/config.ini" "$REAL_HOME/.config/polybar/config.ini"
    cp "${SCRIPT_DIR}/configs/polybar/launch.sh"  "$REAL_HOME/.config/polybar/launch.sh"
    chmod +x "$REAL_HOME/.config/polybar/launch.sh"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/polybar"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/rofi"
    cp "${SCRIPT_DIR}/configs/rofi/launcher.rasi" "$REAL_HOME/.config/rofi/launcher.rasi"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/rofi"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/alacritty"
    cp "${SCRIPT_DIR}/configs/alacritty/alacritty.toml" "$REAL_HOME/.config/alacritty/alacritty.toml"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/alacritty"

    success "bspwm + polybar installed and configured for user: ${REAL_USER}"
    info "Drop a wallpaper at ~/.config/bspwm/wallpaper.jpg to set the background."
}

# ── AwesomeWM (X11 dynamic WM + wibox) ─────────────────────────
install_awesome() {
    header "Installing AwesomeWM"

    case $BASE in
        debian)
            $PM_INSTALL \
                awesome picom rofi feh nitrogen alacritty dunst \
                lightdm lightdm-gtk-greeter \
                fonts-font-awesome fonts-noto-color-emoji \
                pavucontrol lxappearance maim xdotool brightnessctl lua5.4
            sudo systemctl enable lightdm
            ;;
        fedora)
            $PM_INSTALL \
                awesome picom rofi feh nitrogen alacritty dunst \
                lightdm lightdm-gtk-greeter \
                fontawesome-fonts google-noto-emoji-color-fonts \
                pavucontrol lxappearance maim xdotool brightnessctl lua
            sudo systemctl enable lightdm
            ;;
        arch)
            $PM_INSTALL \
                awesome picom rofi feh nitrogen alacritty dunst \
                lightdm lightdm-gtk-greeter \
                ttf-font-awesome noto-fonts-emoji \
                pavucontrol lxappearance maim xdotool brightnessctl lua
            sudo systemctl enable lightdm
            ;;
    esac

    info "Deploying AwesomeWM configs to ${REAL_HOME}..."

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/awesome"
    cp "${SCRIPT_DIR}/configs/awesome/rc.lua" "$REAL_HOME/.config/awesome/rc.lua"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/awesome"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/picom"
    cp "${SCRIPT_DIR}/configs/picom.conf" "$REAL_HOME/.config/picom/picom.conf"
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/picom/picom.conf"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/rofi"
    cp "${SCRIPT_DIR}/configs/rofi/launcher.rasi" "$REAL_HOME/.config/rofi/launcher.rasi"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/rofi"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/alacritty"
    cp "${SCRIPT_DIR}/configs/alacritty/alacritty.toml" "$REAL_HOME/.config/alacritty/alacritty.toml"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/alacritty"

    success "AwesomeWM installed and configured for user: ${REAL_USER}"
    info "Drop a wallpaper at ~/.config/awesome/wallpaper.jpg to set the background."
}

# ── Qtile (X11 tiling WM + built-in bar) ───────────────────────
install_qtile() {
    header "Installing Qtile"

    case $BASE in
        debian)
            # Try package manager first; fall back to pip
            if $PM_INSTALL qtile 2>/dev/null; then
                info "Qtile installed from apt."
            else
                $PM_INSTALL python3-pip python3-xcb python3-cairocffi \
                    libxcb-render0-dev libffi-dev libpangocairo-1.0-0 \
                    python3-dbus python3-psutil python3-gobject
                sudo pip3 install --break-system-packages qtile
            fi
            $PM_INSTALL \
                picom rofi feh nitrogen alacritty dunst \
                lightdm lightdm-gtk-greeter \
                fonts-font-awesome fonts-noto-color-emoji \
                pavucontrol lxappearance maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
        fedora)
            if $PM_INSTALL qtile 2>/dev/null; then
                info "Qtile installed from dnf."
            else
                $PM_INSTALL python3-pip python3-xcb-proto python3-cairocffi \
                    libffi-devel python3-dbus python3-psutil python3-gobject3
                sudo pip3 install --break-system-packages qtile
            fi
            $PM_INSTALL \
                picom rofi feh nitrogen alacritty dunst \
                lightdm lightdm-gtk-greeter \
                fontawesome-fonts google-noto-emoji-color-fonts \
                pavucontrol lxappearance maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
        arch)
            $PM_INSTALL \
                qtile picom rofi feh nitrogen alacritty dunst \
                lightdm lightdm-gtk-greeter \
                ttf-font-awesome noto-fonts-emoji \
                pavucontrol lxappearance maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
    esac

    info "Deploying Qtile configs to ${REAL_HOME}..."

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/qtile"
    cp "${SCRIPT_DIR}/configs/qtile/config.py" "$REAL_HOME/.config/qtile/config.py"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/qtile"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/picom"
    cp "${SCRIPT_DIR}/configs/picom.conf" "$REAL_HOME/.config/picom/picom.conf"
    chown "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/picom/picom.conf"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/rofi"
    cp "${SCRIPT_DIR}/configs/rofi/launcher.rasi" "$REAL_HOME/.config/rofi/launcher.rasi"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/rofi"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/alacritty"
    cp "${SCRIPT_DIR}/configs/alacritty/alacritty.toml" "$REAL_HOME/.config/alacritty/alacritty.toml"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/alacritty"

    success "Qtile installed and configured for user: ${REAL_USER}"
    info "Drop a wallpaper at ~/.config/qtile/wallpaper.jpg to set the background."
}

# ── Hyprland compat check ───────────────────────────────────────
check_hyprland_compat() {
    case $BASE in
        arch)   return 0 ;;
        fedora) return 0 ;;
        debian)
            warn "Hyprland is NOT officially supported on Debian-based distros."
            warn "It may be unstable or require building from source."
            read -rp "  Proceed with Hyprland on Debian anyway? [y/N] " r
            [[ "$r" =~ ^[Yy] ]] && return 0 || return 1
            ;;
    esac
}

# ── Hyprland (Wayland compositor + waybar) ───────────────────────
install_hyprland() {
    header "Installing Hyprland (Wayland)"

    if ! check_hyprland_compat; then
        warn "Skipping Hyprland — not supported on this distro."
        return
    fi

    case $BASE in
        arch)
            $PM_INSTALL \
                hyprland waybar rofi alacritty \
                hyprpaper hypridle hyprlock \
                grim slurp mako jq \
                sddm xorg-xwayland \
                ttf-font-awesome noto-fonts-emoji \
                pavucontrol lxappearance brightnessctl
            sudo systemctl enable sddm
            ;;
        fedora)
            sudo dnf copr enable solopasha/hyprland -y
            $PM_INSTALL \
                hyprland waybar rofi alacritty \
                hyprpaper hypridle hyprlock \
                grim slurp mako jq \
                sddm xorg-x11-server-Xwayland \
                fontawesome-fonts google-noto-emoji-color-fonts \
                pavucontrol lxappearance brightnessctl
            sudo systemctl enable sddm
            ;;
        debian)
            warn "Installing minimal Wayland toolchain for Hyprland on Debian."
            $PM_INSTALL \
                waybar rofi alacritty grim slurp mako-notifier jq \
                fonts-font-awesome fonts-noto-color-emoji \
                pavucontrol lxappearance brightnessctl
            warn "Hyprland itself must be built from source on Debian."
            warn "See: https://wiki.hyprland.org/Getting-Started/Installation/"
            ;;
    esac

    info "Deploying Hyprland + Waybar configs to ${REAL_HOME}..."

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/hypr"
    cp "${SCRIPT_DIR}/configs/hyprland/hyprland.conf" "$REAL_HOME/.config/hypr/hyprland.conf"
    cp "${SCRIPT_DIR}/configs/hyprland/hyprpaper.conf" "$REAL_HOME/.config/hypr/hyprpaper.conf"
    cp "${SCRIPT_DIR}/configs/hyprland/hypridle.conf"  "$REAL_HOME/.config/hypr/hypridle.conf"
    cp "${SCRIPT_DIR}/configs/hyprland/hyprlock.conf"  "$REAL_HOME/.config/hypr/hyprlock.conf"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/hypr"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/waybar"
    cp "${SCRIPT_DIR}/configs/waybar/config.jsonc" "$REAL_HOME/.config/waybar/config.jsonc"
    cp "${SCRIPT_DIR}/configs/waybar/style.css"    "$REAL_HOME/.config/waybar/style.css"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/waybar"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/rofi"
    cp "${SCRIPT_DIR}/configs/rofi/launcher.rasi" "$REAL_HOME/.config/rofi/launcher.rasi"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/rofi"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/alacritty"
    cp "${SCRIPT_DIR}/configs/alacritty/alacritty.toml" "$REAL_HOME/.config/alacritty/alacritty.toml"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/alacritty"

    success "Hyprland + Waybar installed and configured for user: ${REAL_USER}"
    info "Drop a wallpaper at ~/.config/hypr/wallpaper.jpg — hyprpaper will use it."
    warn "Hyprland is launched from the TTY or via a Wayland-capable display manager."
}

# ── Fluxbox (X11 stacking WM + built-in toolbar) ─────────────────
install_fluxbox() {
    header "Installing Fluxbox"

    case $BASE in
        debian)
            $PM_INSTALL \
                fluxbox rofi feh nitrogen alacritty dunst \
                lightdm lightdm-gtk-greeter \
                fonts-font-awesome fonts-noto-color-emoji \
                pavucontrol lxappearance maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
        fedora)
            $PM_INSTALL \
                fluxbox rofi feh nitrogen alacritty dunst \
                lightdm lightdm-gtk-greeter \
                fontawesome-fonts google-noto-emoji-color-fonts \
                pavucontrol lxappearance maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
        arch)
            $PM_INSTALL \
                fluxbox rofi feh nitrogen alacritty dunst \
                lightdm lightdm-gtk-greeter \
                ttf-font-awesome noto-fonts-emoji \
                pavucontrol lxappearance maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
    esac

    info "Deploying Fluxbox configs to ${REAL_HOME}..."

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.fluxbox/styles"
    cp "${SCRIPT_DIR}/configs/fluxbox/init"          "$REAL_HOME/.fluxbox/init"
    cp "${SCRIPT_DIR}/configs/fluxbox/keys"          "$REAL_HOME/.fluxbox/keys"
    cp "${SCRIPT_DIR}/configs/fluxbox/menu"          "$REAL_HOME/.fluxbox/menu"
    cp "${SCRIPT_DIR}/configs/fluxbox/styles/Purple" "$REAL_HOME/.fluxbox/styles/Purple"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.fluxbox"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/rofi"
    cp "${SCRIPT_DIR}/configs/rofi/launcher.rasi" "$REAL_HOME/.config/rofi/launcher.rasi"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/rofi"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/alacritty"
    cp "${SCRIPT_DIR}/configs/alacritty/alacritty.toml" "$REAL_HOME/.config/alacritty/alacritty.toml"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/alacritty"

    success "Fluxbox installed and configured for user: ${REAL_USER}"
    warn "Apply the Purple style via right-click → Fluxbox menu → Styles if not loaded."
}

# ── dwm (X11 minimal WM compiled from source) ───────────────────
install_dwm() {
    header "Installing dwm (compiled from source)"

    # Install build deps
    case $BASE in
        debian)
            $PM_INSTALL build-essential libx11-dev libxft-dev libxinerama-dev \
                dmenu rofi alacritty dunst \
                lightdm lightdm-gtk-greeter \
                fonts-font-awesome pavucontrol maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
        fedora)
            $PM_INSTALL gcc make libX11-devel libXft-devel libXinerama-devel \
                dmenu rofi alacritty dunst \
                lightdm lightdm-gtk-greeter \
                fontawesome-fonts pavucontrol maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
        arch)
            $PM_INSTALL base-devel libx11 libxft libxinerama \
                dmenu rofi alacritty dunst \
                lightdm lightdm-gtk-greeter \
                ttf-font-awesome pavucontrol maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
    esac

    info "Building dwm from source..."
    local build_dir
    build_dir="$(mktemp -d /tmp/dwm-build.XXXXXX)"
    git clone --depth=1 https://git.suckless.org/dwm "$build_dir"
    cp "${SCRIPT_DIR}/configs/dwm/config.h" "$build_dir/config.h"
    make -C "$build_dir"
    make -C "$build_dir" install
    rm -rf "$build_dir"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/rofi"
    cp "${SCRIPT_DIR}/configs/rofi/launcher.rasi" "$REAL_HOME/.config/rofi/launcher.rasi"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/rofi"

    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/alacritty"
    cp "${SCRIPT_DIR}/configs/alacritty/alacritty.toml" "$REAL_HOME/.config/alacritty/alacritty.toml"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/alacritty"

    success "dwm compiled and installed from source for user: ${REAL_USER}"
    info "Add 'exec dwm' to ~/.xinitrc to start it from a TTY."
}

# ── KDE Plasma (minimal desktop + sddm) ──────────────────────────
install_kde() {
    header "Installing KDE Plasma (minimal)"

    case $BASE in
        debian)
            $PM_INSTALL kde-plasma-desktop sddm
            sudo systemctl enable sddm
            ;;
        fedora)
            sudo dnf group install -y "KDE Plasma Workspaces" --skip-broken
            $PM_INSTALL sddm
            sudo systemctl enable sddm
            ;;
        arch)
            $PM_INSTALL plasma-desktop sddm
            sudo systemctl enable sddm
            ;;
    esac

    success "KDE Plasma installed"
    warn "Apply the black/purple theme via System Settings > Appearance after first login."
    warn "Recommended: Breeze Dark base + Kvantum (KvArcDark or Nightfall) + custom accent color #9b30ff"
}

# ── XFCE (minimal core + lightdm) ────────────────────────────────
install_xfce() {
    header "Installing XFCE (minimal)"

    case $BASE in
        debian)
            $PM_INSTALL xfce4 xfce4-terminal lightdm lightdm-gtk-greeter
            sudo systemctl enable lightdm
            ;;
        fedora)
            sudo dnf group install -y "Xfce Desktop" --skip-broken
            $PM_INSTALL lightdm lightdm-gtk-greeter
            sudo systemctl enable lightdm
            ;;
        arch)
            $PM_INSTALL xfce4 xfce4-terminal lightdm lightdm-gtk-greeter
            sudo systemctl enable lightdm
            ;;
    esac

    success "XFCE installed"
    warn "Apply a dark purple GTK theme (Materia-Dark or Orchis-Purple) via XFCE Appearance settings."
}

# ── Cinnamon (minimal core + lightdm) ────────────────────────────
install_cinnamon() {
    header "Installing Cinnamon (minimal)"

    case $BASE in
        debian)
            $PM_INSTALL cinnamon-desktop-environment lightdm lightdm-gtk-greeter
            sudo systemctl enable lightdm
            ;;
        fedora)
            sudo dnf group install -y "Cinnamon Desktop" --skip-broken
            $PM_INSTALL lightdm lightdm-gtk-greeter
            sudo systemctl enable lightdm
            ;;
        arch)
            $PM_INSTALL cinnamon lightdm lightdm-gtk-greeter
            sudo systemctl enable lightdm
            ;;
    esac

    success "Cinnamon installed"
    warn "Apply a dark purple theme via Themes in Cinnamon System Settings."
}

# ── Browsers ─────────────────────────────────────────────────────
install_browsers() {
    header "Installing browsers"

    # ── Firefox ──────────────────────────────────────────────────
    info "Installing Firefox..."
    FIREFOX_OK=false
    case $BASE in
        debian)
            if $PM_INSTALL firefox 2>/dev/null; then
                FIREFOX_OK=true
            elif $PM_INSTALL firefox-esr 2>/dev/null; then
                FIREFOX_OK=true
            fi
            ;;
        fedora)
            if $PM_INSTALL firefox 2>/dev/null; then FIREFOX_OK=true; fi
            ;;
        arch)
            if $PM_INSTALL firefox 2>/dev/null; then FIREFOX_OK=true; fi
            ;;
    esac
    if ! $FIREFOX_OK; then
        warn "Native Firefox unavailable — installing via Flatpak"
        flatpak install -y flathub org.mozilla.firefox
    fi
    success "Firefox installed"

    # ── Brave ─────────────────────────────────────────────────────
    # Try official repo; fall back to Flatpak
    BRAVE_OK=false
    case $BASE in
        debian)
            if sudo install -m 0755 -d /etc/apt/keyrings \
                && curl -fsSLo /etc/apt/keyrings/brave-browser-archive-keyring.gpg \
                    https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
                && echo "deb [signed-by=/etc/apt/keyrings/brave-browser-archive-keyring.gpg arch=amd64] \
https://brave-browser-apt-release.s3.brave.com/ stable main" \
                    | sudo tee /etc/apt/sources.list.d/brave-browser.list > /dev/null \
                && sudo apt update \
                && $PM_INSTALL brave-browser 2>/dev/null; then
                BRAVE_OK=true
            fi
            ;;
        fedora)
            if sudo dnf config-manager \
                    --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo \
                && sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc \
                && $PM_INSTALL brave-browser 2>/dev/null; then
                BRAVE_OK=true
            fi
            ;;
        arch)
            if aur_install brave-bin 2>/dev/null; then BRAVE_OK=true; fi
            ;;
    esac
    if ! $BRAVE_OK; then
        warn "Native Brave install failed — installing via Flatpak"
        flatpak install -y flathub com.brave.Browser
    fi
    success "Brave installed"

    # ── Librewolf — Flatpak primary, native repo fallback ─────────
    info "Installing Librewolf..."
    LIBREWOLF_OK=false
    if flatpak install -y flathub io.gitlab.librewolf-community.LibreWolf 2>/dev/null; then
        LIBREWOLF_OK=true
    else
        warn "Flatpak Librewolf unavailable — trying native repo"
        case $BASE in
            debian)
                if curl -fsSLo /etc/apt/keyrings/librewolf.gpg \
                        https://deb.librewolf.net/keyring.gpg \
                    && echo "deb [signed-by=/etc/apt/keyrings/librewolf.gpg arch=amd64] \
https://deb.librewolf.net $(. /etc/os-release && echo $VERSION_CODENAME) main" \
                        | sudo tee /etc/apt/sources.list.d/librewolf.list > /dev/null \
                    && sudo apt update \
                    && $PM_INSTALL librewolf 2>/dev/null; then
                    LIBREWOLF_OK=true
                fi
                ;;
            fedora)
                if sudo rpm --import https://rpm.librewolf.net/pubkey.gpg \
                    && sudo dnf config-manager \
                        --add-repo https://rpm.librewolf.net/librewolf-repo.repo \
                    && $PM_INSTALL librewolf 2>/dev/null; then
                    LIBREWOLF_OK=true
                fi
                ;;
            arch)
                if aur_install librewolf-bin 2>/dev/null; then LIBREWOLF_OK=true; fi
                ;;
        esac
    fi
    if $LIBREWOLF_OK; then
        success "Librewolf installed"
    else
        warn "Librewolf could not be installed — download manually from https://librewolf.net"
    fi
}

# ── Terminal editors ──────────────────────────────────────────────
install_editors() {
    header "Installing terminal editors (Neovim + Helix)"

    # Neovim
    NV_INSTALLED=false
    case $BASE in
        debian)
            # Use official release binary for latest stable
            NV_URL=$(curl -s --max-time 15 https://api.github.com/repos/neovim/neovim/releases/latest \
                | grep -oP '"browser_download_url": "\K[^"]+nvim-linux-x86_64\.tar\.gz')
            if [ -z "$NV_URL" ]; then
                warn "Could not resolve Neovim download URL — skipping Neovim."
            else
                curl -Lo /tmp/nvim.tar.gz "$NV_URL"
                sudo tar -xzf /tmp/nvim.tar.gz -C /opt
                sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
                rm -f /tmp/nvim.tar.gz
                NV_INSTALLED=true
            fi
            ;;
        fedora) $PM_INSTALL neovim; NV_INSTALLED=true ;;
        arch)   $PM_INSTALL neovim; NV_INSTALLED=true ;;
    esac
    if $NV_INSTALLED; then success "Neovim installed"; fi

    # Helix
    HX_INSTALLED=false
    case $BASE in
        debian)
            HX_URL=$(curl -s --max-time 15 https://api.github.com/repos/helix-editor/helix/releases/latest \
                | grep -oP '"browser_download_url": "\K[^"]+helix-[^"]+linux-x86_64\.tar\.xz')
            if [ -z "$HX_URL" ]; then
                warn "Could not resolve Helix download URL — skipping Helix."
            else
                curl -Lo /tmp/helix.tar.xz "$HX_URL"
                sudo mkdir -p /opt/helix
                sudo tar -xJf /tmp/helix.tar.xz -C /opt/helix --strip-components=1
                sudo ln -sf /opt/helix/hx /usr/local/bin/hx
                rm -f /tmp/helix.tar.xz
                HX_INSTALLED=true
            fi
            ;;
        fedora)
            # Helix is in Fedora 38+ repos
            $PM_INSTALL helix || flatpak install -y flathub com.helix_editor.Helix
            HX_INSTALLED=true
            ;;
        arch) $PM_INSTALL helix; HX_INSTALLED=true ;;
    esac
    if $HX_INSTALLED; then success "Helix installed"; fi

    # VSCode
    case $BASE in
        debian)
            curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
                | gpg --dearmor | sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
            echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
                | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
            sudo apt update
            $PM_INSTALL code
            ;;
        fedora)
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            cat <<'EOF' | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
            $PM_INSTALL code
            ;;
        arch)
            aur_install visual-studio-code-bin
            ;;
    esac
    success "VSCode installed"
}

# ── Communication apps ────────────────────────────────────────────
install_comms() {
    header "Installing communication apps"

    # Discord
    case $BASE in
        debian)
            curl -Lo /tmp/discord.deb \
                "https://discord.com/api/download?platform=linux&format=deb"
            sudo dpkg -i /tmp/discord.deb
            sudo apt install -f -y
            rm -f /tmp/discord.deb
            ;;
        fedora)
            flatpak install -y flathub com.discordapp.Discord
            ;;
        arch)
            $PM_INSTALL discord
            ;;
    esac
    success "Discord installed"

    # Telegram (Flatpak — consistent across distros)
    flatpak install -y flathub org.telegram.desktop
    success "Telegram installed"
}

# ── Media apps ────────────────────────────────────────────────────
install_media() {
    header "Installing media apps"

    # Enable RPM Fusion on Fedora (required for VLC and OBS)
    if [ "$BASE" = "fedora" ]; then
        info "Enabling RPM Fusion Free repo (required for VLC and OBS)..."
        sudo dnf install -y \
            "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
            2>/dev/null || warn "RPM Fusion Free install failed — VLC/OBS may not install."
    fi

    # OBS Studio
    case $BASE in
        debian)
            # OBS is in Debian's main repos (no PPA needed — PPAs are Ubuntu-only)
            $PM_INSTALL obs-studio
            ;;
        fedora) $PM_INSTALL obs-studio ;;
        arch)   $PM_INSTALL obs-studio ;;
    esac
    success "OBS Studio installed"

    # VLC
    case $BASE in
        debian) $PM_INSTALL vlc ;;
        fedora) $PM_INSTALL vlc ;;
        arch)   $PM_INSTALL vlc ;;
    esac
    success "VLC installed"

    # Spotify (Flatpak)
    flatpak install -y flathub com.spotify.Client
    success "Spotify installed"

    # Dopamine music player (Flatpak)
    flatpak install -y flathub io.github.digimezzo.dopamine \
        || warn "Dopamine not on Flathub yet; get the AppImage/deb/rpm from https://github.com/digimezzo/dopamine/releases"
    success "Dopamine install attempted"
}

# ── Productivity ──────────────────────────────────────────────────
install_productivity() {
    header "Installing productivity apps"

    # Obsidian (Flatpak)
    flatpak install -y flathub md.obsidian.Obsidian
    success "Obsidian installed"
}

# ── Full-stack development tools ──────────────────────────────────
install_dev_tools() {
    header "Installing full-stack development tools"

    # Build essentials
    case $BASE in
        debian) $PM_INSTALL build-essential pkg-config libssl-dev ;;
        fedora) $PM_INSTALL gcc gcc-c++ make pkgconf openssl-devel ;;
        arch)   $PM_INSTALL base-devel openssl ;;
    esac

    # Git + Git LFS
    case $BASE in
        debian) $PM_INSTALL git git-lfs ;;
        fedora) $PM_INSTALL git git-lfs ;;
        arch)   $PM_INSTALL git git-lfs ;;
    esac
    sudo -u "$REAL_USER" git lfs install 2>/dev/null || true
    success "Build tools + Git installed"

    # tmux
    case $BASE in
        debian) $PM_INSTALL tmux ;;
        fedora) $PM_INSTALL tmux ;;
        arch)   $PM_INSTALL tmux ;;
    esac

    # Node.js via nvm (version manager)
    if [ ! -d "$REAL_HOME/.nvm" ]; then
        info "Installing nvm + Node.js LTS for ${REAL_USER}..."
        sudo -u "$REAL_USER" bash -c \
            'curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash'
        sudo -u "$REAL_USER" bash -c \
            'export NVM_DIR="$HOME/.nvm"; source "$NVM_DIR/nvm.sh"; nvm install --lts; nvm use --lts'
        success "Node.js LTS installed via nvm"
    else
        info "nvm already present — skipping Node.js install"
    fi

    # Python
    case $BASE in
        debian) $PM_INSTALL python3 python3-pip python3-venv ;;
        fedora) $PM_INSTALL python3 python3-pip ;;
        arch)   $PM_INSTALL python python-pip ;;
    esac
    success "Python installed"

    # Docker (official install script — works across distros)
    if ! command -v docker &>/dev/null; then
        info "Installing Docker..."
        curl -fsSL https://get.docker.com | sudo sh
        sudo usermod -aG docker "$REAL_USER"
        sudo systemctl enable --now docker
        success "Docker installed (re-login required for group membership)"
    else
        info "Docker already installed"
    fi

    # Docker Compose (plugin)
    case $BASE in
        debian) sudo apt install -y docker-compose-plugin 2>/dev/null || \
                sudo apt install -y docker-compose 2>/dev/null || true ;;
        fedora) $PM_INSTALL docker-compose-plugin 2>/dev/null || $PM_INSTALL docker-compose 2>/dev/null || true ;;
        arch)   $PM_INSTALL docker-compose-plugin 2>/dev/null || $PM_INSTALL docker-compose 2>/dev/null || true ;;
    esac

    # Rust via rustup
    if [ ! -d "$REAL_HOME/.cargo" ]; then
        info "Installing Rust via rustup for ${REAL_USER}..."
        sudo -u "$REAL_USER" bash -c \
            'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path'
        success "Rust installed"
    else
        info "Rust already installed"
    fi

    # Go
    case $BASE in
        debian)
            GO_VER=$(curl -s --max-time 15 "https://go.dev/VERSION?m=text" | head -1)
            if [ -z "$GO_VER" ]; then
                warn "Could not fetch Go version — skipping Go install."
            else
                curl -Lo /tmp/go.tar.gz "https://go.dev/dl/${GO_VER}.linux-amd64.tar.gz"
                sudo rm -rf /usr/local/go
                sudo tar -C /usr/local -xzf /tmp/go.tar.gz
                rm -f /tmp/go.tar.gz
                grep -qF '/usr/local/go/bin' "$REAL_HOME/.profile" \
                    || echo 'export PATH=$PATH:/usr/local/go/bin' >> "$REAL_HOME/.profile"
                success "Go installed"
            fi
            ;;
        fedora) $PM_INSTALL golang; success "Go installed" ;;
        arch)   $PM_INSTALL go;     success "Go installed" ;;
    esac

    # Java via SDKMAN (manages multiple JDK versions)
    if ! command -v sdk &>/dev/null && [ ! -d "$REAL_HOME/.sdkman" ]; then
        info "Installing SDKMAN and Java LTS (Temurin)..."
        sudo -u "$REAL_USER" bash -c 'curl -s "https://get.sdkman.io" | bash'
        # shellcheck source=/dev/null
        source "$REAL_HOME/.sdkman/bin/sdkman-init.sh" 2>/dev/null || true
        sudo -u "$REAL_USER" bash -c \
            'source "$HOME/.sdkman/bin/sdkman-init.sh" && sdk install java 21.0.3-tem'
        success "Java 21 LTS installed via SDKMAN"
    else
        info "SDKMAN already present — skipping Java install"
    fi

    # PostgreSQL client
    case $BASE in
        debian) $PM_INSTALL postgresql-client ;;
        fedora) $PM_INSTALL postgresql ;;
        arch)   $PM_INSTALL postgresql-libs ;;
    esac

    # HTTP / API tools
    case $BASE in
        debian) $PM_INSTALL curl wget jq httpie ;;
        fedora) $PM_INSTALL curl wget jq python3-httpie ;;
        arch)   $PM_INSTALL curl wget jq python-httpie ;;
    esac

    # Beekeeper Studio — cross-platform DB GUI
    flatpak install -y flathub io.beekeeperstudio.Studio

    # Opencode AI CLI
    if command -v npm &>/dev/null; then
        npm install -g opencode-ai \
            || warn "opencode npm install failed; try: curl -fsSL https://opencode.ai/install | sh"
    else
        curl -fsSL https://opencode.ai/install | sh \
            || warn "opencode install failed; visit https://opencode.ai"
    fi

    success "Full-stack dev tools installed"
}

# ── Fastfetch ─────────────────────────────────────────────────────
install_fastfetch() {
    header "Installing fastfetch"

    FF_INSTALLED=false

    # Direct latest-release download URL — no GitHub API call, no rate limiting
    local FF_DEB_URL="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.deb"
    local FF_RPM_URL="https://github.com/fastfetch-cli/fastfetch/releases/latest/download/fastfetch-linux-amd64.rpm"

    case $BASE in
        debian)
            info "Trying fastfetch from apt (available in Trixie+)..."
            if sudo apt-get install -y -q fastfetch 2>/dev/null; then
                FF_INSTALLED=true
            else
                info "Not in apt repos — downloading .deb from GitHub..."
                if curl -fL --max-time 60 -o /tmp/fastfetch.deb "$FF_DEB_URL"; then
                    sudo apt-get install -y -q /tmp/fastfetch.deb && FF_INSTALLED=true
                    rm -f /tmp/fastfetch.deb
                else
                    warn "fastfetch .deb download failed."
                fi
            fi
            ;;
        fedora)
            info "Trying fastfetch from dnf..."
            if $PM_INSTALL fastfetch 2>/dev/null; then
                FF_INSTALLED=true
            else
                info "Not in dnf repos — downloading .rpm from GitHub..."
                if curl -fL --max-time 60 -o /tmp/fastfetch.rpm "$FF_RPM_URL"; then
                    sudo rpm -i /tmp/fastfetch.rpm && FF_INSTALLED=true
                    rm -f /tmp/fastfetch.rpm
                else
                    warn "fastfetch .rpm download failed."
                fi
            fi
            ;;
        arch)
            if $PM_INSTALL fastfetch 2>/dev/null; then FF_INSTALLED=true; fi
            ;;
    esac

    if ! $FF_INSTALLED; then
        warn "fastfetch could not be installed automatically."
        warn "Install manually: https://github.com/fastfetch-cli/fastfetch/releases"
    fi

    # Also install screenfetch as a lightweight alternative
    info "Installing screenfetch (lightweight alternative)..."
    case $BASE in
        debian) $PM_INSTALL screenfetch 2>/dev/null || true ;;
        fedora) $PM_INSTALL screenfetch 2>/dev/null || true ;;
        arch)   $PM_INSTALL screenfetch 2>/dev/null || true ;;
    esac

    # Deploy config and ASCII art to the real user's home
    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config/fastfetch"
    cp "${SCRIPT_DIR}/configs/fastfetch/config.jsonc" "$REAL_HOME/.config/fastfetch/config.jsonc"
    cp "${SCRIPT_DIR}/configs/fastfetch/wolf.txt"     "$REAL_HOME/.config/fastfetch/wolf.txt"
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config/fastfetch"

    success "fastfetch installed and configured for user: ${REAL_USER}"
}

# ── Shell profile updates ─────────────────────────────────────────
update_shell() {
    header "Updating shell profile"

    # Detect the real user's login shell and RC file
    REAL_SHELL=$(getent passwd "$REAL_USER" | cut -d: -f7 2>/dev/null || echo "/bin/bash")
    if echo "$REAL_SHELL" | grep -q zsh; then
        SHELL_RC="$REAL_HOME/.zshrc"
    elif [ -f "$REAL_HOME/.zshrc" ]; then
        SHELL_RC="$REAL_HOME/.zshrc"
    else
        SHELL_RC="$REAL_HOME/.bashrc"
    fi

    # Create the file if it doesn't exist yet
    [ -f "$SHELL_RC" ] || sudo -u "$REAL_USER" touch "$SHELL_RC"

    info "Updating ${SHELL_RC}"

    # fastfetch on terminal start
    grep -qF 'fastfetch' "$SHELL_RC" \
        || echo -e '\n# Show system info on terminal start\n[ -z "$TMUX" ] && fastfetch' >> "$SHELL_RC"

    # nvm
    grep -qF 'NVM_DIR' "$SHELL_RC" || cat >> "$SHELL_RC" <<'SHELLEOF'

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
SHELLEOF

    # Rust
    grep -qF 'cargo/env' "$SHELL_RC" \
        || echo -e '\n# Rust\n[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"' >> "$SHELL_RC"

    # Go (Debian manual install)
    [ "$BASE" = "debian" ] && {
        grep -qF '/usr/local/go/bin' "$SHELL_RC" \
            || echo 'export PATH=$PATH:/usr/local/go/bin' >> "$SHELL_RC"
    }

    # SDKMAN (Java)
    grep -qF 'sdkman-init.sh' "$SHELL_RC" || cat >> "$SHELL_RC" <<'SHELLEOF'

# SDKMAN (Java / JVM tooling)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
SHELLEOF

    # Fix ownership so the real user can write their own RC
    chown "$REAL_USER:$REAL_USER" "$SHELL_RC"

    success "Shell profile updated: ${SHELL_RC} (user: ${REAL_USER})"
}

# ── Summary ───────────────────────────────────────────────────────
print_summary() {
    echo ""
    echo -e "${BOLD}${PURPLE}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║                  Setup Complete!                     ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    echo -e "${CYAN}Installed:${NC}"
    echo "  Browsers   : Firefox, Brave, Librewolf"
    echo "  Editors    : Neovim, Helix, VSCode"
    echo "  Comms      : Discord, Telegram"
    echo "  Media      : OBS Studio, VLC, Spotify, Dopamine"
    echo "  Notes      : Obsidian"
    echo "  Dev        : Node/nvm, Python, Docker, Rust, Go, Java/SDKMAN, PostgreSQL client"
    echo "               Beekeeper Studio, Opencode, tmux, jq, httpie"
    echo "  System     : Flatpak/Flathub, fastfetch"
    if $INSTALL_BLUETOOTH;     then echo "  Drivers    : Bluetooth (bluez + blueman)"; fi
    if $INSTALL_WIFI;          then echo "  Drivers    : WiFi / NetworkManager"; fi
    if $INSTALL_MOUSE_DRIVERS; then echo "  Drivers    : Mouse / pointer (libinput)"; fi
    if $INSTALL_GPU_DRIVERS;   then echo "  Drivers    : ${GPU_TYPE^^} GPU"; fi
    if $INSTALL_PIPEWIRE;      then echo "  Audio      : PipeWire"; fi
    echo ""
    warn "Re-login (or reboot) for Docker group, nvm, and cargo PATH to take effect."
    if $INSTALL_I3;       then info "i3       : ${REAL_HOME}/.config/{i3,picom,rofi,alacritty} — i3bar + i3status"; fi
    if $INSTALL_BSPWM;    then info "bspwm    : ${REAL_HOME}/.config/{bspwm,sxhkd,polybar,rofi,alacritty}"; fi
    if $INSTALL_AWESOME;  then info "awesome  : ${REAL_HOME}/.config/{awesome,picom,rofi,alacritty}"; fi
    if $INSTALL_QTILE;    then info "qtile    : ${REAL_HOME}/.config/{qtile,picom,rofi,alacritty}"; fi
    if $INSTALL_FLUXBOX;  then info "fluxbox  : ${REAL_HOME}/.fluxbox/{init,keys,menu,styles/Purple}"; fi
    if $INSTALL_DWM;      then info "dwm      : compiled to /usr/local/bin/dwm — add 'exec dwm' to ~/.xinitrc"; fi
    if $INSTALL_SWAY;     then info "sway     : ${REAL_HOME}/.config/{sway,waybar,rofi,alacritty}"; fi
    if $INSTALL_HYPRLAND; then info "hyprland : ${REAL_HOME}/.config/{hypr,waybar,rofi,alacritty}"; fi
    info "All configs installed for user: ${REAL_USER}"
}

# ── Main ──────────────────────────────────────────────────────────
main() {
    echo -e "${BOLD}${PURPLE}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║          Linux Machine Setup Script                  ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    check_unix
    detect_distro
    select_de
    select_optional_drivers

    update_system
    install_base_deps
    install_aur_helper
    setup_flatpak

    if $INSTALL_I3;        then install_i3; fi
    if $INSTALL_BSPWM;     then install_bspwm; fi
    if $INSTALL_AWESOME;   then install_awesome; fi
    if $INSTALL_QTILE;     then install_qtile; fi
    if $INSTALL_FLUXBOX;   then install_fluxbox; fi
    if $INSTALL_DWM;       then install_dwm; fi
    if $INSTALL_SWAY;      then install_sway; fi
    if $INSTALL_HYPRLAND;  then install_hyprland; fi
    if $INSTALL_KDE;       then install_kde; fi
    if $INSTALL_XFCE;      then install_xfce; fi
    if $INSTALL_CINNAMON;  then install_cinnamon; fi

    if $INSTALL_BLUETOOTH;     then install_bluetooth; fi
    if $INSTALL_WIFI;          then install_wifi; fi
    if $INSTALL_MOUSE_DRIVERS; then install_mouse_drivers; fi
    if $INSTALL_GPU_DRIVERS;   then install_gpu_drivers; fi
    if $INSTALL_PIPEWIRE;      then install_pipewire; fi

    install_browsers
    install_editors
    install_comms
    install_media
    install_productivity
    install_dev_tools
    install_fastfetch
    update_shell

    print_summary
}

main "$@"
