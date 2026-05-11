#!/usr/bin/env bash

idx="${1:-1}"

mapfile -t mounts < <(
    findmnt -rn -o TARGET,SOURCE,FSTYPE |
    awk '
        $2 ~ "^/dev/" &&
        $3 !~ /tmpfs|devtmpfs|squashfs|overlay|proc|sysfs|cgroup|bpf|tracefs|securityfs|pstore|debugfs|mqueue|hugetlbfs|fusectl/ &&
        $1 !~ "^/boot" {
            print $1
        }
    ' |
    awk '!seen[$0]++'
)

target="${mounts[$((idx-1))]}"

[ -n "$target" ] || exit 1

df -h --output=avail "$target" 2>/dev/null | awk 'NR==2 { gsub(/ /, "", $1); print $1 }'
