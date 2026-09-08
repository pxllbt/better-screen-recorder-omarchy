# Better Screen Recorder — Omarchy Bar Widget

[![Omarchy plugin](https://img.shields.io/badge/omarchy-plugin-6f42c1)](https://omarchy.org/)
[![Version](https://img.shields.io/badge/version-1.3.4-informational)](https://github.com/pxllbt/better-screen-recorder-omarchy/releases)
[![License](https://img.shields.io/github/license/pxllbt/better-screen-recorder-omarchy)](/LICENSE)
[![Platform](https://img.shields.io/badge/platform-Wayland%20%7C%20X11-1a73e8)](https://git.dec05eba.com/gpu-screen-recorder/)

An Omarchy bar widget for [gpu-screen-recorder](https://git.dec05eba.com/gpu-screen-recorder/) — instant, one-click screen recording with live sync to the GTK settings app and GPU auto-detection. Works on Wayland **and** X11.

## Features

- **Dynamic GTK sync** — reads `~/.config/gpu-screen-recorder/config` when a recording starts and every 5 seconds, so changes made in the GTK GUI are used automatically. The path is configurable via the widget's `gtkConfigPath` setting.
- **GPU auto-detection** — enumerates `/dev/dri/card*`; on single-GPU systems `-gpu` is omitted entirely, on multi-GPU systems the first discrete NVIDIA / AMD / virtio-gpu card is preferred over an integrated one.
- **Session-aware capture** — the configured source is validated against the live `--list-capture-options` before `-w` is passed, so it behaves correctly whether the GTK config stores a Wayland connector name (e.g. `HDMI-A-1`), a window id, or a region geometry. Stale or session-mismatched values fall back to fullscreen instead of failing.
- **Region capture** — records an exact area via the modern `-w WxH+X+Y` geometry syntax (the deprecated `-region` flag is not used).
- **Live device maps** — audio and capture-source lists refresh periodically, so plugging in a USB mic or adding a monitor mid-session is picked up without a shell restart.
- **Self-healing GTK detection** — if `gpu-screen-recorder-gtk` is installed after the shell started, the widget notices within seconds and un-dims instead of staying disabled.
- **External-session aware** — if another recorder instance is already running, the widget disables new recordings instead of disappearing, so the bar layout never reflows.
- **Safe stop** — stopping a recording signals the recorder process only and never interrupts the GTK settings app.
- **Never overlaps other widgets** — built on the shell's own `WidgetButton`, so its width always matches its label instead of a fixed icon slot.

## Requirements

- Arch-based Linux with [Omarchy](https://omarchy.org/)
- Hyprland (Wayland) or an X11 session
- `gpu-screen-recorder` installed (required)
- `gpu-screen-recorder-gtk` from the AUR — optional, for the visual settings GUI (the widget stays fully functional without it, just rendered dimmed)

## Install

```sh
omarchy plugin add https://github.com/pxllbt/better-screen-recorder-omarchy.git --enable
```

Installing via `omarchy plugin add` keeps the plugin as a git checkout, so you can update it (or enable automatic updates) with:

```sh
omarchy plugin update io.github.pxllbt.gpu-screen-recorder
```

The bundled `install.sh` performs the equivalent setup manually and also installs the runtime dependencies (`gpu-screen-recorder` from the official repos, `gpu-screen-recorder-gtk` from the AUR).

## Usage

| Action | Result |
|--------|--------|
| Left-click the widget | Start / stop a recording |
| Middle-click the widget | Open the GTK settings GUI *(requires `gpu-screen-recorder-gtk` installed)* |
| Change settings in the GTK GUI | Applied automatically on the next recording start |

Recordings are saved to the directory configured in the GTK app (`record.save_directory`), named `YYYY-MM-DDTHH-MM-SS.mp4`.

## Configuration

The widget is a thin, stateless adapter: it reads `~/.config/gpu-screen-recorder/config` every 5 seconds and maps GTK keys straight to `gpu-screen-recorder` CLI flags.

| GTK key | CLI flag |
|---------|----------|
| `main.record_area_option` | `-w <source>` — falls back to `screen` if not a valid live source |
| `main.record_area_option = region` | `-w <W>x<H>+<X>+<Y>` (with `main.record_area_width`, `_height`, `_offset_x`, `_offset_y`) |
| `main.record_area_width` + `main.record_area_height` | `-s WxH` (all modes except `region`) |
| `main.quality` | `-q` |
| `main.audio_input` | `-a` (friendly name resolved to its PipeWire node; omitted if unresolvable) |
| `main.fps` | `-f` |
| `main.codec` (not `auto`) | `-k` |
| `main.audio_codec` | `-ac` |
| `main.record_cursor = true` | `-cursor yes` |
| `record.container` | `-c` |
| `record.save_directory` | output path |

## Compatibility

The widget is designed to behave identically across Omarchy setups without any configuration:

- **GPU configs** — single-GPU systems omit `-gpu`; multi-GPU systems prefer a discrete NVIDIA/AMD/virtio GPU. Systems without a supported hardware encoder fall back to whatever the installed `gpu-screen-recorder` supports.
- **Sessions (Wayland & X11)** — `-w` is always emitted. A stored source that is stale, renamed, or session-mismatched falls back to the recorder's `screen` default — a recording never fails because the GTK config didn't set a capture area.
- **Region captures** — use the current non-deprecated `-w WxH+X+Y` geometry syntax, so they keep working with newer `gpu-screen-recorder` releases.
- **Optional GTK GUI** — without `gpu-screen-recorder-gtk` the widget renders dimmed and middle-click is disabled; left-click recording still works. The widget re-checks every 5 seconds, so a later install is honoured without a shell restart.
- **Hot-plug awareness** — audio and capture-source maps refresh every 5 seconds; a USB mic or monitor appearing mid-session is detected on the next recording.
- **Own-probe isolation** — the widget's introspection calls (`--list-audio-devices`, `--list-capture-options`, `--help`) are never mistaken for an external recording session, so it won't spuriously display "BUSY".
- **Audio handling** — if the configured audio device cannot be resolved on the current system, `-a` is omitted rather than passed an invalid value.

## Troubleshooting

- **Recording doesn't start.** Confirm `gpu-screen-recorder` is installed (`which gpu-screen-recorder`). The widget always emits a valid `-w`, so the most common cause is a missing binary.
- **Widget is dimmed / middle-click does nothing.** `gpu-screen-recorder-gtk` isn't installed (or was installed after the shell started — give it up to 5 seconds, or restart the shell with `omarchy restart shell`).
- **It shows "BUSY" with nothing recording.** Another `gpu-screen-recorder` instance is running (GTK app or terminal). Stop it and the widget returns to "REC".
- **The area recorded isn't what I selected.** Region capture needs width, height and offsets set in the GTK app's capture-area settings; if the values are missing the widget falls back to fullscreen.

## Changelog

See [CHANGELOG.md](/CHANGELOG.md) for the full history.

## Credit

Screen recording is powered by [gpu-screen-recorder](https://git.dec05eba.com/gpu-screen-recorder/) by [dec05eba](https://git.dec05eba.com/). This project is an independent Omarchy bar widget and is not affiliated with or endorsed by its author.

## License

MIT — see [LICENSE](/LICENSE).