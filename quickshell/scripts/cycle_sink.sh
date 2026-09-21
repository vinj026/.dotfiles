#!/usr/bin/env bash
# ==============================================================================
# CYCLE AUDIO SINK
# Switches the default PipeWire/PulseAudio sink to the next available one.
# Used by the Quickshell ControlCenter (ControlsTab -> Output switcher).
# ==============================================================================
set -euo pipefail

# Extract the "Sinks:" block from wpctl status (stop at the next section header)
mapfile -t LINES < <(wpctl status 2>/dev/null | awk '
    /^[[:space:]]*Sinks:/ { inblock = 1; next }
    inblock && /^[[:space:]]*[A-Za-z][A-Za-z \/&-]*:$/ { inblock = 0 }
    inblock { print }
') || true

if [ "${#LINES[@]}" -le 0 ]; then
    echo "No sinks found" >&2
    exit 0
fi

IDS=()
CURRENT=""
for line in "${LINES[@]}"; do
    id=$(echo "$line" | grep -oE '[0-9]+' | head -n1 || true)
    [ -n "$id" ] || continue
    IDS+=("$id")
    if echo "$line" | grep -q '^\s*\*'; then
        CURRENT="$id"
    fi
done

COUNT=${#IDS[@]}
if [ "$COUNT" -le 1 ]; then
    echo "Only one sink available, nothing to cycle" >&2
    exit 0
fi

NEXT=""
if [ -n "$CURRENT" ]; then
    for i in "${!IDS[@]}"; do
        if [ "${IDS[$i]}" = "$CURRENT" ]; then
            NEXT=${IDS[$(( (i + 1) % COUNT ))]}
            break
        fi
    done
fi
[ -n "$NEXT" ] || NEXT="${IDS[0]}"

wpctl set-default "$NEXT"

SINK_NAME=$(wpctl status 2>/dev/null | awk '
    /^[[:space:]]*Sinks:/ { inblock = 1; next }
    inblock && /^[[:space:]]*[A-Za-z][A-Za-z \/&-]*:$/ { inblock = 0 }
    inblock && $0 ~ "^[[:space:]]*\\*?[[:space:]]*"'"$NEXT"'\\." { sub(/^[^A-Za-z]*/, ""); sub(/ \[vol[^]]*\]/, ""); print; exit }
' | sed "s/^${NEXT}\. *//")

notify-send "Audio Output" "Switched to: ${SINK_NAME:-$NEXT}" 2>/dev/null || true
echo "Switched default sink to $NEXT (${SINK_NAME:-unknown})"