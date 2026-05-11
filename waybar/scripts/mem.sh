#!/usr/bin/env bash

free -b | awk '/Mem:/ {
    used=$3;
    total=$2;
    printf "%d%% / %.0fG", used / total * 100, total / 1024 / 1024 / 1024
}'
