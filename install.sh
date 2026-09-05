#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="thirdparty.gpu-screen-recorder"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_NAME"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== GPU Screen Recorder Omarchy Plugin Installer ==="
echo

if [ ! -f /etc/arch-release ]; then
  echo "Error: This plugin only supports Arch-based systems with Omarchy."
  exit 1
fi

echo "[1/4] Checking dependencies..."
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
    echo "Please install gpu-screen-recorder-gtk manually:"
    echo "  yay -S gpu-screen-recorder-gtk"
    echo "or"
    echo "  paru -S gpu-screen-recorder-gtk"
    exit 1
  fi
else
  echo "gpu-screen-recorder-gtk already installed."
fi

echo
echo "[2/4] Installing plugin files..."
mkdir -p "$PLUGIN_DIR"
cp "$SCRIPT_DIR/BarWidget.qml" "$PLUGIN_DIR/"
cp "$SCRIPT_DIR/manifest.json" "$PLUGIN_DIR/"
cp "$SCRIPT_DIR/config.json" "$PLUGIN_DIR/"

echo
echo "[3/4] Enabling plugin..."
if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin enable "$PLUGIN_NAME" right 2>/dev/null || true
else
  echo "Warning: omarchy CLI not found. Please enable the plugin manually:"
  echo "  omarchy plugin enable $PLUGIN_NAME right"
fi

echo
echo "[4/4] Restarting shell..."
if command -v omarchy >/dev/null 2>&1; then
  omarchy restart shell 2>/dev/null || true
else
  echo "Please restart Omarchy manually to load the plugin."
fi

echo
echo "Installation complete!"
echo "Usage:"
echo "  Left-click  - Start/stop recording (uses GTK settings)"
echo "  Middle-click - Open GTK GUI to change settings"
