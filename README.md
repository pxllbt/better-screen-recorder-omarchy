# GPU Screen Recorder — Omarchy Plugin

Omarchy bar widget for [gpu-screen-recorder](https://git.dec05eba.com/gpu-screen-recorder/) with dynamic GTK settings sync and GPU auto-detection.

## Features

- **Dynamic GTK sync**: reads `~/.config/gpu-screen-recorder/config` on every recording start (and every 5s), so changes made in the GTK GUI are picked up automatically
- **GPU auto-detection**: enumerates `/dev/dri/card*` devices; on single-GPU systems it omits `-gpu`; on multi-GPU systems it prefers discrete GPUs (NVIDIA/AMD/virtio-gpu)
- **Wayland & X11 aware**: validates the configured capture source against the live list (`--list-capture-options`) before passing `-w`, so it works whether the GTK config stores a Wayland monitor connector name (e.g. `HDMI-A-1`) or an X11 source — stale/mismatched values fall back to fullscreen instead of erroring
- **Middle-click GTK GUI**: opens `gpu-screen-recorder-gtk` for visual settings (optional — if it isn't installed the widget stays functional, just dimmed)
- **Never overlaps other bar widgets**: built on the shell's own `WidgetButton`, so its width always matches its label instead of a fixed icon slot
- **External-session aware**: if another `gpu-screen-recorder` process is already running, the widget disables new recordings instead of disappearing, so the bar layout never reflows
- **Automatic dependency install**: `install.sh` installs `gpu-screen-recorder` (official repos) and `gpu-screen-recorder-gtk` (AUR)

## Requirements

- Arch-based Linux with [Omarchy](https://omarchy.org/)
- Hyprland / Wayland session
- `yay` or `paru` for AUR package installation (optional — only needed for the GTK settings GUI)

## Install

```sh
omarchy plugin add https://github.com/pxllbt/better-screen-recorder-omarchy.git --enable
```

Installing via `omarchy plugin add` keeps the plugin as a git checkout, so you
can update it (or enable automatic updates) with:

```sh
omarchy plugin update io.github.pxllbt.gpu-screen-recorder
```

## Usage

| Action | Result |
|--------|--------|
| Left-click bar widget | Start / stop recording |
| Middle-click bar widget | Open GTK GUI |
| Change settings in GTK GUI | Automatically used on next recording start |

## How it works

The widget reads `~/.config/gpu-screen-recorder/config` every 5 seconds and when recording starts. The path is configurable via the plugin's `gtkConfigPath` setting.

It maps GTK keys to CLI flags:

| GTK key | CLI flag |
|---------|----------|
| `main.record_area_option` | `-w` (only if it is a valid live capture source) |
| `main.record_area_width` + `main.record_area_height` | `-s WxH` |
| `main.quality` | `-q` |
| `main.audio_input` | `-a` |
| `main.fps` | `-f` |
| `main.codec` (not `auto`) | `-k` |
| `main.audio_codec` | `-ac` |
| `main.record_cursor true` | `-cursor yes` |
| `record.container` | `-c` |
| `record.save_directory` | output path |

GPU detection runs at startup. If multiple GPUs are found, it selects the first discrete GPU (NVIDIA `10de`, AMD `1002`, virtio-gpu `1af4`); on a single-GPU system `-gpu` is omitted entirely.

## Compatibility

The widget is designed to behave correctly on a range of Omarchy setups without configuration:

- **GPU configs**: single-GPU systems omit `-gpu` (gpu-screen-recorder picks the default encoder); multi-GPU systems prefer a discrete NVIDIA/AMD/virtio GPU. Systems without a supported hardware encoder fall back to whatever encoder the installed `gpu-screen-recorder` supports.
- **Sessions (Wayland & X11)**: the capture source is validated against the live `--list-capture-options` before `-w` is used. A stored option that is stale, renamed, or session-mismatched is ignored and the widget falls back to fullscreen rather than failing the recording.
- **Optional GTK GUI**: if `gpu-screen-recorder-gtk` isn't installed middle-click is disabled and the widget renders dimmed — recording from left-click still works. No AUR helper? Same graceful behaviour; only the settings GUI is unavailable.
- **Own-probe isolation**: the widget never mistakes its own introspection calls (`--list-audio-devices`, `--list-capture-options`) for an external recording session, so it won't spuriously show "BUSY" on any setup.
- **Audio handling**: if the configured audio device can't be resolved on the current system, `-a` is omitted rather than passed an invalid value.

## Files

```
better-screen-recorder-omarchy/
├── BarWidget.qml      # Main bar widget
├── manifest.json      # Plugin metadata
├── install.sh         # Dependency installation + plugin setup
├── uninstall.sh       # Remove plugin files and disable
└── LICENSE            # MIT license
```

## Uninstall

```bash
./uninstall.sh
```

## Notes

- Omarchy also ships a built-in "Screen Recording" bar indicator. It's independent of this plugin and safe to keep enabled alongside it.
- Plugin id uses namespaced format to match Omarchy conventions and avoid collisions.

## License

MIT
