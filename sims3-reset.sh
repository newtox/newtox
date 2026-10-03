#!/usr/bin/env bash
# The Sims 3 (Steam/Proton) – reset the Proton prefix and restore saved Sims
#
# Fixes a broken Sims 3 prefix (e.g. after adding/removing expansion packs,
# which leaves stale registry entries behind). Backs up all user data first,
# rebuilds the prefix, then restores .sim files, game settings and mods.
#
# Usage: chmod +x sims3-reset.sh && ./sims3-reset.sh

set -uo pipefail

# ===== Settings =====
APPID=47890
LIBRARY="/run/media/justin/73296a0c-de83-4ea3-8fa3-e7387b2bb03d/SteamLibrary"
SIMS_SOURCE="/run/media/justin/B4BADFC8BADF8570/Backup Daten/Sims"
# ====================

PREFIX="$LIBRARY/steamapps/compatdata/$APPID"
EA_DOCS="$PREFIX/pfx/drive_c/users/steamuser/Documents/Electronic Arts"
BACKUP=~/Sims3_Backup_$(date +%Y-%m-%d_%H-%M)

ok()   { echo -e "\e[32m✔ $*\e[0m"; }
info() { echo -e "\e[36m→ $*\e[0m"; }
err()  { echo -e "\e[31m✘ $*\e[0m"; }

# Safety check so we never delete the wrong folder
if [[ "$PREFIX" != *"/steamapps/compatdata/$APPID" ]]; then
    err "Prefix path looks wrong: $PREFIX"; exit 1
fi
if [[ ! -d "$SIMS_SOURCE" ]]; then
    err "Sims folder not found: $SIMS_SOURCE (is the drive mounted?)"; exit 1
fi

echo "Sims 3 prefix reset"
echo "  Prefix:      $PREFIX"
echo "  Sims source: $SIMS_SOURCE"
read -rp "Continue? [y/N] " a
[[ "$a" =~ ^[yY]$ ]] || { echo "Aborted."; exit 0; }

# 1. Stop Steam and Wine
info "Stopping Steam and Wine processes …"
if pgrep -x steam >/dev/null; then
    steam -shutdown >/dev/null 2>&1
    for _ in {1..20}; do pgrep -x steam >/dev/null || break; sleep 1; done
fi
pkill wineserver 2>/dev/null
sleep 2
ok "Stopped"

# 2. Backup
if [[ -d "$EA_DOCS" ]]; then
    info "Backing up saves/Sims/mods/settings to $BACKUP …"
    cp -r "$EA_DOCS" "$BACKUP" || { err "Backup failed – aborting, nothing was deleted."; exit 1; }
    ok "Backed up"
else
    info "No user folder in prefix, skipping backup"
fi

# 3. Delete prefix
if [[ -d "$PREFIX" ]]; then
    rm -rf "$PREFIX" && ok "Prefix deleted"
else
    info "Prefix did not exist"
fi

# 4. Start Steam, optionally validate files, launch the game
info "Starting Steam …"
setsid steam >/dev/null 2>&1 &
sleep 15

read -rp "Validate game files (recommended after changing packs)? [Y/n] " v
if [[ ! "$v" =~ ^[nN]$ ]]; then
    xdg-open "steam://validate/$APPID" >/dev/null 2>&1
    read -rp "Wait until Steam has finished validating, then press Enter … "
fi

info "Launching Sims 3 – let it reach the main menu, then quit the game."
xdg-open "steam://rungameid/$APPID" >/dev/null 2>&1
read -rp "Press Enter once the game has reached the main menu and is closed again … "

# 5. Find the Sims 3 user folder (name depends on game language)
S3=$(find "$EA_DOCS" -maxdepth 1 -type d -name "*Sims 3" 2>/dev/null | head -n1)
if [[ -z "$S3" ]]; then
    S3="$EA_DOCS/Die Sims 3"
    info "No Sims 3 folder found, creating $S3"
fi

# 6. Copy Sims
mkdir -p "$S3/SavedSims"
shopt -s nullglob nocaseglob
SIMS=("$SIMS_SOURCE"/*.sim)
shopt -u nullglob nocaseglob
if (( ${#SIMS[@]} == 0 )); then
    err "No .sim files found in $SIMS_SOURCE"
else
    cp "${SIMS[@]}" "$S3/SavedSims/" && ok "Copied ${#SIMS[@]} Sim(s) to SavedSims:"
    ls "$S3/SavedSims"
fi

# 7. Restore game settings (volume, graphics, camera …) from backup
if [[ -d "$BACKUP" ]]; then
    OPTS=$(find "$BACKUP" -maxdepth 2 -type f -iname "Options.ini" | head -n1)
    if [[ -n "$OPTS" ]]; then
        cp "$OPTS" "$S3/Options.ini" && ok "Game settings (Options.ini) restored"
    fi
fi

# 8. Optionally restore mods from backup
if [[ -d "$BACKUP" ]]; then
    MODS=$(find "$BACKUP" -maxdepth 2 -type d -name Mods | head -n1)
    if [[ -n "$MODS" ]]; then
        read -rp "Restore Mods folder from backup? [y/N] " m
        if [[ "$m" =~ ^[yY]$ ]]; then
            cp -r "$MODS" "$S3/" && ok "Mods restored"
        fi
    fi
fi

echo
ok "Done! Launch Sims 3 via Steam → Create a Sim → load saved Sims."
[[ -d "$BACKUP" ]] && echo "  Backup is located at: $BACKUP"