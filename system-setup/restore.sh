#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
B="${BACKUP_DIR:-/run/media/justin/B4BADFC8BADF8570/Backup Daten/system-backup}"
OPENRGB_DIR="$DIR/../openrgb-setup"
ICONS_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/icons"
PAPIRUS_COLOR="breeze"

say() { printf '\033[1;38;2;255;103;0m==>\033[0m %s\n' "$*"; }
ask() {
    local answer
    read -r -p "$1 [Y/n] " answer || answer=""
    [[ -z "$answer" || "$answer" =~ ^[YyJj] ]]
}

if [[ ! -d "$B" ]]; then
    say "No backup found at $B. Is the drive mounted? Otherwise run with BACKUP_DIR=/path/to/backup."
    exit 1
fi

restore_repos() {
    local missing=()
    for f in "$B"/repos/*.repo; do
        [[ -e "$f" ]] || continue
        [[ -f "/etc/yum.repos.d/$(basename "$f")" ]] || missing+=("$f")
    done
    if (( ${#missing[@]} == 0 )); then
        say "All repos already present."
        return
    fi
    say "Missing repos:"
    printf '    %s\n' "${missing[@]##*/}"
    if ask "Add them?"; then
        sudo cp "${missing[@]}" /etc/yum.repos.d/
        sudo dnf makecache
    fi
}

restore_dnf() {
    [[ -s "$B/dnf-packages.txt" ]] || return 0
    if ask "Install $(wc -l < "$B/dnf-packages.txt") dnf packages? Already installed ones are skipped."; then
        xargs -a "$B/dnf-packages.txt" sudo dnf install -y --skip-unavailable
    fi
}

restore_flatpak() {
    [[ -s "$B/flatpaks.txt" ]] || return 0
    command -v flatpak >/dev/null || { say "flatpak not installed, skipping."; return; }
    if ask "Install $(wc -l < "$B/flatpaks.txt") Flatpak apps?"; then
        flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        local failed=()
        while IFS=$'\t' read -r origin app; do
            [[ -z "$app" ]] && continue
            flatpak install -y --noninteractive "$origin" "$app" || failed+=("$app ($origin)")
        done < "$B/flatpaks.txt"
        if (( ${#failed[@]} )); then
            say "Could not install:"
            printf '    %s\n' "${failed[@]}"
        fi
    fi
}

restore_dotfiles() {
    [[ -d "$B/dotfiles" ]] || return 0
    if ask "Restore dotfiles (bash, fastfetch, Konsole, panel layout, shortcuts)? Existing files are backed up first."; then
        local safe="$HOME/.restore-backup-$(date +%Y%m%d-%H%M%S)"
        while IFS= read -r path || [[ -n "$path" ]]; do
            [[ -z "$path" || ! -e "$B/dotfiles/$path" ]] && continue
            if [[ -e "$HOME/$path" ]]; then
                mkdir -p "$safe/$(dirname "$path")"
                mv "$HOME/$path" "$safe/$path"
            fi
            mkdir -p "$HOME/$(dirname "$path")"
            cp -a "$B/dotfiles/$path" "$HOME/$path"
            echo "    $path"
        done < "$DIR/dotfiles.txt"
        if [[ -d "$safe" ]]; then say "Previous files saved in $safe"; fi
    fi
}

restore_icons() {
    if [[ -d "$ICONS_DIR/Papirus-Dark" ]]; then
        say "Papirus-Dark already installed."
        return
    fi
    if ask "Install Papirus icons with $PAPIRUS_COLOR folders?"; then
        local tmp
        tmp="$(mktemp -d)"
        mkdir -p "$ICONS_DIR"
        git clone -q --depth 1 https://github.com/PapirusDevelopmentTeam/papirus-icon-theme.git "$tmp/papirus"
        cp -r "$tmp/papirus/Papirus" "$tmp/papirus/Papirus-Dark" "$ICONS_DIR/"
        curl -fsSL https://raw.githubusercontent.com/PapirusDevelopmentTeam/papirus-folders/master/papirus-folders -o "$tmp/papirus-folders"
        USER_HOME="$HOME" bash "$tmp/papirus-folders" -C "$PAPIRUS_COLOR" --theme Papirus-Dark || true
        rm -rf "$tmp"
    fi
}

restore_look() {
    [[ -s "$B/kde-look.txt" ]] || return 0
    local scheme="" icons="" cursor=""
    while IFS='=' read -r key value; do
        case "$key" in
            ColorScheme) scheme="$value" ;;
            IconTheme) icons="$value" ;;
            CursorTheme) cursor="$value" ;;
        esac
    done < "$B/kde-look.txt"
    if ask "Apply KDE look (colors: ${scheme:-default}, icons: ${icons:-default}, cursor: ${cursor:-default})?"; then
        [[ -n "$scheme" ]] && plasma-apply-colorscheme "$scheme" || true
        [[ -n "$cursor" ]] && plasma-apply-cursortheme "$cursor" || true
        if [[ -n "$icons" ]]; then
            if [[ -x /usr/libexec/plasma-changeicons ]]; then
                /usr/libexec/plasma-changeicons "$icons"
            else
                kwriteconfig6 --file kdeglobals --group Icons --key Theme "$icons"
            fi
        fi
    fi
}

restore_openrgb() {
    if ask "Set up OpenRGB udev rules (needs sudo)?"; then
        local tmp
        tmp="$(mktemp -d)"
        if curl -fsSL https://openrgb.org/releases/release_0.9/60-openrgb.rules -o "$tmp/60-openrgb.rules"; then
            sudo cp "$tmp/60-openrgb.rules" /usr/lib/udev/rules.d/
        else
            say "Could not download 60-openrgb.rules, get it manually (see openrgb-setup/README.md)."
        fi
        [[ -f "$OPENRGB_DIR/61-openrgb-kraken-v3.rules" ]] && sudo cp "$OPENRGB_DIR/61-openrgb-kraken-v3.rules" /etc/udev/rules.d/
        sudo udevadm control --reload-rules
        sudo udevadm trigger
        rm -rf "$tmp"
    fi
    if [[ ! -x "$HOME/.local/bin/OpenRGB.AppImage" ]]; then
        say "OpenRGB AppImage missing: download it from https://openrgb.org to ~/.local/bin/OpenRGB.AppImage and chmod +x it."
    fi
    command -v kbuildsycoca6 >/dev/null && kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
}

restore_repos
restore_dnf
restore_flatpak
restore_dotfiles
restore_icons
restore_look
restore_openrgb

say "Done. Log out and back in so KDE picks up the restored settings."
