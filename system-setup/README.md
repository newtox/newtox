# System Setup

Backup and restore scripts for my Nobara (KDE Plasma) install. `backup.sh` snapshots
installed packages and a few configs, `restore.sh` puts everything back on a fresh
install.

The backup data itself is not part of this repo. It is written to
`/run/media/justin/B4BADFC8BADF8570/Backup Daten/system-backup`, a separate drive
that survives a reinstall. Set `BACKUP_DIR` to use another location:

```bash
BACKUP_DIR=/path/to/backup ./backup.sh
BACKUP_DIR=/path/to/backup ./restore.sh
```

## What gets saved

| What | File in the backup folder |
|---|---|
| User-installed dnf packages | `dnf-packages.txt` |
| COPR repo files | `repos/*.repo` |
| Flatpak apps | `flatpaks.txt` |
| KDE color scheme, icon theme and cursor | `kde-look.txt` |
| Dotfiles listed in `dotfiles.txt` | `dotfiles/` |

`dotfiles.txt` covers bash, fastfetch, Konsole, the Plasma panel layout and global
shortcuts. Add or remove paths there, one per line, relative to `$HOME`.

## Backup

```bash
./backup.sh
```

Re-run it after bigger changes to the system. Only the files listed above are
replaced, anything else in the backup folder is left alone.

## Automatic backup every 30 days

```bash
./install-timer.sh
```

Installs a systemd user timer that runs `auto-backup.sh` once a day (and 15 minutes
after login). It only creates a backup if the last one is older than 30 days and
the backup drive is mounted, so a switched-off PC or an unmounted drive never makes
it skip a backup for a whole month. A desktop notification shows up when a backup
was made. A manual `./backup.sh` also resets the 30 days.

```bash
systemctl --user list-timers system-backup.timer
journalctl --user -u system-backup.service
./install-timer.sh --remove
```

Use `BACKUP_INTERVAL_DAYS` in `auto-backup.sh` to change the interval.

## Restore on a fresh install

Make sure the backup drive is mounted (open it once in Dolphin), then:

```bash
git clone https://github.com/newtox/newtox.git
cd newtox/system-setup
./restore.sh
```

Every step asks first:

1. Missing COPR repos are added
2. dnf packages are installed (unavailable ones are skipped)
3. Flatpak apps are installed
4. Dotfiles are restored, existing files are moved to `~/.restore-backup-<date>/`
5. Papirus-Dark icons with Breeze-blue folders are installed
6. The saved KDE color scheme, icon theme and cursor are applied
7. OpenRGB udev rules are set up (the AppImage itself still has to be downloaded,
   see [`openrgb-setup`](../openrgb-setup))

Log out and back in afterwards so KDE loads the restored settings.
