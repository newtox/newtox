#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="${BACKUP_DIR:-/run/media/justin/B4BADFC8BADF8570/Backup Daten/system-backup}"
DAYS="${BACKUP_INTERVAL_DAYS:-30}"
STAMP="$OUT/dnf-packages.txt"

if [[ ! -d "$(dirname "$OUT")" ]]; then
    echo "Backup drive not mounted, skipping."
    exit 0
fi

if [[ -f "$STAMP" ]]; then
    age_days=$(( ($(date +%s) - $(stat -c %Y "$STAMP")) / 86400 ))
    if (( age_days < DAYS )); then
        echo "Last backup is $age_days days old, next one in $(( DAYS - age_days )) days."
        exit 0
    fi
fi

BACKUP_DIR="$OUT" "$DIR/backup.sh"
notify-send -i drive-harddisk "System-Backup" "Backup erstellt: $OUT" 2>/dev/null || true
