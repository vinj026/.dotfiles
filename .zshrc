# ZSH CONFIGURATION

# Load Instant Prompt for P10k
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# PATH SETTINGS
export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/.local/bin:$PATH"
export XDG_DATA_DIRS="/home/kvn/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:${XDG_DATA_DIRS}"

# THEME SETTINGS
ZSH_THEME="powerlevel10k/powerlevel10k"
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# PLUGINS
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
  sudo
  web-search
  copyfile
  copypath
  dirhistory
  history
)
source $ZSH/oh-my-zsh.sh

# ALIASES
alias mvi="NVIM_APPNAME=nvim-mini nvim"
alias avi="NVIM_APPNAME=astro-nvim nvim"
alias cls="clear"
alias update="sudo apt update && sudo apt upgrade -y"
alias ..="cd .."
alias ...="cd ../.."
alias ll="ls -alh"
alias grep="grep --color=auto"
alias ports="netstat -tulanp"

# CUSTOM FUNCTIONS
mkcd() {
  mkdir -p "$1" && cd "$1"
}

# HISTORY SETTINGS
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# WAYLAND AUTO-START (Hyprland)
if [ -z "${WAYLAND_DISPLAY}" ] && [ "${XDG_VTNR}" -eq 1 ]; then
  exec Hyprland
fi

# PYWAL (Dynamic Colors)
(cat ~/.cache/wal/sequences &)
cat ~/.cache/wal/sequences
source ~/.cache/wal/colors-tty.sh

