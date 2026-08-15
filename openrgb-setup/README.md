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
| `openrgb-lock-hook.sh` | Listens for screen lock/unlock via D-Bus. Turns all devices (including the motherboard) off on lock, restores the saved profile on unlock |
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

5. **Set up devices and colors once in the OpenRGB GUI**, then save a profile
   named `Static Orange Razer All` (or update `openrgb-lock-hook.sh` if you use
   a different name). This is the profile restored on unlock.

6. **Enable the SDK server** inside OpenRGB (SDK Server tab) — required for the
   lock hook to talk to the running instance.

7. Reboot and verify: OpenRGB starts minimized → locking the screen (Win+L) turns
   all five devices off, including the motherboard → unlocking restores the saved
   profile.

## Notes

- The Kraken V3 HyperSense doesn't support the `Static` mode, only `Direct`,
  `Breathing`, and `Wave` — so it's turned off using `--mode direct`, same as
  the mouse, mousepad, and motherboard. The Huntsman V2 keyboard uses
  `--mode static`, since `direct` alone left the top row (Esc, F1–F12,
  Print/Scroll/Pause, media keys) still lit on that device.
- Loading a saved `.orp` profile via CLI is a known-flaky upstream feature —
  make sure the profile name in the script matches the saved profile exactly
  (case-sensitive), or the unlock step silently fails with "Profile failed to
  load".
- Motherboard RGB staying lit during S3 suspend is a BIOS setting, not something
  this script controls — check Advanced → AURA / Onboard Devices in your BIOS
  if you want it to turn off on suspend too.
- An earlier version of this setup used a custom Python script
  (`openrgb-python`) to drive a synced rainbow-cycle animation across devices,
  since OpenRGB's built-in Effects tab config isn't saved in profiles and can't
  be triggered from the CLI. That approach was dropped in favor of this simpler
  static-color version.
