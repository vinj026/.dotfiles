# vin's Dotfiles

Personal dotfiles for Linux Wayland setup featuring **Mango Compositor** (`mangowm`) and **Quickshell**.

## Components
- **Compositor**: [Mango](https://github.com/DreamMaoMao/mango) (wlroots-based Wayland compositor)
- **Shell & Widgets**: [Quickshell](https://quickshell.outfoxxed.me/) *(upcoming)*
- **Terminal**: Kitty
- **Wallpaper Daemon**: `awww`
- **Clipboard**: `cliphist` + `wl-clipboard`
- **Audio & Brightness**: `wpctl` + `brightnessctl`
- **Screenshot**: `grim` + `slurp`

## Directory Structure
```text
~/.dotfiles/
├── mango/              # Mango compositor configuration
│   ├── config.conf     # Main compositor config & keybindings
│   ├── autostart.sh    # Startup daemons (awww, cliphist, portals)
│   └── wallpaper/      # Default wallpapers
├── install.sh          # Idempotent symlink installer script
└── README.md
```

## Installation
Run the installer to link configurations to `~/.config`:
```bash
git clone https://github.com/vinj026/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

## Keybindings Reference
| Key Combination | Action |
| :--- | :--- |
| `Super` + `Return` | Open Kitty terminal |
| `Super` + `Q` / `Alt` + `Q` | Close active window (`killclient`) |
| `Super` + `F` | Toggle fullscreen |
| `Super` + `V` | Toggle floating mode |
| `Super` + `M` | Toggle maximize mode |
| `Super` + `S` | Toggle scratchpad |
| `Super` + `Tab` | Focus next window |
| `Super` + `Arrow` / `h/j/k/l` | Focus window in direction |
| `Super` + `Shift` + `Arrow` / `h/j/k/l` | Swap/exchange window |
| `Super` + `Ctrl` + `Arrow` / `h/j/k/l` | Resize window |
| `Super` + `1-9` | Switch to workspace / tag 1-9 |
| `Super` + `Shift` + `1-9` | Move window to tag 1-9 |
| `Super` + `Alt` + `Left/Right` | Focus monitor |
| `Print` / `Super` + `Shift` + `S` | Snip area screenshot to clipboard |
| `Super` + `Shift` + `R` | Reload Mango configuration |
| `Super` + `Shift` + `E` | Quit Mango compositor |
