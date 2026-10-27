# Terminal Setup

Dark and orange Konsole + fastfetch setup, matched to the orange RGB lighting
from [`openrgb-setup`](../openrgb-setup). Background and text colors are inspired
by the [DoA Darker](https://github.com/ImScheinox/doa) TeamSpeak theme.

## Colors

| Role | Color |
|---|---|
| Accent (Safety Orange) | `#ff6700` |
| Accent (dark) | `#e05a00` |
| Background | `#121314` |
| Background (intense) | `#0d0e0f` |
| Text | `#dcddde` |
| Secondary text | `#b9bbbe` |

The RGB hardware uses `#ff3200` instead: LEDs render green much brighter than
monitors, so a lower green value is needed for the same orange look.

## Files

| File | Purpose |
|---|---|
| `fastfetch/config.jsonc` | fastfetch layout: orange Nobara logo, framed System / Desktop / Hardware sections, usage bars for RAM and swap |
| `konsole/NTX-Orange.colorscheme` | Konsole color scheme with a near-black background and orange as the yellow/accent color |
| `bashrc-prompt.sh` | Orange bash prompt |

## Setup

```bash
mkdir -p ~/.config/fastfetch ~/.local/share/konsole
cp fastfetch/config.jsonc ~/.config/fastfetch/config.jsonc
cp konsole/NTX-Orange.colorscheme ~/.local/share/konsole/
cat bashrc-prompt.sh >> ~/.bashrc
```

Then in Konsole: *Settings → Edit Current Profile → Appearance → NTX-Orange*.
