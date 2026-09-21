#!/usr/bin/env bash

# ==============================================================================
# DOTFILES INSTALLER & ENVIRONMENT SETUP SCRIPT
# OS Support: CachyOS / Arch Linux
# ==============================================================================
# Usage:
#   ./install.sh                  # Interactive mode
#   ./install.sh --no-pkg         # Skip package check & install configs only
#   ./install.sh -y               # Non-interactive / unattended mode
# ==============================================================================

set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}"
TIMESTAMP="$(date +'%Y%m%d_%H%M%S')"

SKIP_PKGS=false
AUTO_YES=false

for arg in "$@"; do
    case "$arg" in
        --no-pkg|--skip-packages) SKIP_PKGS=true ;;
        -y|--yes) AUTO_YES=true ;;
    esac
done

# Colors
RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
BLUE="\033[0;34m"
MAGENTA="\033[0;35m"
CYAN="\033[0;36m"
BOLD="\033[1m"
NC="\033[0m"

log_info()    { echo -e "${BLUE}${BOLD}==>${NC} $1"; }
log_success() { echo -e "${GREEN}${BOLD} [OK]${NC} $1"; }
log_warn()    { echo -e "${YELLOW}${BOLD}[WARN]${NC} $1"; }
log_step()    { echo -e "\n${MAGENTA}${BOLD}--- $1 ---${NC}"; }

echo -e "${CYAN}${BOLD}"
cat << "BANNER"
  __  __                         __        ____  __ 
 |  \/  | __ _ _ __   __ _  ___  \ \      / /  \/  |
 | |\/| |/ _` | '_ \ / _` |/ _ \  \ \ /\ / /| |\/| |
 | |  | | (_| | | | | (_| | (_) |  \ V  V / | |  | |
 |_|  |_|\__,_|_| |_|\__, |\___/    \_/\_/  |_|  |_|
                     |___/                          
          Dotfiles Installer & Environment Setup
BANNER
echo -e "${NC}"

# ------------------------------------------------------------------------------
# 1. Detect Package Manager & Offer Package Installation
# ------------------------------------------------------------------------------
log_step "1. Checking System Packages"

if [ "$SKIP_PKGS" = true ]; then
    log_info "Skipping package checks (--no-pkg flag specified)."
else
    AUR_HELPER=""
    if command -v paru &>/dev/null; then
        AUR_HELPER="paru"
    elif command -v yay &>/dev/null; then
        AUR_HELPER="yay"
    fi

    PACKAGES=(
        mangowm
        quickshell
        kitty
        alacritty
        fish
        fastfetch
        starship
        zoxide
        eza
        bat
        lazygit
        fzf
        ripgrep
        fd
        matugen-bin
        awww
        cliphist
        wl-clipboard
        xdg-desktop-portal-wlr
        xdg-desktop-portal
        brightnessctl
        wireplumber
        pipewire
        pipewire-pulse
        adw-gtk-theme
        papirus-icon-theme
        qt5ct
        qt6ct
        noto-fonts
        noto-fonts-cjk
        noto-fonts-emoji
        ttf-meslo-nerd
    )

    MISSING_PKGS=()
    for pkg in "${PACKAGES[@]}"; do
        if ! pacman -Qi "$pkg" &>/dev/null; then
            if [ "$pkg" = "matugen-bin" ] && pacman -Qi matugen &>/dev/null; then
                continue
            fi
            MISSING_PKGS+=("$pkg")
        fi
    done

    if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
        log_warn "Missing packages detected: ${MISSING_PKGS[*]}"
        if [ -n "$AUR_HELPER" ] && [ -t 0 ] && [ "$AUTO_YES" = false ]; then
            read -rp "Do you want to install missing packages using $AUR_HELPER now? [y/N]: " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log_info "Installing missing packages with $AUR_HELPER..."
                "$AUR_HELPER" -S --needed "${MISSING_PKGS[@]}" || log_warn "Some packages failed to install, proceeding with configuration..."
            fi
        else
            log_info "To install missing packages later, run: ${AUR_HELPER:-pacman} -S ${MISSING_PKGS[*]}"
        fi
    else
        log_success "All essential packages are installed."
    fi
fi

# ------------------------------------------------------------------------------
# 2. Backup Existing Configurations
# ------------------------------------------------------------------------------
log_step "2. Backing up Existing Configurations"

mkdir -p "$CONFIG_DIR"
BACKUP_DIR="$HOME/.config_backup_${TIMESTAMP}"
HAS_BACKUP=false

backup_if_real() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        mkdir -p "$BACKUP_DIR"
        local bname="$(basename "$target")"
        cp -r "$target" "$BACKUP_DIR/$bname"
        rm -rf "$target"
        HAS_BACKUP=true
        log_info "Backed up $target -> $BACKUP_DIR/$bname"
    fi
}

CONFIG_ITEMS=(
    mango
    mango-modular
    quickshell
    kitty
    alacritty
    matugen
    gtk-3.0
    gtk-4.0
    qt5ct
    qt6ct
    scripts
    btop
    fastfetch
)

for item in "${CONFIG_ITEMS[@]}"; do
    backup_if_real "$CONFIG_DIR/$item"
done

if [ "$HAS_BACKUP" = true ]; then
    log_success "Backup preserved at: $BACKUP_DIR"
else
    log_success "No conflicting directory backups required."
fi

# ------------------------------------------------------------------------------
# 3. Create Clean Symlinks in ~/.config
# ------------------------------------------------------------------------------
log_step "3. Symlinking Configurations"

link_item() {
    local src="$1"
    local dest="$2"
    local name="$(basename "$src")"

    if [ -L "$dest" ]; then
        local current_target
        current_target="$(readlink -f "$dest")"
        if [ "$current_target" = "$src" ]; then
            log_success "$name is already properly linked."
            return
        else
            rm -f "$dest"
        fi
    elif [ -e "$dest" ]; then
        rm -rf "$dest"
    fi

    ln -sfn "$src" "$dest"
    log_success "Linked $name -> $dest"
}

for item in mango quickshell matugen scripts kitty alacritty gtk-3.0 gtk-4.0 qt6ct qt5ct btop fastfetch environment.d; do
    if [ -d "$DOTFILES_DIR/$item" ]; then
        link_item "$DOTFILES_DIR/$item" "$CONFIG_DIR/$item"
    fi
done

# Backwards compatibility symlink for mango-modular
ln -sfn "$CONFIG_DIR/mango" "$CONFIG_DIR/mango-modular"

# Link fish configuration
mkdir -p "$CONFIG_DIR/fish"
if [ -f "$DOTFILES_DIR/fish/config.fish" ]; then
    if [ -f "$CONFIG_DIR/fish/config.fish" ] && [ ! -L "$CONFIG_DIR/fish/config.fish" ]; then
        mv "$CONFIG_DIR/fish/config.fish" "$CONFIG_DIR/fish/config.fish.bak.${TIMESTAMP}"
    fi
    ln -sfn "$DOTFILES_DIR/fish/config.fish" "$CONFIG_DIR/fish/config.fish"
    log_success "Linked fish/config.fish -> $CONFIG_DIR/fish/config.fish"
fi

# Link starship configuration
if [ -f "$DOTFILES_DIR/starship/starship.toml" ]; then
    if [ -f "$CONFIG_DIR/starship.toml" ] && [ ! -L "$CONFIG_DIR/starship.toml" ]; then
        mv "$CONFIG_DIR/starship.toml" "$CONFIG_DIR/starship.toml.bak.${TIMESTAMP}"
    fi
    ln -sfn "$DOTFILES_DIR/starship/starship.toml" "$CONFIG_DIR/starship.toml"
    log_success "Linked starship/starship.toml -> $CONFIG_DIR/starship.toml"
fi

# Restore bash/zsh profile if requested or missing
if [ -f "$DOTFILES_DIR/shell/.bashrc" ] && [ ! -f "$HOME/.bashrc" ]; then
    cp "$DOTFILES_DIR/shell/.bashrc" "$HOME/.bashrc"
    log_info "Restored .bashrc from dotfiles"
fi

# Fix user-specific home paths in qt5ct and qt6ct
for qtc in "$CONFIG_DIR/qt5ct/qt5ct.conf" "$CONFIG_DIR/qt6ct/qt6ct.conf"; do
    if [ -f "$qtc" ]; then
        sed -i "s|color_scheme_path=.*/colors/current.conf|color_scheme_path=$CONFIG_DIR/$(basename "$(dirname "$qtc")")/colors/current.conf|g" "$qtc"
    fi
done

# ------------------------------------------------------------------------------
# 4. Install Fonts
# ------------------------------------------------------------------------------
log_step "4. Installing Custom & Icon Fonts"

mkdir -p "$DATA_DIR/fonts"
if [ -d "$DOTFILES_DIR/assets/fonts" ]; then
    log_info "Copying fonts to $DATA_DIR/fonts/..."
    cp -r "$DOTFILES_DIR/assets/fonts/"* "$DATA_DIR/fonts/"
    if command -v fc-cache &>/dev/null; then
        log_info "Updating font cache..."
        fc-cache -f "$DATA_DIR/fonts"
        log_success "Fonts installed and cache refreshed."
    fi
fi

# ------------------------------------------------------------------------------
# 5. Install Mouse Cursor & Icon Themes
# ------------------------------------------------------------------------------
log_step "5. Installing Mouse Cursor & Default Pointers"

mkdir -p "$DATA_DIR/icons"
mkdir -p "$HOME/.icons/default"

if [ -d "$DOTFILES_DIR/assets/icons" ]; then
    log_info "Installing cursor themes to $DATA_DIR/icons/..."
    cp -r "$DOTFILES_DIR/assets/icons/"* "$DATA_DIR/icons/"
fi

# Set default cursor for legacy X11 / Wayland fallbacks
cat << 'EOF_CURSOR' > "$HOME/.icons/default/index.theme"
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=macOS
EOF_CURSOR
log_success "Default cursor fallback configured to 'macOS'."

# ------------------------------------------------------------------------------
# 6. Apply Desktop Appearance Settings (GTK, Qt, Fonts)
# ------------------------------------------------------------------------------
log_step "6. Applying Desktop & Interface Theming"

if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface cursor-theme 'macOS' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name 'Adwaita Sans 11' 2>/dev/null || true
    log_success "GNOME/GTK settings applied via gsettings."
fi

# ------------------------------------------------------------------------------
# 7. Set Permissions & Initialize Theme
# ------------------------------------------------------------------------------
log_step "7. Finalizing Permissions & Theming Engine"

chmod +x "$DOTFILES_DIR/install.sh"
chmod +x "$DOTFILES_DIR/mango/autostart.sh"
chmod +x "$DOTFILES_DIR/scripts/"*.sh 2>/dev/null || true
chmod +x "$DOTFILES_DIR/scripts/"*.py 2>/dev/null || true
chmod +x "$DOTFILES_DIR/quickshell/scripts/"*.sh 2>/dev/null || true
chmod +x "$DOTFILES_DIR/quickshell/scripts/"*.py 2>/dev/null || true

# Initialize wallpaper and Matugen dynamic color scheme
WALLPAPER="$DOTFILES_DIR/mango/wallpaper/wallhaven-zmomwo.png"
if [ ! -f "$WALLPAPER" ]; then
    WALLPAPER="$(find "$DOTFILES_DIR/mango/wallpaper" -type f \( -name "*.png" -o -name "*.jpg" \) | head -n 1)"
fi

if [ -f "$WALLPAPER" ] && [ -x "$CONFIG_DIR/scripts/set-wallpaper.sh" ]; then
    log_info "Triggering initial Matugen color extraction with $WALLPAPER..."
    "$CONFIG_DIR/scripts/set-wallpaper.sh" "$WALLPAPER" || log_warn "Wallpaper daemon not running; colors generated from image."
    log_success "Dynamic color scheme initialized for Kitty, Quickshell, MangoWM, GTK, and Qt."
fi

# Check default shell
CURRENT_LOGIN_SHELL="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7 || echo "${SHELL:-}")"
if [[ "$CURRENT_LOGIN_SHELL" != *"fish"* ]] && command -v fish &>/dev/null; then
    if [ "$AUTO_YES" = true ]; then
        chsh -s "$(which fish)" || true
    elif [ -t 0 ]; then
        read -rp "Do you want to change default shell to fish? [y/N]: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            chsh -s "$(which fish)" || log_warn "Could not change shell automatically. Run: chsh -s $(which fish)"
        fi
    fi
fi

echo
log_info "${GREEN}${BOLD}Installation and configuration complete!${NC}"
echo -e "You can now start MangoWM by logging in on tty1 or running: ${CYAN}mango${NC}\n"
