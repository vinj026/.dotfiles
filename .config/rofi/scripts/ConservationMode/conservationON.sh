#!/bin/bash
echo '1' > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
notify-send "Conservation Mode" "Conservation mode telah diaktifkan."