#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ID="io.github.pxllbt.gpu-screen-recorder"
OLD_PLUGIN_IDS=("thirdparty.gpu-screen-recorder" "io.github.pixllbeat.gpu-screen-recorder")
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== GPU Screen Recorder — Omarchy Plugin Installer ==="
echo

if [ ! -f /etc/arch-release ]; then
  echo "Error: This plugin only supports Arch-based systems with Omarchy."
  exit 1
fi

echo "[1/5] Checking dependencies..."
if ! command -v gpu-screen-recorder >/dev/null 2>&1; then
  echo "Installing gpu-screen-recorder from official repos..."
  sudo pacman -S --needed --noconfirm gpu-screen-recorder
else
  echo "gpu-screen-recorder already installed."
fi

if ! command -v gpu-screen-recorder-gtk >/dev/null 2>&1; then
  echo "Installing gpu-screen-recorder-gtk from AUR..."
  if command -v yay >/dev/null 2>&1; then
    yay -S --noconfirm gpu-screen-recorder-gtk
  elif command -v paru >/dev/null 2>&1; then
    paru -S --noconfirm gpu-screen-recorder-gtk
  else
    echo "Warning: No AUR helper found (yay or paru)."
    echo "The recorder itself will still work; only the GTK settings GUI needs this:"
    echo "  yay -S gpu-screen-recorder-gtk"
    echo "or"
    echo "  paru -S gpu-screen-recorder-gtk"
  fi
else
  echo "gpu-screen-recorder-gtk already installed."
fi

echo
echo "[2/5] Removing any previous install of this plugin..."
for old_id in "${OLD_PLUGIN_IDS[@]}"; do
  old_dir="$HOME/.config/omarchy/plugins/$old_id"
  if [ -d "$old_dir" ]; then
    echo "Found legacy plugin at $old_dir — removing (renamed to $PLUGIN_ID)."
    if command -v omarchy >/dev/null 2>&1; then
      omarchy plugin disable "$old_id" 2>/dev/null || true
    fi
    rm -rf "$old_dir"
  fi
done
if [ -d "$PLUGIN_DIR" ]; then
  echo "Updating existing install at $PLUGIN_DIR."
  rm -rf "$PLUGIN_DIR"
fi

echo
echo "[3/5] Installing plugin files..."
mkdir -p "$PLUGIN_DIR"
cp "$SCRIPT_DIR/BarWidget.qml" "$PLUGIN_DIR/"
cp "$SCRIPT_DIR/manifest.json" "$PLUGIN_DIR/"

if command -v omarchy >/dev/null 2>&1; then
  if omarchy plugin validate "$PLUGIN_DIR" 2>&1; then
    echo "Manifest validated."
  else
    echo "Warning: plugin validation reported an issue (see above). Continuing anyway."
  fi
fi

echo
echo "[4/5] Registering the plugin with the running shell..."
if command -v omarchy-shell >/dev/null 2>&1; then
  # A shell that was already running before these files existed needs an
  # explicit rescan before it knows about the new plugin id.
  omarchy-shell shell rescanPlugins 2>/dev/null || true
  sleep 1
fi
if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin enable "$PLUGIN_ID" --section right 2>&1 || \
    echo "Warning: could not auto-enable. Enable manually with:
  omarchy-shell shell rescanPlugins
  omarchy plugin enable $PLUGIN_ID --section right"
else
  echo "Warning: omarchy CLI not found. Enable manually once Omarchy is set up:"
  echo "  omarchy plugin enable $PLUGIN_ID --section right"
fi

echo
echo "[5/5] Restarting shell..."
if command -v omarchy >/dev/null 2>&1; then
  omarchy restart shell 2>/dev/null || true
else
  echo "Please restart Omarchy manually to load the plugin."
fi

echo
echo "Installation complete!"
echo "Usage:"
echo "  Left-click   - Start/stop recording (uses your GTK settings)"
echo "  Middle-click - Open the GTK GUI to change settings"
