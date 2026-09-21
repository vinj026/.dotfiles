#!/usr/bin/env bash
# Fix for Lenovo IdeaPad Gaming 3 (ALC257) Headphone / External Speaker Jack
# Root cause:
# 1. BIOS incorrectly marks Pin 0x21 (Headphone Jack) as 0x411111f0 [N/A].
# 2. Hardware jack sensor on ALC257 reports "unplugged" (values=off) even when plugged in.
#    When switching to Headphones in UI, WirePlumber sees "not available" and kicks audio to HDMI sink!
# 3. Adding "[hint] jack_detect = no" tells ALSA to disable hardware jack sensing,
#    making Headphones permanently [available] so WirePlumber never redirects to HDMI.

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "[-] Skrip ini memerlukan akses root (sudo)."
    echo "    Silakan jalankan: sudo bash $0"
    exit 1
fi

REAL_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "vin")}"
REAL_UID="$(id -u "$REAL_USER" 2>/dev/null || echo 1000)"

echo "[1/4] Menulis patch firmware /lib/firmware/hda-jack-retask.fw..."
cat << 'FIRMWARE_EOF' > /lib/firmware/hda-jack-retask.fw
[codec]
0x10ec0257 0 0

[pincfg]
0x21 0x02211020

[hint]
jack_detect = no
FIRMWARE_EOF
chmod 644 /lib/firmware/hda-jack-retask.fw

echo "[2/4] Memastikan konfigurasi modprobe di /etc/modprobe.d/hda-jack-retask.conf..."
cat << 'MODPROBE_EOF' > /etc/modprobe.d/hda-jack-retask.conf
# Pin override configuration for Realtek ALC257 headphone jack detection
# Card 1 = Ryzen HD Audio Controller
options snd-hda-intel patch=,hda-jack-retask.fw
MODPROBE_EOF
chmod 644 /etc/modprobe.d/hda-jack-retask.conf

echo "[3/4] Menghentikan sementara audio server untuk live reconfig..."
sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$REAL_UID" systemctl --user stop wireplumber.service pipewire.socket pipewire.service 2>/dev/null || true
fuser -k -9 /dev/snd/* 2>/dev/null || true
sleep 1

HW_CARD=""
if [ -d /sys/class/sound/hwC1D0 ]; then
    HW_CARD="/sys/class/sound/hwC1D0"
elif [ -d /sys/class/sound/hwC0D0 ]; then
    HW_CARD="/sys/class/sound/hwC0D0"
fi

RECONFIG_SUCCESS=0
if [ -n "$HW_CARD" ]; then
    echo "jack_detect = no" > "$HW_CARD/hints" 2>/dev/null || true
    echo "0x21 0x02211020" > "$HW_CARD/user_pin_configs" 2>/dev/null || true
    if echo 1 > "$HW_CARD/reconfig" 2>/dev/null; then
        echo "[+] Codec $HW_CARD berhasil di-reconfig secara live!"
        RECONFIG_SUCCESS=1
    else
        echo "[!] Live reconfig ditolak driver (sedang dikunci kernel)."
    fi
fi

echo "[4/4] Menyalakan kembali PipeWire & WirePlumber..."
sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$REAL_UID" systemctl --user start pipewire.socket pipewire.service wireplumber.service 2>/dev/null || true
sleep 2

# Unmute ALSA channels
amixer -c 1 sset Master 100% unmute 2>/dev/null || true
amixer -c 1 sset Headphone 100% unmute 2>/dev/null || true
amixer -c 1 sset Speaker 100% unmute 2>/dev/null || true
amixer -c 1 sset "Auto-Mute Mode" Disabled 2>/dev/null || true

# Set default sink ke Ryzen HD Audio Analog Stereo (bukan HDMI monitor)
sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$REAL_UID" pactl set-default-sink alsa_output.pci-0000_05_00.6.analog-stereo 2>/dev/null || true

echo "---------------------------------------------------------"
if [ "$RECONFIG_SUCCESS" -eq 1 ]; then
    echo "[✓] SUKSES! Headphone jack dan speaker aktif tanpa terlempar ke HDMI."
else
    echo "[✓] File patch firmware & modprobe telah BERHASIL DIPERBAIKI."
    echo "    Silakan RESTART / REBOOT laptop kamu:"
    echo "    $ reboot"
    echo "    Setelah reboot, jack 3.5mm akan aktif permanen dan tidak akan lari ke HDMI."
fi
echo "---------------------------------------------------------"
