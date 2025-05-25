#!/bin/bash

options=(
"conservation 󱉝"
"rapid charge 󰂅"
)
hello_world_simple() {

    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal -- bash -c "echo 'Activating Conservation Mode...'; echo '1' | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode > /dev/null; echo 'Conservation mode telah diaktifkan.'; read -p 'Tekan Enter untuk menutup jendela...'"
    elif command -v xterm &> /dev/null; then
        xterm -e "echo 'Activating Conservation Mode...'; echo '1' | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode > /dev/null; echo 'Conservation mode telah diaktifkan.'; read -p 'Tekan Enter untuk menutup jendela...'"
    elif command -v konsole &> /dev/null; then
        konsole -e bash -c "echo 'Activating Conservation Mode...'; echo '1' | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode > /dev/null; echo 'Conservation mode telah diaktifkan.'; read -p 'Tekan Enter untuk menutup jendela...'"
    elif command -v kitty &> /dev/null; then
        kitty bash -c "echo 'Activating Conservation Mode...'; echo '1' | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode > /dev/null; echo 'Conservation mode telah diaktifkan.'; read -p 'Tekan Enter untuk menutup jendela...'"
    elif command -v alacritty &> /dev/null; then
        alacritty -e bash -c "echo 'Activating Conservation Mode...'; echo '1' | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode > /dev/null; echo 'Conservation mode telah diaktifkan.'; read -p 'Tekan Enter untuk menutup jendela...'"
    else
        notify-send "Error" "Can't find emulator"
        exit 1
    fi
       notify-send "Conservation Mode" "Conservation mode activated"
}

hello_world_color() {
    if command -v gnome-terminal &> /dev/null; then
        gnome-terminal -- bash -c "echo 'Activating Rapid Charge Mode...'; echo '0' | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode > /dev/null; echo 'Rapid charge mode telah diaktifkan.'; read -p 'Tekan Enter untuk menutup jendela...'"
    elif command -v xterm &> /dev/null; then
        xterm -e "echo 'Activating Rapid Charge Mode...'; echo '0' | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode > /dev/null; echo 'Rapid charge mode telah diaktifkan.'; read -p 'Tekan Enter untuk menutup jendela...'"
    elif command -v konsole &> /dev/null; then
        konsole -e bash -c "echo 'Activating Rapid Charge Mode...'; echo '0' | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode > /dev/null; echo 'Rapid charge mode telah diaktifkan.'; read -p 'Tekan Enter untuk menutup jendela...'"
    elif command -v kitty &> /dev/null; then
        kitty bash -c "echo 'Activating Rapid Charge Mode...'; echo '0' | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode > /dev/null; echo 'Rapid charge mode telah diaktifkan.'; read -p 'Tekan Enter untuk menutup jendela...'"
    elif command -v alacritty &> /dev/null; then
        alacritty -e bash -c "echo 'Activating Rapid Charge Mode...'; echo '0' | sudo tee /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode > /dev/null; echo 'Rapid charge mode telah diaktifkan.'; read -p 'Tekan Enter untuk menutup jendela...'"
    else
        notify-send "Error" "Can't find emulator"
        exit 1
    fi
    
    notify-send "Rapid Charge" "Rapid Charge mode activated"
}

temp_file=$(mktemp)
printf '%s\n' "${options[@]}" > "$temp_file"

theme_path="$HOME/.config/rofi/launchers/conservationmode.rasi"
if [ -f "$theme_path" ]; then
    choice=$(rofi -dmenu -theme "$theme_path" -p "Hello World Options:" < "$temp_file")
else
    echo "Custom Theme Not Found"
    choice=$(rofi -dmenu -p "Hello World Options:" < "$temp_file")
fi

rm "$temp_file"

case "$choice" in
    "${options[0]}") # Conservation Mode
        hello_world_simple
        ;;
    "${options[1]}") # Rapid Charge Mode
        hello_world_color
        ;;
esac
