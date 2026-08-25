# OpenRGB Setup Scripts

Personal automation scripts for running OpenRGB on Linux (Nobara/Fedora, KDE Plasma
Wayland) without manual startup, with all devices turning off automatically on
screen lock.

## Hardware

- ASUS ROG STRIX B850-A GAMING WIFI (Aura Mainboard + Addressable headers)
- Razer Basilisk V3
- Razer Kraken V3 HyperSense
- Razer Goliathus Extended
- Razer Huntsman V2

## Files

| File | Purpose |
|---|---|
| `openrgb.desktop` | Autostart entry for OpenRGB itself (minimized, forced to run via XWayland with the SDK server auto-started — see Notes) |
| `openrgb-lock-hook.desktop` | Autostart entry for the lock-hook script |
| `openrgb-lock-hook.sh` | Listens for screen lock/unlock via D-Bus. Sets every device (including the motherboard) to a static orange directly, and turns everything off on lock |
| `61-openrgb-kraken-v3.rules` | Extra udev rule for the Razer Kraken V3 HyperSense (missing from OpenRGB's official 0.9 udev rules) |

## Runtime layout

This repo is a backup/source copy only. The actual autostart setup lives locally:

| What | Where |
|---|---|
| OpenRGB AppImage | `~/.local/bin/OpenRGB.AppImage` |
| Lock-hook script | `~/.local/bin/openrgb-lock-hook.sh` |
| Icon | `~/.local/share/icons/openrgb.png` |
| Autostart entries | `~/.config/autostart/*.desktop` |

Keeping scripts under `~/.local/` (not on the external drive this repo lives on)
means the autostart setup keeps working even if the external drive isn't mounted
at login.

## Setup on a fresh install

1. **Download OpenRGB AppImage** to `~/.local/bin/OpenRGB.AppImage`:
```bash
   mkdir -p ~/.local/bin
   chmod +x ~/.local/bin/OpenRGB.AppImage
```

2. **Install udev rules** (required for non-root USB device access):
```bash
   wget https://openrgb.org/releases/release_0.9/60-openrgb.rules
   sudo mv 60-openrgb.rules /usr/lib/udev/rules.d/
   sudo cp 61-openrgb-kraken-v3.rules /etc/udev/rules.d/
   sudo udevadm control --reload-rules
   sudo udevadm trigger
```
   Reconnect USB devices (or reboot) afterwards.

3. **Extract and install the icon:**
```bash
   mkdir -p ~/.local/share/icons
   cd /tmp
   ~/.local/bin/OpenRGB.AppImage --appimage-extract
   cp squashfs-root/org.openrgb.OpenRGB.png ~/.local/share/icons/openrgb.png
   rm -rf squashfs-root
```

4. **Copy the lock-hook script and desktop entries.** Edit hardcoded paths
   (`/home/justin/...`) in the `.desktop` files and `openrgb-lock-hook.sh` first
   if the username/home differs.
```bash
   cp openrgb-lock-hook.sh ~/.local/bin/
   chmod +x ~/.local/bin/openrgb-lock-hook.sh

   cp openrgb.desktop openrgb-lock-hook.desktop ~/.local/share/applications/
   cp openrgb.desktop openrgb-lock-hook.desktop ~/.config/autostart/

   kbuildsycoca6 --noincremental
```

5. Reboot and verify: OpenRGB starts minimized with its SDK server already
   active → after ~5s (the lock hook's startup delay) all devices turn
   orange → locking the screen (Win+L) turns all five off, including the
   motherboard → unlocking turns them back to orange. No manual steps needed.

## Notes

- OpenRGB (Qt5, no bundled Wayland platform plugin) is started with
  `QT_QPA_PLATFORM=xcb --server`. `QT_QPA_PLATFORM=xcb` forces it through
  XWayland — without it, it races XWayland's lazy startup on login and can
  silently fail to open a window or SDK server (still shows up in `pgrep`,
  but every CLI call then spawns broken standalone instances instead of
  connecting). `--server` auto-starts the SDK server on launch, so it
  doesn't need to be enabled manually in the GUI after every reboot.
- Devices turn off/on one at a time rather than perfectly in sync, since
  each is a separate sequential CLI invocation (each one reconnects to the
  server from scratch). Noticeable but fast enough to not matter in practice.
- The Kraken V3 HyperSense doesn't support the `Static` mode, only `Direct`,
  `Breathing`, and `Wave` — so it (and the mainboard) use `--mode direct`. The
  Huntsman V2 keyboard and Goliathus Extended mousepad use `--mode static`,
  since `direct` alone intermittently left parts of them unlit or the wrong
  color (keyboard top row, mousepad zones) when set via CLI.
- No `.orp` profile is used. Loading a saved profile via OpenRGB's CLI turned
  out to be unreliable, so the script sets each device's color directly
  instead.
- Motherboard RGB staying lit during S3 suspend is a BIOS setting, not
  something this script controls — check Advanced → AURA / Onboard Devices
  in your BIOS if you want it to turn off on suspend too.
- Monitors not powering off on screen lock (Win+L) is a known, long-standing
  NVIDIA + KWin + Wayland DPMS bug, unrelated to this setup. No fix applied —
  screen locking itself still works fine, just without the monitor turning off.
