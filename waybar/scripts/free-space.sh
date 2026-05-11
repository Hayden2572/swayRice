#!/usr/bin/env bash

path="${1:-/}"

df -h --output=avail "$path" 2>/dev/null | awk 'NR==2 { gsub(/ /, "", $1); print $1 }'
