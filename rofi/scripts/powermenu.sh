#!/bin/bash

# ======== CONFIG ========
rofi_cmd() {
  rofi -dmenu \
    -i \
    -p "Power Menu" \
    -theme ~/.config/rofi/powermenu.rasi
}

# ======== OPTIONS ========
shutdown=" Shutdown"
reboot=" Reboot"
lock=" Lock"
suspend=" Suspend"
logout=" Logout"

options="$shutdown\n$reboot\n$lock\n$suspend\n$logout"

chosen="$(echo -e "$options" | rofi_cmd)"

# ======== ACTIONS ========
case $chosen in
"$shutdown")
  systemctl poweroff
  ;;
"$reboot")
  systemctl reboot
  ;;
"$lock")
  # Sesuaikan dengan locker yang lo pakai
  swaylock || i3lock
  ;;
"$suspend")
  systemctl suspend
  ;;
"$logout")
  labwc-ctl exit
  ;;
esac
