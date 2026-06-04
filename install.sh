#!/usr/bin/env bash
# ================================================================
#  Linux Machine Setup Script
#  Supports: Debian-based | Fedora-based | Arch-based
#  Desktop Envs: i3, KDE Plasma, XFCE, Cinnamon (pick one or more)
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
            PM_UPDATE="sudo apt update && sudo apt upgrade -y"
            PM_INSTALL="sudo apt install -y"
            ;;
        fedora)
            PM_UPDATE="sudo dnf upgrade -y"
            PM_INSTALL="sudo dnf install -y"
            ;;
        arch)
            PM_UPDATE="sudo pacman -Syu --noconfirm"
            PM_INSTALL="sudo pacman -S --noconfirm --needed"
            AUR_HELPER=""
            ;;
    esac

    success "Distro base: ${BASE} (${DISTRO_ID})"
}

# ── Desktop environment selection ────────────────────────────────
select_de() {
    header "Desktop Environment Setup"

    INSTALL_I3=false
    INSTALL_KDE=false
    INSTALL_XFCE=false
    INSTALL_CINNAMON=false

    echo "Which desktop environment(s) would you like to install?"
    echo "  1) i3 (tiling window manager)"
    echo "  2) KDE Plasma"
    echo "  3) XFCE"
    echo "  4) Cinnamon"
    echo "  5) Multiple (choose below)"
    echo ""
    read -rp "Enter choice [1-5]: " de_choice

    case $de_choice in
        1) INSTALL_I3=true ;;
        2) INSTALL_KDE=true ;;
        3) INSTALL_XFCE=true ;;
        4) INSTALL_CINNAMON=true ;;
        5)
            echo ""
            read -rp "  Install i3?       [y/N] " r; [[ "$r" =~ ^[Yy] ]] && INSTALL_I3=true
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
    $INSTALL_I3       && info "Will install: i3"
    $INSTALL_KDE      && info "Will install: KDE Plasma"
    $INSTALL_XFCE     && info "Will install: XFCE"
    $INSTALL_CINNAMON && info "Will install: Cinnamon"
}

# ── System update ────────────────────────────────────────────────
update_system() {
    header "Updating system packages"
    eval "$PM_UPDATE"
    success "System up to date"
}

# ── Base dependencies ────────────────────────────────────────────
install_base_deps() {
    header "Installing base dependencies"

    case $BASE in
        debian)
            $PM_INSTALL \
                curl wget git gnupg2 apt-transport-https ca-certificates \
                software-properties-common xorg xinit xdg-utils \
                flatpak pulseaudio pulseaudio-utils
            ;;
        fedora)
            $PM_INSTALL \
                curl wget git gnupg2 xorg-x11-server-Xorg xinit xdg-utils \
                flatpak pulseaudio pulseaudio-utils
            ;;
        arch)
            $PM_INSTALL \
                curl wget git gnupg xorg-server xorg-xinit xdg-utils \
                flatpak pulseaudio pulseaudio-utils
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
    git clone --depth=1 https://aur.archlinux.org/paru.git /tmp/paru-build
    (cd /tmp/paru-build && makepkg -si --noconfirm)
    AUR_HELPER="paru"
    success "paru installed"
}

aur_install() {
    [ "$BASE" = "arch" ] && ${AUR_HELPER:-paru} -S --noconfirm --needed "$@"
}

# ── Flatpak setup ────────────────────────────────────────────────
setup_flatpak() {
    header "Setting up Flatpak + Flathub"
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
    success "Flathub configured"
}

# ── i3 (minimal: wm + bar + launcher + compositor + wallpaper) ───
install_i3() {
    header "Installing i3"

    case $BASE in
        debian)
            $PM_INSTALL \
                i3 i3status rofi picom feh nitrogen \
                lightdm lightdm-gtk-greeter \
                polybar fonts-font-awesome fonts-noto-color-emoji \
                pavucontrol lxappearance maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
        fedora)
            $PM_INSTALL \
                i3 i3status rofi picom feh nitrogen \
                lightdm lightdm-gtk-greeter \
                polybar fontawesome-fonts google-noto-emoji-color-fonts \
                pavucontrol lxappearance maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
        arch)
            $PM_INSTALL \
                i3-wm i3status rofi picom feh nitrogen \
                lightdm lightdm-gtk-greeter \
                polybar ttf-font-awesome noto-fonts-emoji \
                pavucontrol lxappearance maim xdotool brightnessctl
            sudo systemctl enable lightdm
            ;;
    esac

    # Deploy i3 config
    mkdir -p "$HOME/.config/i3"
    cp "${SCRIPT_DIR}/configs/i3/config" "$HOME/.config/i3/config"

    # Deploy polybar config
    mkdir -p "$HOME/.config/polybar"
    cp "${SCRIPT_DIR}/configs/polybar/config.ini"  "$HOME/.config/polybar/config.ini"
    cp "${SCRIPT_DIR}/configs/polybar/launch.sh"   "$HOME/.config/polybar/launch.sh"
    chmod +x "$HOME/.config/polybar/launch.sh"

    # Deploy picom config
    mkdir -p "$HOME/.config/picom"
    cp "${SCRIPT_DIR}/configs/picom.conf" "$HOME/.config/picom/picom.conf"

    # Deploy rofi theme
    mkdir -p "$HOME/.config/rofi"
    cp "${SCRIPT_DIR}/configs/rofi/launcher.rasi" "$HOME/.config/rofi/launcher.rasi"

    success "i3 installed and configured"
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

    # Firefox
    case $BASE in
        debian) $PM_INSTALL firefox ;;
        fedora) $PM_INSTALL firefox ;;
        arch)   $PM_INSTALL firefox ;;
    esac
    success "Firefox installed"

    # Brave
    case $BASE in
        debian)
            sudo install -m 0755 -d /etc/apt/keyrings
            curl -fsSLo /etc/apt/keyrings/brave-browser-archive-keyring.gpg \
                https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
            echo "deb [signed-by=/etc/apt/keyrings/brave-browser-archive-keyring.gpg arch=amd64] \
https://brave-browser-apt-release.s3.brave.com/ stable main" \
                | sudo tee /etc/apt/sources.list.d/brave-browser.list > /dev/null
            sudo apt update
            $PM_INSTALL brave-browser
            ;;
        fedora)
            sudo dnf config-manager \
                --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo
            sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
            $PM_INSTALL brave-browser
            ;;
        arch)
            aur_install brave-bin
            ;;
    esac
    success "Brave installed"

    # Librewolf — Flatpak is the most reliable cross-distro method
    flatpak install -y flathub io.gitlab.librewolf-community.LibreWolf
    success "Librewolf installed (Flatpak)"
}

# ── Terminal editors ──────────────────────────────────────────────
install_editors() {
    header "Installing terminal editors (Neovim + Helix)"

    # Neovim
    case $BASE in
        debian)
            # Use official release binary for latest stable
            NV_URL=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest \
                | grep -oP '"browser_download_url": "\K[^"]+nvim-linux-x86_64\.tar\.gz')
            curl -Lo /tmp/nvim.tar.gz "$NV_URL"
            sudo tar -xzf /tmp/nvim.tar.gz -C /opt
            sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
            ;;
        fedora) $PM_INSTALL neovim ;;
        arch)   $PM_INSTALL neovim ;;
    esac
    success "Neovim installed"

    # Helix
    case $BASE in
        debian)
            HX_URL=$(curl -s https://api.github.com/repos/helix-editor/helix/releases/latest \
                | grep -oP '"browser_download_url": "\K[^"]+helix-[^"]+linux-x86_64\.tar\.xz')
            curl -Lo /tmp/helix.tar.xz "$HX_URL"
            sudo mkdir -p /opt/helix
            sudo tar -xJf /tmp/helix.tar.xz -C /opt/helix --strip-components=1
            sudo ln -sf /opt/helix/hx /usr/local/bin/hx
            ;;
        fedora)
            # Helix is in Fedora 38+ repos
            $PM_INSTALL helix || flatpak install -y flathub com.helix_editor.Helix
            ;;
        arch) $PM_INSTALL helix ;;
    esac
    success "Helix installed"

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

    # OBS Studio
    case $BASE in
        debian)
            sudo add-apt-repository ppa:obsproject/obs-studio -y
            sudo apt update
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
        fedora) $PM_INSTALL gcc gcc-c++ make openssl-devel ;;
        arch)   $PM_INSTALL base-devel openssl ;;
    esac

    # Git + Git LFS
    case $BASE in
        debian) $PM_INSTALL git git-lfs ;;
        fedora) $PM_INSTALL git git-lfs ;;
        arch)   $PM_INSTALL git git-lfs ;;
    esac
    success "Build tools + Git installed"

    # tmux
    case $BASE in
        debian) $PM_INSTALL tmux ;;
        fedora) $PM_INSTALL tmux ;;
        arch)   $PM_INSTALL tmux ;;
    esac

    # Node.js via nvm (version manager)
    if ! command -v nvm &>/dev/null && [ ! -d "$HOME/.nvm" ]; then
        info "Installing nvm + Node.js LTS..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        export NVM_DIR="$HOME/.nvm"
        # shellcheck source=/dev/null
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        nvm install --lts
        nvm use --lts
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
        sudo usermod -aG docker "$USER"
        sudo systemctl enable --now docker
        success "Docker installed (re-login required for group membership)"
    else
        info "Docker already installed"
    fi

    # Docker Compose (plugin)
    case $BASE in
        debian) sudo apt install -y docker-compose-plugin 2>/dev/null || \
                sudo apt install -y docker-compose 2>/dev/null || true ;;
        fedora) $PM_INSTALL docker-compose ;;
        arch)   $PM_INSTALL docker-compose ;;
    esac

    # Rust via rustup
    if ! command -v rustup &>/dev/null; then
        info "Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        # shellcheck source=/dev/null
        source "$HOME/.cargo/env" 2>/dev/null || true
        success "Rust installed"
    else
        info "Rust already installed"
    fi

    # Go
    case $BASE in
        debian)
            GO_VER=$(curl -s "https://go.dev/VERSION?m=text" | head -1)
            curl -Lo /tmp/go.tar.gz "https://go.dev/dl/${GO_VER}.linux-amd64.tar.gz"
            sudo rm -rf /usr/local/go
            sudo tar -C /usr/local -xzf /tmp/go.tar.gz
            grep -qF '/usr/local/go/bin' "$HOME/.profile" \
                || echo 'export PATH=$PATH:/usr/local/go/bin' >> "$HOME/.profile"
            success "Go installed"
            ;;
        fedora) $PM_INSTALL golang; success "Go installed" ;;
        arch)   $PM_INSTALL go;     success "Go installed" ;;
    esac

    # Java via SDKMAN (manages multiple JDK versions)
    if ! command -v sdk &>/dev/null && [ ! -d "$HOME/.sdkman" ]; then
        info "Installing SDKMAN and Java LTS (Temurin)..."
        curl -s "https://get.sdkman.io" | bash
        # shellcheck source=/dev/null
        source "$HOME/.sdkman/bin/sdkman-init.sh" 2>/dev/null || true
        sdk install java 21.0.3-tem   # Eclipse Temurin JDK 21 LTS
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

    case $BASE in
        debian)
            FF_URL=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
                | grep -oP '"browser_download_url": "\K[^"]+linux-amd64\.deb')
            curl -Lo /tmp/fastfetch.deb "$FF_URL"
            sudo dpkg -i /tmp/fastfetch.deb
            ;;
        fedora)
            $PM_INSTALL fastfetch \
                || (FF_URL=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest \
                    | grep -oP '"browser_download_url": "\K[^"]+linux-amd64\.rpm')
                    curl -Lo /tmp/fastfetch.rpm "$FF_URL"
                    sudo rpm -i /tmp/fastfetch.rpm)
            ;;
        arch)
            $PM_INSTALL fastfetch
            ;;
    esac

    # Deploy config and ASCII art
    mkdir -p "$HOME/.config/fastfetch"
    cp "${SCRIPT_DIR}/configs/fastfetch/config.jsonc" "$HOME/.config/fastfetch/config.jsonc"
    cp "${SCRIPT_DIR}/configs/fastfetch/wolf.txt"     "$HOME/.config/fastfetch/wolf.txt"

    success "fastfetch installed and configured"
}

# ── Shell profile updates ─────────────────────────────────────────
update_shell() {
    header "Updating shell profile"

    # Detect active shell RC file
    SHELL_RC="$HOME/.bashrc"
    [ -n "${ZSH_VERSION:-}" ] && SHELL_RC="$HOME/.zshrc"
    [ -f "$HOME/.zshrc" ]    && SHELL_RC="$HOME/.zshrc"

    # fastfetch on terminal start
    grep -qF 'fastfetch' "$SHELL_RC" \
        || echo -e '\n# Show system info on terminal start\n[ -z "$TMUX" ] && fastfetch' >> "$SHELL_RC"

    # nvm
    grep -qF 'NVM_DIR' "$SHELL_RC" || cat <<'EOF' >> "$SHELL_RC"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF

    # Rust
    grep -qF 'cargo/env' "$SHELL_RC" \
        || echo -e '\n# Rust\n[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"' >> "$SHELL_RC"

    # Go (Debian manual install)
    [ "$BASE" = "debian" ] && {
        grep -qF '/usr/local/go/bin' "$SHELL_RC" \
            || echo 'export PATH=$PATH:/usr/local/go/bin' >> "$SHELL_RC"
    }

    # SDKMAN (Java)
    grep -qF 'sdkman-init.sh' "$SHELL_RC" || cat <<'EOF' >> "$SHELL_RC"

# SDKMAN (Java / JVM tooling)
export SDKMAN_DIR="$HOME/.sdkman"
[[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ]] && source "$SDKMAN_DIR/bin/sdkman-init.sh"
EOF

    success "Shell profile updated (${SHELL_RC})"
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
    echo ""
    warn "Re-login (or reboot) for Docker group, nvm, and cargo PATH to take effect."
    $INSTALL_I3 && info "i3 configs: ~/.config/i3/  ~/.config/polybar/  ~/.config/picom/"
}

# ── Main ──────────────────────────────────────────────────────────
main() {
    echo -e "${BOLD}${PURPLE}"
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║          Linux Machine Setup Script                  ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    detect_distro
    select_de

    update_system
    install_base_deps
    install_aur_helper
    setup_flatpak

    $INSTALL_I3       && install_i3
    $INSTALL_KDE      && install_kde
    $INSTALL_XFCE     && install_xfce
    $INSTALL_CINNAMON && install_cinnamon

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
