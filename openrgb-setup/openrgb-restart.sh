#!/bin/bash

pkill -f OpenRGB.AppImage
pkill -f openrgb-lock-hook.sh
sleep 1

QT_QPA_PLATFORM=xcb ~/.local/bin/OpenRGB.AppImage --server > /dev/null 2>&1 &
disown
sleep 3

~/.local/bin/openrgb-lock-hook.sh > /dev/null 2>&1 &
disown

notify-send "OpenRGB" "Script has been restarted." 2>/dev/null
