#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ID="io.github.pxllbt.gpu-screen-recorder"
LEGACY_PLUGIN_IDS=("thirdparty.gpu-screen-recorder" "io.github.pixllbeat.gpu-screen-recorder")
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

echo "=== GPU Screen Recorder — Omarchy Plugin Uninstaller ==="
echo

removed_any=0

for id in "$PLUGIN_ID" "${LEGACY_PLUGIN_IDS[@]}"; do
  dir="$HOME/.config/omarchy/plugins/$id"
  if [ -d "$dir" ]; then
    echo "[1/2] Disabling and removing $id..."
    if command -v omarchy >/dev/null 2>&1; then
      omarchy plugin disable "$id" 2>/dev/null || true
    fi
    rm -rf "$dir"
    removed_any=1
  fi
done

if [ "$removed_any" -eq 0 ]; then
  echo "Plugin directory not found at $PLUGIN_DIR (already uninstalled?)."
  exit 0
fi

echo
echo "[2/2] Restarting shell..."
if command -v omarchy >/dev/null 2>&1; then
  omarchy restart shell 2>/dev/null || true
else
  echo "Please restart Omarchy manually."
fi

echo
echo "Uninstall complete."
