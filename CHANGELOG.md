# Changelog

All notable changes to this plugin are documented in this file.

The version scheme follows the plugin manifest `version` field.

## [1.3.4] — 2026-09-08

### Added
- Periodic refresh of the live audio-device and capture-source maps (every 5 s), so a USB mic plugged in or a monitor added mid-session is picked up without a shell restart.
- Region capture now uses the modern non-deprecated `-w WxH+X+Y` geometry syntax, learned from live verification against `gpu-screen-recorder` 6.x (the old `-region` flag is deprecated upstream).

## [1.3.3] — 2026-09-08

### Fixed
- Process-match patterns were anchored on a leading `/`, so PATH-launched recorder instances (cmdline `gpu-screen-recorder -w …`) were neither detected as busy sessions nor stopped. Patterns are now anchored on start-of-line **or** slash.
- Verified live: stopping a recording signals only the recorder core and never interrupts `gpu-screen-recorder-gtk`.

## [1.3.2] — 2026-09-08

### Added
- The widget re-checks for `gpu-screen-recorder-gtk` every 5 s, so installing it after the shell started un-dims the widget and enables middle-click settings without a restart.

## [1.3.1] — 2026-09-08

### Fixed
- `-w` is now always emitted, with a safe `screen` fallback, so a recording never fails when the GTK config has no capture area (regression from `gpu-screen-recorder` 6.x requiring `-w`).
- Session detection no longer mistakes the widget's own introspection probes (`--list-audio-devices`, `--list-capture-options`, `--help`, `--version`) for an external session (false "BUSY").
- Stopping a recording no longer signals the GTK settings app (the core name is matched to a word boundary).
- Audio fallback drops `-a` instead of passing an invalid friendly device name that `gpu-screen-recorder` rejects.
- Capture-source validation was hardened for Wayland **and** X11 setups: stored sources that are stale or session-mismatched fall back to fullscreen.

## [1.3.0] — 2026-09-08

### Added
- Audio device support: `main.audio_input` is resolved from the friendly name in the GTK config to the real PipeWire node.
- GPU auto-detection across `/dev/dri/card*`.
- Dynamic 5 s GTK config sync.

## Initial release

- First bar widget for Omarchy wrapping `gpu-screen-recorder`.