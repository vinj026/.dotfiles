source /usr/share/cachyos-zsh-config/cachyos-config.zsh

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"


# Added by Antigravity CLI installer
export PATH="/home/vin/.local/bin:$PATH"
