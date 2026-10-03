#!/usr/bin/env bash
#
# sims3-reset.sh – Back up, reset and restore The Sims 3 (Steam/Proton)
#
# Adding or removing expansion packs in the Steam version of The Sims 3 leaves
# stale registry entries in the Proton prefix, which stops the game from
# launching. This script backs up your user data, deletes and rebuilds the
# prefix, and then restores your saved Sims, game settings and mods.
#
# Usage:
#   ./sims3-reset.sh              Full reset: backup → delete prefix → rebuild → restore
#   ./sims3-reset.sh -b           Only create a backup
#   ./sims3-reset.sh -r           Only restore from the newest backup
#   ./sims3-reset.sh -r -f DIR    Only restore from a specific backup folder
#   ./sims3-reset.sh -h           Show help
#
# What gets backed up / restored:
#   - Backup:  the whole "Documents/Electronic Arts" folder of the prefix
#              (saves, SavedSims, Mods, Options.ini) → ~/Sims3_Backup_<date>
#   - Restore: all .sim files from SIMS_SOURCE into SavedSims,
#              Options.ini (volume, graphics, camera …) and the Mods folder
#
# Not included: EA/launcher logins (not needed – Steam handles ownership).
#
# Requirements: Steam (native), Sims 3 set to run with Proton.
# Adjust the paths in the "Settings" section below before the first run.

set -uo pipefail

# ===== Settings =====
APPID=47890
LIBRARY="/run/media/justin/73296a0c-de83-4ea3-8fa3-e7387b2bb03d/SteamLibrary"
SIMS_SOURCE="/run/media/justin/B4BADFC8BADF8570/Backup Daten/Sims"
BACKUP_ROOT=~
# ====================

PREFIX="$LIBRARY/steamapps/compatdata/$APPID"
EA_DOCS="$PREFIX/pfx/drive_c/users/steamuser/Documents/Electronic Arts"
GAME_PROC="TS3W.exe|TS3.exe"

MODE="full"
RESTORE_FROM=""
BACKUP=""

ok()   { echo -e "\e[32m✔ $*\e[0m"; }
info() { echo -e "\e[36m→ $*\e[0m"; }
err()  { echo -e "\e[31m✘ $*\e[0m"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") [option]

  (no option)       Full reset: backup → delete prefix → rebuild → restore
  -b, --backup      Only create a backup
  -r, --restore     Only restore Sims, settings and mods (newest backup)
  -f, --from DIR    Backup folder to restore from (use with -r)
  -h, --help        Show this help
EOF
}

confirm() {   # confirm "question" default(y/n)
    local a
    if [[ "${2:-n}" == "y" ]]; then read -rp "$1 [Y/n] " a; [[ ! "$a" =~ ^[nN]$ ]]
    else                            read -rp "$1 [y/N] " a; [[ "$a" =~ ^[yY]$ ]]; fi
}

game_running() { pgrep -fi "$GAME_PROC" >/dev/null; }

# ===== Arguments =====
while (( $# )); do
    case "$1" in
        -b|--backup)  MODE="backup" ;;
        -r|--restore) MODE="restore" ;;
        -f|--from)    shift; RESTORE_FROM="${1:-}" ;;
        -h|--help)    usage; exit 0 ;;
        *) err "Unknown option: $1"; usage; exit 1 ;;
    esac
    shift
done

# Safety check so we never delete the wrong folder
[[ "$PREFIX" == *"/steamapps/compatdata/$APPID" ]] || { err "Prefix path looks wrong: $PREFIX"; exit 1; }

# ===== Steps =====
do_backup() {
    [[ -d "$EA_DOCS" ]] || { info "No user folder in prefix, nothing to back up"; return 0; }
    BACKUP="$BACKUP_ROOT/Sims3_Backup_$(date +%Y-%m-%d_%H-%M-%S)"
    info "Backing up to $BACKUP …"
    cp -r "$EA_DOCS" "$BACKUP" || { err "Backup failed"; return 1; }
    ok "Backed up"
}

do_restore() {   # do_restore BACKUP_DIR
    local from="$1" S3

    # Sims 3 user folder (name depends on game language)
    S3=$(find "$EA_DOCS" -maxdepth 1 -type d -name "*Sims 3" 2>/dev/null | head -n1)
    [[ -n "$S3" ]] || S3="$EA_DOCS/Die Sims 3"
    mkdir -p "$S3/SavedSims"

    # Sims
    if [[ -d "$SIMS_SOURCE" ]]; then
        shopt -s nullglob nocaseglob
        local sims=("$SIMS_SOURCE"/*.sim)
        shopt -u nullglob nocaseglob
        if (( ${#sims[@]} )); then
            cp "${sims[@]}" "$S3/SavedSims/" && ok "Copied ${#sims[@]} Sim(s) to SavedSims"
        else
            err "No .sim files found in $SIMS_SOURCE"
        fi
    else
        err "Sims folder not found: $SIMS_SOURCE (is the drive mounted?)"
    fi

    [[ -n "$from" && -d "$from" ]] || { info "No backup found to restore settings/mods from"; return 0; }
    info "Restoring from $from"

    # Settings (volume, graphics, camera …)
    local opts mods
    opts=$(find "$from" -maxdepth 2 -type f -iname "Options.ini" | head -n1)
    [[ -n "$opts" ]] && cp "$opts" "$S3/Options.ini" && ok "Settings (Options.ini) restored"

    # Mods
    mods=$(find "$from" -maxdepth 2 -type d -name Mods | head -n1)
    if [[ -n "$mods" ]] && confirm "Restore Mods folder?" y; then
        mkdir -p "$S3/Mods" && cp -r "$mods/." "$S3/Mods/" && ok "Mods restored"
    fi
}

full_reset() {
    echo "Sims 3 full reset"
    echo "  Prefix:      $PREFIX"
    echo "  Sims source: $SIMS_SOURCE"
    confirm "Continue?" n || { echo "Aborted."; exit 0; }

    info "Stopping Steam and Wine …"
    if pgrep -x steam >/dev/null; then
        steam -shutdown >/dev/null 2>&1
        for _ in {1..20}; do pgrep -x steam >/dev/null || break; sleep 1; done
    fi
    pkill wineserver 2>/dev/null; sleep 2

    do_backup || { err "Aborting, nothing was deleted."; exit 1; }
    rm -rf "$PREFIX" && ok "Prefix deleted"

    info "Starting Steam …"
    setsid steam >/dev/null 2>&1 &
    sleep 15

    if confirm "Validate game files (recommended after changing packs)?" y; then
        xdg-open "steam://validate/$APPID" >/dev/null 2>&1
        read -rp "Press Enter once Steam has finished validating … "
    fi

    info "Launching Sims 3 – let it reach the main menu, then quit the game."
    xdg-open "steam://rungameid/$APPID" >/dev/null 2>&1
    read -rp "Press Enter once the game is closed again … "

    do_restore "$BACKUP"
}

# ===== Run =====
case "$MODE" in
    backup)
        game_running && { err "Sims 3 is running – close it first."; exit 1; }
        do_backup || exit 1
        ;;
    restore)
        game_running && { err "Sims 3 is running – close it first."; exit 1; }
        [[ -d "$EA_DOCS" ]] || { err "Prefix has no user folder yet – launch Sims 3 once first."; exit 1; }
        if [[ -n "$RESTORE_FROM" && ! -d "$RESTORE_FROM" ]]; then
            err "Backup folder not found: $RESTORE_FROM"; exit 1
        fi
        do_restore "${RESTORE_FROM:-$(ls -d "$BACKUP_ROOT"/Sims3_Backup_* 2>/dev/null | sort | tail -n1)}"
        ;;
    full)
        full_reset
        ;;
esac

echo
ok "Done!"
if [[ -n "$BACKUP" ]]; then echo "  Backup: $BACKUP"; fi
exit 0