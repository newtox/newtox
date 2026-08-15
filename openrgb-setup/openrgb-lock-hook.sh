#!/bin/bash

ORANGE="ff8000"

turn_off() {
    ~/.local/bin/OpenRGB.AppImage --device "ASUS ROG STRIX B850-A GAMING WIFI" --mode direct --color 000000
    ~/.local/bin/OpenRGB.AppImage --device "Razer Kraken V3 HyperSense" --mode direct --color 000000
    ~/.local/bin/OpenRGB.AppImage --device "Razer Basilisk V3" --mode direct --color 000000
    ~/.local/bin/OpenRGB.AppImage --device "Razer Goliathus Extended" --mode direct --color 000000
    ~/.local/bin/OpenRGB.AppImage --device "Razer Huntsman V2" --mode static --color 000000
}

turn_orange() {
    ~/.local/bin/OpenRGB.AppImage --device "ASUS ROG STRIX B850-A GAMING WIFI" --mode direct --color $ORANGE
    ~/.local/bin/OpenRGB.AppImage --device "Razer Kraken V3 HyperSense" --mode direct --color $ORANGE
    ~/.local/bin/OpenRGB.AppImage --device "Razer Basilisk V3" --mode static --color $ORANGE
    ~/.local/bin/OpenRGB.AppImage --device "Razer Goliathus Extended" --mode static --color $ORANGE
    ~/.local/bin/OpenRGB.AppImage --device "Razer Huntsman V2" --mode static --color $ORANGE
}

sleep 3
turn_orange

gdbus monitor -y -d org.freedesktop.login1 | while read -r line; do
    if echo "$line" | grep -q "LockedHint': <true>"; then
        turn_off
    elif echo "$line" | grep -q "LockedHint': <false>"; then
        turn_orange
    fi
done
