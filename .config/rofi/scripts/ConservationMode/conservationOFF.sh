#!/bin/bash
echo '0' > /sys/bus/platform/drivers/ideapad_acpi/VPC2004:00/conservation_mode
notify-send "Rapid Charge" "Rapid Charge mode telah diaktifkan."