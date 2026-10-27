#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${BACKUP_DIR:-/run/media/justin/B4BADFC8BADF8570/Backup Daten/system-backup}"

say() { printf '\033[1;38;2;255;103;0m==>\033[0m %s\n' "$*"; }

if [[ ! -d "$(dirname "$OUT")" ]]; then
    say "$(dirname "$OUT") not found. Is the drive mounted?"
    exit 1
fi

mkdir -p "$OUT"
rm -rf "$OUT/dotfiles" "$OUT/repos" "$OUT/dnf-packages.txt" "$OUT/flatpaks.txt" "$OUT/kde-look.txt"
mkdir -p "$OUT/dotfiles"

if command -v dnf >/dev/null; then
    dnf repoquery --userinstalled --queryformat '%{name}\n' 2>/dev/null | sed '/^$/d' | sort -u > "$OUT/dnf-packages.txt"
    say "dnf: $(wc -l < "$OUT/dnf-packages.txt") packages"

    shopt -s nullglob
    copr=(/etc/yum.repos.d/_copr*.repo)
    shopt -u nullglob
    if (( ${#copr[@]} )); then
        mkdir -p "$OUT/repos"
        cp "${copr[@]}" "$OUT/repos/"
        say "COPR repos: ${#copr[@]}"
    fi
fi

if command -v flatpak >/dev/null; then
    flatpak list --app --columns=origin,application > "$OUT/flatpaks.txt"
    say "Flatpak: $(wc -l < "$OUT/flatpaks.txt") apps"
fi

if command -v kreadconfig6 >/dev/null; then
    {
        echo "ColorScheme=$(kreadconfig6 --file kdeglobals --group General --key ColorScheme)"
        echo "IconTheme=$(kreadconfig6 --file kdeglobals --group Icons --key Theme)"
        echo "CursorTheme=$(kreadconfig6 --file kcminputrc --group Mouse --key cursorTheme)"
    } > "$OUT/kde-look.txt"
    say "KDE look: $(paste -sd ' ' "$OUT/kde-look.txt")"
fi

while IFS= read -r path || [[ -n "$path" ]]; do
    [[ -z "$path" || ! -e "$HOME/$path" ]] && continue
    mkdir -p "$OUT/dotfiles/$(dirname "$path")"
    cp -a "$HOME/$path" "$OUT/dotfiles/$path"
done < "$DIR/dotfiles.txt"
say "Dotfiles: $(find "$OUT/dotfiles" -type f | wc -l) files"

say "Backup written to $OUT"
