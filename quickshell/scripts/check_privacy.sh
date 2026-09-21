#!/bin/bash
st=$(wpctl status 2>/dev/null)

# 1. Microphone check (WirePlumber active capture stream or PulseAudio source-output)
m=$(echo "$st" | awk '/Audio/,/Video/' | grep -E '<\s.*\[active\]')
if [ -z "$m" ]; then
    m=$(pactl list source-outputs short 2>/dev/null)
fi

# 2. Camera check (direct V4L2 device usage by browser/apps, or PipeWire video stream)
c=$(fuser /dev/video* 2>/dev/null)
if [ -z "$c" ]; then
    c=$(echo "$st" | awk '/Video/,/Settings/' | grep -E '\[active\]')
fi
if [ -z "$c" ]; then
    c=$(pw-cli dump Node 2>/dev/null | grep -E -B2 -A10 'media\.role = "Camera"|media\.class = "Video/Source"' | grep 'state: "running"')
fi

echo "${m:+mic}:${c:+cam}"
