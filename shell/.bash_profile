#
# ~/.bash_profile
#

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Added by Antigravity CLI installer
export PATH="/home/vin/.local/bin:$PATH"

# Autostart MangoWM on tty1 login
if [[ -z "$WAYLAND_DISPLAY" && "$XDG_VTNR" -eq 1 ]]; then
    exec mango
fi
