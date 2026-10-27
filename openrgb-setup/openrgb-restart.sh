#!/bin/bash

pkill -f openrgb-lock-hook.sh
pkill -f OpenRGB.AppImage
fuser -k 6742/tcp > /dev/null 2>&1
sleep 2

QT_QPA_PLATFORM=xcb ~/.local/bin/OpenRGB.AppImage --server > /dev/null 2>&1 &
disown
sleep 3

~/.local/bin/openrgb-lock-hook.sh > /dev/null 2>&1 &
disown

notify-send "OpenRGB" "Script has been restarted." 2>/dev/null
