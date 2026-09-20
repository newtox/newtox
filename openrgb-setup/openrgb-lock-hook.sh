#!/bin/bash

LIGHT_BLUE="3dadda"

turn_off() {
    ~/.local/bin/OpenRGB.AppImage --device "ASUS ROG STRIX B850-A GAMING WIFI" --mode direct --color 000000
    ~/.local/bin/OpenRGB.AppImage --device "Razer Kraken V3 HyperSense" --mode direct --color 000000
    ~/.local/bin/OpenRGB.AppImage --device "Razer Basilisk V3" --mode direct --color 000000
    ~/.local/bin/OpenRGB.AppImage --device "Razer Goliathus Extended" --mode direct --color 000000
    ~/.local/bin/OpenRGB.AppImage --device "Razer Huntsman V2" --mode static --color 000000
}

turn_light_blue() {
    ~/.local/bin/OpenRGB.AppImage --device "ASUS ROG STRIX B850-A GAMING WIFI" --mode direct --color $LIGHT_BLUE
    ~/.local/bin/OpenRGB.AppImage --device "Razer Kraken V3 HyperSense" --mode direct --color $LIGHT_BLUE
    ~/.local/bin/OpenRGB.AppImage --device "Razer Basilisk V3" --mode static --color $LIGHT_BLUE
    ~/.local/bin/OpenRGB.AppImage --device "Razer Goliathus Extended" --mode static --color $LIGHT_BLUE
    ~/.local/bin/OpenRGB.AppImage --device "Razer Huntsman V2" --mode static --color $LIGHT_BLUE
}

sleep 10
turn_light_blue

gdbus monitor -y -d org.freedesktop.login1 | while read -r line; do
    if echo "$line" | grep -q "LockedHint': <true>"; then
        turn_off
    elif echo "$line" | grep -q "LockedHint': <false>"; then
        turn_light_blue
    fi
done
