#!/bin/bash

gdbus monitor -y -d org.freedesktop.login1 | while read -r line; do
    if echo "$line" | grep -q "LockedHint': <true>"; then
        ~/.local/bin/OpenRGB.AppImage --device "ASUS ROG STRIX B850-A GAMING WIFI" --mode direct --color 000000
        ~/.local/bin/OpenRGB.AppImage --device "Razer Kraken V3 HyperSense" --mode direct --color 000000
        ~/.local/bin/OpenRGB.AppImage --device "Razer Basilisk V3" --mode direct --color 000000
        ~/.local/bin/OpenRGB.AppImage --device "Razer Goliathus Extended" --mode direct --color 000000
        ~/.local/bin/OpenRGB.AppImage --device "Razer Huntsman V2" --mode static --color 000000
    elif echo "$line" | grep -q "LockedHint': <false>"; then
        ~/.local/bin/OpenRGB.AppImage --profile "Static Orange Razer All"
    fi
done
