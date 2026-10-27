#!/usr/bin/env bash
set -euo pipefail

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNIT_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
NAME="system-backup"

if [[ "${1:-}" == "--remove" ]]; then
    systemctl --user disable --now "$NAME.timer" 2>/dev/null || true
    rm -f "$UNIT_DIR/$NAME.service" "$UNIT_DIR/$NAME.timer"
    systemctl --user daemon-reload
    echo "Automatic backup removed."
    exit 0
fi

mkdir -p "$UNIT_DIR"

cat > "$UNIT_DIR/$NAME.service" <<EOF
[Unit]
Description=System backup (every 30 days)
ConditionPathExists=$DIR/auto-backup.sh

[Service]
Type=oneshot
ExecStart=$DIR/auto-backup.sh
EOF

cat > "$UNIT_DIR/$NAME.timer" <<EOF
[Unit]
Description=Daily check whether a system backup is due

[Timer]
OnBootSec=15min
OnUnitActiveSec=1d
Persistent=true

[Install]
WantedBy=timers.target
EOF

chmod +x "$DIR/auto-backup.sh" "$DIR/backup.sh"
systemctl --user daemon-reload
systemctl --user enable --now "$NAME.timer"

echo "Automatic backup installed. Check with:"
echo "    systemctl --user list-timers $NAME.timer"
echo "    journalctl --user -u $NAME.service"
