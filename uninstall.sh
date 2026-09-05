#!/usr/bin/env bash
set -euo pipefail

PLUGIN_NAME="thirdparty.gpu-screen-recorder"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_NAME"

echo "=== GPU Screen Recorder Omarchy Plugin Uninstaller ==="
echo

if [ ! -d "$PLUGIN_DIR" ]; then
  echo "Plugin directory not found at $PLUGIN_DIR"
  exit 0
fi

echo "[1/3] Disabling plugin..."
if command -v omarchy >/dev/null 2>&1; then
  omarchy plugin disable "$PLUGIN_NAME" 2>/dev/null || true
fi

echo
echo "[2/3] Removing plugin files..."
rm -rf "$PLUGIN_DIR"

echo
echo "[3/3] Restarting shell..."
if command -v omarchy >/dev/null 2>&1; then
  omarchy restart shell 2>/dev/null || true
else
  echo "Please restart Omarchy manually."
fi

echo
echo "Uninstall complete."
