# GPU Screen Recorder — Omarchy Plugin

Omarchy bar widget for [gpu-screen-recorder](https://git.dec05eba.com/gpu-screen-recorder/) with dynamic GTK settings sync and GPU auto-detection.

## Features

- **Dynamic GTK sync**: reads `~/.config/gpu-screen-recorder/config` on every recording start, so changes made in the GTK GUI are picked up automatically
- **GPU auto-detection**: detects available `/dev/dri/card*` devices; on single-GPU systems it omits `-gpu`; on multi-GPU systems it prefers discrete GPUs (NVIDIA/AMD)
- **Wayland-friendly**: uses monitor connector names from GTK config (e.g. `HDMI-A-1`) instead of X11 window IDs
- **Middle-click GTK GUI**: opens `gpu-screen-recorder-gtk` for visual settings
- **Automatic dependency install**: `install.sh` installs `gpu-screen-recorder` (official repos) and `gpu-screen-recorder-gtk` (AUR)

## Requirements

- Arch-based Linux with [Omarchy](https://omarchy.org/)
- Hyprland / Wayland session
- `yay` or `paru` for AUR package installation

## Installation

```bash
git clone https://github.com/<your-user>/gpu-screen-recorder-omarchy.git
cd gpu-screen-recorder-omarchy
./install.sh
```

The installer will:
1. Install `gpu-screen-recorder` from official repos via `pacman`
2. Install `gpu-screen-recorder-gtk` from AUR via `yay` or `paru`
3. Copy plugin files to `~/.config/omarchy/plugins/thirdparty.gpu-screen-recorder/`
4. Enable the plugin on the right side of the bar
5. Restart the Omarchy shell

## Usage

| Action | Result |
|--------|--------|
| Left-click bar widget | Start / stop recording |
| Middle-click bar widget | Open GTK GUI |
| Change settings in GTK GUI | Automatically used on next recording start |

## How it works

The widget reads `~/.config/gpu-screen-recorder/config` every 5 seconds and when recording starts. It maps GTK keys to CLI flags:

| GTK key | CLI flag |
|---------|----------|
| `main.record_area_option` | `-w` |
| `main.record_area_width` + `main.record_area_height` | `-s WxH` |
| `main.quality` | `-q` |
| `main.audio_input` | `-a` |
| `main.fps` | `-f` |
| `main.codec` (not `auto`) | `-k` |
| `main.audio_codec` | `-ac` |
| `main.record_cursor true` | `-cursor yes` |
| `record.container` | `-c` |
| `record.save_directory` | output path |

GPU detection runs at startup. If multiple GPUs are found, it selects the first discrete GPU (NVIDIA `10de`, AMD `1002`). The detected GPU index is passed as `-gpu <index>`.

## Files

```
gpu-screen-recorder-omarchy/
├── BarWidget.qml      # Main bar widget with GTK config reader + GPU detection
├── manifest.json      # Plugin metadata
├── config.json        # Plugin config (gtkConfigPath)
├── install.sh         # Dependency installation + plugin setup
└── uninstall.sh       # Remove plugin files and disable
```

## Uninstall

```bash
./uninstall.sh
```

## Notes

- `gpu-screen-recorder --help` does not accept `-w focused` on Wayland. Use a monitor connector name like `-w HDMI-A-1`.
- The GTK config `main.codec auto` is not a valid CLI value; it is omitted so the recorder defaults to `h264`.
- The GTK config `main.video_bitrate` is ignored because `-q` (quality) controls bitrate in the CLI.
- Middle-click behavior requires `gpu-screen-recorder-gtk` to remain installed. Uninstalling it disables the GTK launch.
