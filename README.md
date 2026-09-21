# 🥭 Vin's Modular Dotfiles

> Sleek, modern, and ultra-responsive Wayland desktop environment powered by **MangoWM**, **Quickshell**, **Material Design 3**, and **Fish Shell** on CachyOS / Arch Linux.

---

## ✨ Features & Highlights

- **Window Manager**: [MangoWM](https://github.com/DreamMaoMao/mango) (Clean modular architecture, custom per-workspace layouts, fast scroller and tile support, 1px borders, smooth animations).
- **Desktop Shell & Widgets**: [Quickshell](https://quickshell.outfoxxed.me/) (Dynamic Island / Notch bar, Material 3 Expressive Quick Settings, morphing launcher, live battery, audio, media, and wallpaper switcher).
- **Dynamic Theming Engine**: [Matugen](https://github.com/InioX/matugen) extracts dynamic Material You tonal palettes from any wallpaper and synchronously themes:
  - **Quickshell** semantic color tokens
  - **MangoWM** window borders & accents
  - **Kitty & Alacritty** terminals
  - **GTK 3 & GTK 4 / Libadwaita** (`adw-gtk3-dark` with dynamic CSS)
  - **Qt 5 & Qt 6** (`qt5ct` / `qt6ct` Fusion style)
- **Terminal**: [Kitty](https://sw.kovidgoyal.net/kitty/) with font ligatures, MesloLGS Nerd Font, opacity, and live SIGUSR1 theme reload.
- **Shell**: [Fish Shell](https://fishshell.com/) with instant MangoWM login autostart on tty1.
- **Mouse & Pointers**: macOS cursor theme with consistent sizing and default fallbacks.
- **Icon Set**: Papirus-Dark with automatic dynamic folder tinting.

---

## 🚀 One-Command Installation

On a fresh installation of CachyOS or Arch Linux:

```bash
git clone https://github.com/vinj026/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
chmod +x install.sh
./install.sh
```

The installer will:
1. Detect your package manager (`paru`, `yay`, or `pacman`) and install any missing dependencies.
2. Safely backup any existing non-symlinked configs to `~/.config_backup_<timestamp>`.
3. Create atomic symbolic links for all configurations into `~/.config/`.
4. Install all essential fonts (`MaterialSymbolsRounded`, `Inter`, `TitanOne`, `ZenKakuGothic`) into `~/.local/share/fonts` and refresh `fc-cache`.
5. Install the macOS cursor theme into `~/.local/share/icons/` and set default XCursor fallbacks.
6. Configure GTK, Qt, and GNOME appearance settings.
7. Run the initial Matugen theme extraction and wallpaper setup so everything looks cohesive out-of-the-box.

---

## 📂 Repository Structure

```
~/.dotfiles/
├── install.sh                  # Complete automated installer
├── packages.txt                # Required package list
├── README.md                   # Documentation
├── .gitignore                  # Clean repository ignores
│
├── mango/                      # MangoWM Configuration
│   ├── config.conf             # Main configuration loader
│   ├── autostart.sh            # Services autostart (awww, quickshell, cliphist)
│   ├── theme.conf              # Dynamic border colors (Matugen)
│   ├── modules/                # Modular conf files
│   │   ├── animations.conf     # Window animations
│   │   ├── environment.conf    # Session & toolkit environment variables
│   │   ├── input.conf          # Keyboard & touchpad settings
│   │   ├── keybindings.conf    # Comprehensive keybinds
│   │   ├── layouts.conf        # Scroller, Tile, Dwindle & tag rules
│   │   ├── monitors.conf       # Multi-monitor setup
│   │   ├── visuals.conf        # 1px borders, radius, gaps, blur, shadows
│   │   └── windows.conf        # Window rules & floating overrides
│   └── wallpaper/              # Curated wallpapers & current.jpg symlink
│
├── quickshell/                 # Material 3 Desktop Shell
│   ├── shell.qml               # Shell entry point
│   ├── components/             # Services (Battery, ControlCenter, Wifi, etc.)
│   ├── modules/                # Bar views (Notch, Dynamic Island, Center)
│   ├── shapes/                 # M3 continuous squircle surfaces
│   ├── theme/                  # M3 color tokens and shape geometry
│   └── scripts/                # Helper tools for system info and privacy
│
├── fish/                       # Fish shell config (autostart on tty1)
│   └── config.fish
│
├── kitty/                      # Kitty terminal config & dynamic theme
│   ├── kitty.conf
│   └── theme.conf
│
├── alacritty/                  # Alacritty terminal fallback
│   ├── alacritty.toml
│   └── theme.toml
│
├── matugen/                    # Material You color scheme generator
│   ├── config.toml             # Target mapping
│   └── templates/              # CSS, JSON, and conf templates
│
├── gtk-3.0/ & gtk-4.0/         # GTK themes & dynamic CSS overrides
│   ├── settings.ini
│   └── gtk.css
│
├── qt5ct/ & qt6ct/             # Qt styling (Fusion + dynamic palette)
│   ├── qt5ct.conf & qt6ct.conf
│   └── colors/current.conf
│
├── scripts/                    # Automation Scripts
│   ├── set-theme.sh            # Switch theme across all apps
│   ├── set-wallpaper.sh        # Apply wallpaper & recompute color schemes
│   └── sync-folders.py         # Sync Papirus icon folder tint
│
└── assets/                     # Bundled binary assets
    ├── fonts/                  # UI icon font & primary typography
    └── icons/                  # macOS cursor theme
```

---

## ⌨️ Common Keybindings

| Keybinding | Action |
| :--- | :--- |
| `Super + Enter` | Open Terminal (Kitty) |
| `Super + Space` | Toggle Quickshell App Launcher |
| `Super + Q` | Close focused window |
| `Super + Shift + R` | Reload MangoWM configuration |
| `Super + 1-9` | Switch to workspace / tag 1-9 |
| `Super + Shift + 1-9` | Move focused window to workspace 1-9 |
| `Alt + Tab` | Cycle through windows in current workspace |
| `Super + ,` | Set window proportion to 0.5 |
| `Super + .` | Set window proportion to 1.0 |
| `Super + /` | Switch proportion preset |

---

## 🎨 Theme & Wallpaper Management

Change wallpaper and dynamically theme your whole desktop:
```bash
~/.config/scripts/set-wallpaper.sh /path/to/image.png
```

Or switch to a preset theme manually:
```bash
~/.config/scripts/set-theme.sh catppuccin
~/.config/scripts/set-theme.sh gruvbox
~/.config/scripts/set-theme.sh everforest
~/.config/scripts/set-theme.sh everblush
~/.config/scripts/set-theme.sh wallpaper
```
