# GPU Screen Recorder — Omarchy Plugin

Omarchy bar widget for [gpu-screen-recorder](https://git.dec05eba.com/gpu-screen-recorder/) with dynamic GTK settings sync and GPU auto-detection.

Created and maintained by [**pixllbeat**](https://github.com/pixllbeat). See [Credits](#credits) below.

## Features

- **Dynamic GTK sync**: reads `~/.config/gpu-screen-recorder/config` on every recording start (and every 5s), so changes made in the GTK GUI are picked up automatically
- **GPU auto-detection**: enumerates `/dev/dri/card*` devices; on single-GPU systems it omits `-gpu`; on multi-GPU systems it prefers discrete GPUs (NVIDIA/AMD/virtio-gpu)
- **Wayland-friendly**: uses monitor connector names from GTK config (e.g. `HDMI-A-1`) instead of X11 window IDs
- **Middle-click GTK GUI**: opens `gpu-screen-recorder-gtk` for visual settings
- **Never overlaps other bar widgets**: built on the shell's own `WidgetButton`, so its width always matches its label instead of a fixed icon slot — see [How it works](#how-it-works)
- **External-session aware**: if another `gpu-screen-recorder` process is already running (started from the GTK app or a terminal), the widget disables new recordings instead of disappearing, so the bar layout never reflows
- **Automatic dependency install**: `install.sh` installs `gpu-screen-recorder` (official repos) and `gpu-screen-recorder-gtk` (AUR)

## Requirements

- Arch-based Linux with [Omarchy](https://omarchy.org/)
- Hyprland / Wayland session
- `yay` or `paru` for AUR package installation (optional — only needed for the GTK settings GUI)

## Installation

```bash
git clone https://github.com/pixllbeat/gpu-screen-recorder-omarchy.git
cd gpu-screen-recorder-omarchy
./install.sh
```

The installer will:
1. Install `gpu-screen-recorder` from official repos via `pacman`
2. Install `gpu-screen-recorder-gtk` from AUR via `yay` or `paru` (best-effort)
3. Remove any previous install of this plugin (including the legacy `thirdparty.gpu-screen-recorder` id)
4. Copy plugin files to `~/.config/omarchy/plugins/io.github.pixllbeat.gpu-screen-recorder/`
5. Validate the manifest with `omarchy plugin validate`
6. Enable the plugin on the right side of the bar
7. Restart the Omarchy shell

Works alongside any bar layout, including third-party full-bar replacements (e.g. Shibumi) and any number of other active bar widgets/plugins — the widget only ever claims the width its own label needs.

## Usage

| Action | Result |
|--------|--------|
| Left-click bar widget | Start / stop recording |
| Middle-click bar widget | Open GTK GUI |
| Change settings in GTK GUI | Automatically used on next recording start |

## How it works

The widget reads `~/.config/gpu-screen-recorder/config` every 5 seconds and when recording starts. The path is configurable via the plugin's `gtkConfigPath` setting (defaults to the path above) — set it from Omarchy's plugin settings panel, or directly in `~/.config/omarchy/shell.json`'s bar layout entry for this widget.

It maps GTK keys to CLI flags:

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

GPU detection runs at startup. If multiple GPUs are found, it selects the first discrete GPU (NVIDIA `10de`, AMD `1002`, virtio-gpu `1af4`); on a single-GPU system `-gpu` is omitted entirely. The detected GPU index is passed as `-gpu <index>`.

**Widget sizing:** Omarchy's shell packs bar widgets using each widget's reported `implicitWidth`. Icon-style widgets built on `BarIconButton` reserve a fixed single-glyph slot, which clips or bleeds multi-character labels ("REC"/"STOP") into neighboring widgets once a bar section is crowded. This widget is built on the shell's plain `WidgetButton` instead, whose `implicitWidth` always matches the rendered label — so it reports its real size to the bar layout and can never overlap a neighbor, no matter how many other plugins (first- or third-party) are active or which full bar you use.

## Files

```
gpu-screen-recorder-omarchy/
├── BarWidget.qml      # Main bar widget: WidgetButton UI, GTK config reader, GPU detection
├── manifest.json      # Plugin metadata (namespaced id, settings schema)
├── install.sh         # Dependency installation + plugin setup
├── uninstall.sh        # Remove plugin files and disable
└── LICENSE            # MIT license
```

## Uninstall

```bash
./uninstall.sh
```

## Notes

- `gpu-screen-recorder --help` does not accept `-w focused` on Wayland. Use a monitor connector name like `-w HDMI-A-1`.
- The GTK config `main.codec auto` is not a valid CLI value; it is omitted so the recorder defaults to `h264`.
- The GTK config `main.video_bitrate` is ignored because `-q` (quality) controls bitrate in the CLI.
- Middle-click behavior requires `gpu-screen-recorder-gtk` to remain installed. Uninstalling it disables the GTK launch (recording itself still works).
- Plugin id changed from `thirdparty.gpu-screen-recorder` to the namespaced `io.github.pixllbeat.gpu-screen-recorder` to match Omarchy's plugin-id conventions and avoid collisions with other authors. `install.sh`/`uninstall.sh` clean up the old id automatically.
- Omarchy also ships a built-in "Screen Recording" bar indicator (`omarchy-capture-screenrecording`) that shows/toggles a generic `gpu-screen-recorder` session. It's independent of this plugin and safe to keep enabled alongside it — this widget adds GTK-settings sync, GPU auto-detection, and its own start/stop control, so you may prefer to disable the built-in indicator to avoid two recording icons on the bar (`omarchy plugin list` to find its id, then `omarchy plugin disable <id>`).

## Credits

This plugin is © pixllbeat, licensed under [MIT](LICENSE). MIT is intentionally permissive — you're welcome to fork, modify, and reuse this code — but it requires keeping the copyright notice and license text with any copy or substantial portion of the software you redistribute (see `LICENSE` and the header comment in `BarWidget.qml`).

If you build something from this project, a credit/link back to [github.com/pixllbeat/gpu-screen-recorder-omarchy](https://github.com/pixllbeat/gpu-screen-recorder-omarchy) in your README or about screen is appreciated (and, per the license, required if you keep substantial parts of the code).
