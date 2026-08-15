# OpenRGB Setup Scripts

Personal automation scripts for running OpenRGB on Linux (Nobara/Fedora, KDE Plasma)
without manual startup, with all devices turning off automatically on screen lock.

## Hardware

- ASUS ROG STRIX B850-A GAMING WIFI (Aura Mainboard + Addressable headers)
- Razer Basilisk V3
- Razer Kraken V3 HyperSense
- Razer Goliathus Extended
- Razer Huntsman V2

## Files

| File | Purpose |
|---|---|
| `openrgb.desktop` | Autostart entry for OpenRGB itself (minimized) |
| `openrgb-lock-hook.desktop` | Autostart entry for the lock-hook script |
| `openrgb-lock-hook.sh` | Listens for screen lock/unlock via D-Bus. Sets every device to a static orange directly (on script start, and on unlock), and turns everything off on lock |
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

5. **Enable the SDK server** inside OpenRGB (SDK Server tab) — required for the
   lock hook to talk to the running instance.

6. Reboot and verify: OpenRGB starts minimized → after ~5s all devices turn
   orange → locking the screen (Win+L) turns all five off, including the
   motherboard → unlocking turns them back to orange.

## Notes

- No `.orp` profile is used. Loading a saved profile via OpenRGB's CLI turned
  out to be unreliable (see below), so `openrgb-lock-hook.sh` sets each
  device's color directly with `--device`/`--mode`/`--color` instead — both on
  script start and on unlock.
- The Kraken V3 HyperSense doesn't support the `Static` mode, only `Direct`,
  `Breathing`, and `Wave` — so it (and the mainboard) use `--mode direct`. The
  Huntsman V2 keyboard and Goliathus Extended mousepad use `--mode static`,
  since `direct` alone intermittently left parts of them unlit or the wrong
  color (keyboard top row, mousepad zones) when set via CLI.
- The script waits 5 seconds after starting before setting colors, to give
  OpenRGB time to fully start and its SDK server to become reachable (both
  launch from autostart at roughly the same time).
- Motherboard RGB staying lit during S3 suspend is a BIOS setting, not something
  this script controls — check Advanced → AURA / Onboard Devices in your BIOS
  if you want it to turn off on suspend too.
- An earlier version of this setup used a custom Python script
  (`openrgb-python`) to drive a synced rainbow-cycle animation across devices,
  since OpenRGB's built-in Effects tab config isn't saved in profiles and can't
  be triggered from the CLI. That approach was dropped in favor of this simpler
  static-color version.
