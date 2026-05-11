#!/usr/bin/env bash

# Prefer hwmon thermal zones
for f in /sys/class/thermal/thermal_zone*/temp; do
    [ -r "$f" ] || continue
    raw="$(cat "$f" 2>/dev/null)"
    [ -n "$raw" ] || continue

    # sane CPU-like range: 20C-100C
    if [ "$raw" -gt 20000 ] && [ "$raw" -lt 100000 ]; then
        awk -v t="$raw" 'BEGIN { printf "%.1f", t / 1000 }'
        exit 0
    fi
done

# Fallback via sensors
if command -v sensors >/dev/null 2>&1; then
    sensors | awk '/Package id 0|Tctl|CPU/ {
        gsub(/\+|°C/, "", $4);
        printf "%.1f", $4;
        exit
    }'
    exit 0
fi

echo "n/a"
