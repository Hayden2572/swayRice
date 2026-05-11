#!/usr/bin/env bash

if ! command -v bluetoothctl >/dev/null 2>&1; then
    echo "bt n/a"
    exit 0
fi

powered="$(bluetoothctl show 2>/dev/null | awk -F': ' '/Powered/ {print $2}')"

if [ "$powered" != "yes" ]; then
    echo "bt off"
    exit 0
fi

connected="$(bluetoothctl devices Connected 2>/dev/null | sed 's/^Device //')"

if [ -n "$connected" ]; then
    name="$(echo "$connected" | cut -d' ' -f2- | head -n1)"
    echo "bt $name"
else
    echo "bt on"
fi
