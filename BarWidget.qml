// GPU Screen Recorder — Omarchy bar widget
//
// Author:  pixllbeat (https://github.com/pixllbeat)
// Repo:    https://github.com/pixllbeat/better-screen-recorder-omarchy
// License: MIT — see LICENSE. If you fork or reuse this file, please keep
//          this header and credit the original author.
//
// Renders as a plain text WidgetButton (NOT BarIconButton) on purpose:
// BarIconButton reserves a fixed single-glyph icon slot and will clip or
// bleed multi-character labels ("REC"/"STOP") into neighboring widgets once
// a bar section is crowded. WidgetButton sizes implicitWidth/implicitHeight
// to the actual label, which is what lets this widget sit correctly next to
// any number of other first- or third-party bar widgets/bars without
// overlapping or misaligning — see README "How it works" for details.
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "io.github.pixllbeat.gpu-screen-recorder"

  property bool gtkAvailable: true
  property bool sessionActive: false
  property bool recording: false
  property var gtkConfig: ({})
  property int gpuIndex: -1
  readonly property string gtkConfigPath: root.setting("gtkConfigPath", "~/.config/gpu-screen-recorder/config")
  readonly property string homeDir: Quickshell.env("HOME") || ""

  // True when a gpu-screen-recorder process is running that this widget did
  // not start (e.g. launched from the GTK app or a terminal). We disable new
  // recordings in that case instead of hiding the widget, so the bar layout
  // never reflows just because this widget's visibility flickered.
  readonly property bool externalSessionActive: sessionActive && !recording

  // Resolves "~" ourselves (rather than leaning on shell-side $HOME expansion)
  // because every path we build gets single-quoted via shellEscape() before
  // it reaches bash, and single quotes prevent $HOME from expanding there.
  function expandHome(path) {
    var value = String(path || "")
    if (!root.homeDir) return value
    return value.replace(/^~(?=\/|$)/, root.homeDir)
  }

  function shellEscape(str) {
    return "'" + String(str).replace(/'/g, "'\\''") + "'"
  }

  // Detect GPU: if there's a single GPU, omit -gpu entirely (gpu-screen-recorder
  // defaults to it). If there are several, prefer the first discrete GPU
  // (NVIDIA 10de, AMD 1002, virtio-gpu 1af4) over an integrated one.
  Process {
    id: gpuDetectProc
    command: ["bash", "-lc", [
      "shopt -s nullglob",
      "cards=(/dev/dri/card*)",
      "if [ ${#cards[@]} -eq 0 ]; then echo \"none\"; exit 0; fi",
      "if [ ${#cards[@]} -eq 1 ]; then echo \"\"; exit 0; fi",
      "for card_path in \"${cards[@]}\"; do",
      "  card_name=$(basename \"$card_path\")",
      "  card_num=${card_name#card}",
      "  pci_slot=$(cat \"/sys/class/drm/$card_name/device/uevent\" 2>/dev/null | grep PCI_SLOT_NAME | cut -d= -f2)",
      "  if [ -n \"$pci_slot\" ] && command -v lspci >/dev/null 2>&1; then",
      "    lspci_line=$(lspci -n -s \"$pci_slot\" 2>/dev/null | head -1)",
      "    vendor_device=$(echo \"$lspci_line\" | sed -E \"s/^[^ ]+ [0-9a-f]{4}: ([0-9a-f]{4}:[0-9a-f]{4}) .*/\\1/\")",
      "    vendor_id=${vendor_device%%:*}",
      "    if [[ \"$vendor_id\" =~ ^(10de|1002|1af4) ]]; then",
      "      echo \"$card_num\"",
      "      exit 0",
      "    fi",
      "  fi",
      "done",
      "echo \"0\""
    ].join("\n")]
    stdout: StdioCollector {
      onStreamFinished: function() {
        var text = this.text ? this.text.trim() : ""
        if (!text || text === "none") {
          root.gpuIndex = -1
        } else {
          root.gpuIndex = parseInt(text) || 0
        }
      }
    }
  }

  Process {
    id: sessionProc
    command: ["pgrep", "--quiet", "-f", "gpu-screen-recorder( |$)"]
    onExited: function(exitCode) {
      root.sessionActive = exitCode === 0
      if (!root.sessionActive) root.recording = false
    }
  }

  Process {
    id: audioListProc
    command: ["bash", "-lc", "gpu-screen-recorder --list-audio-devices | while IFS='|' read -r node name; do echo \"$name|$node\"; done"]
    onNewOutput: function(output) {
      var lines = String(output).split("\n")
      root.audioDevices = {}
      for (var i = 0; i < lines.length; i++) {
        var line = lines[i].trim()
        if (!line) continue
        var idx = line.indexOf("|")
        if (idx > 0) {
          var friendly = line.substring(0, idx).trim()
          var real = line.substring(idx + 1).trim()
          root.audioDevices[friendly] = real
        }
      }
    }
  }

  // 2s is frequent enough to reflect external start/stop promptly without
  // adding meaningful overhead alongside every other polling plugin on a
  // busy bar.
  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: function() {
      if (!sessionProc.running) sessionProc.running = true
    }
  }

  Process {
    id: gtkCheckProc
    command: ["bash", "-lc", "command -v gpu-screen-recorder-gtk"]
    onExited: function(exitCode) {
      root.gtkAvailable = exitCode === 0
    }
  }

  Component.onCompleted: {
    gtkCheckProc.running = true
    refreshGtkConfig()
    gpuDetectProc.running = true
  }

  Timer {
    interval: 5000
    running: true
    repeat: true
    onTriggered: refreshGtkConfig()
  }

  Process {
    id: configProc
    command: ["bash", "-lc", "f=" + root.shellEscape(root.expandHome(root.gtkConfigPath)) + "; test -f \"$f\" && cat \"$f\" || true"]
    stdout: StdioCollector {
      id: configCollector
      onStreamFinished: function() {
        var text = this.text || ""
        var cfg = {}
        if (text) {
          var lines = text.split("\n")
          for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (!line || line.startsWith("#")) continue
            var idx = line.indexOf(" ")
            if (idx > 0) {
              var key = line.substring(0, idx)
              var value = line.substring(idx + 1)
              cfg[key] = value
            }
          }
        }
        root.gtkConfig = cfg
      }
    }
  }

  function refreshGtkConfig() {
    if (!configProc.running) configProc.running = true
  }

  function getConfigValue(key, fallback) {
    return root.gtkConfig.hasOwnProperty(key) ? root.gtkConfig[key] : fallback
  }

  function buildCliArgs() {
    var args = []

    if (root.gpuIndex >= 0) {
      args.push("-gpu", root.gpuIndex)
    }

    var monitor = getConfigValue("main.record_area_option", "")
    if (monitor) args.push("-w", monitor)

    var width = getConfigValue("main.record_area_width", "")
    var height = getConfigValue("main.record_area_height", "")
    if (width && height) args.push("-s", width + "x" + height)

    var quality = getConfigValue("main.quality", "")
    if (quality) args.push("-q", quality)

    var audioInput = getConfigValue("main.audio_input", "")
    if (audioInput) {
      var device = resolveAudioDevice(audioInput)
      if (device) args.push("-a", device)
    }

    var fps = getConfigValue("main.fps", "")
    if (fps) args.push("-f", fps)

    var codec = getConfigValue("main.codec", "")
    if (codec && codec !== "auto") args.push("-k", codec)

    var audioCodec = getConfigValue("main.audio_codec", "")
    if (audioCodec) args.push("-ac", audioCodec)

    var recordCursor = getConfigValue("main.record_cursor", "")
    if (recordCursor === "true") args.push("-cursor", "yes")

    var container = getConfigValue("record.container", "")
    if (container) args.push("-c", container)

    return args
  }

  function startRecording() {
    if (root.recording || root.externalSessionActive) return
    var now = new Date()
    var stamp = now.toISOString().replace(/[:.]/g, "-").slice(0, 19)
    var saveDir = getConfigValue("record.save_directory", "~/Videos")
    var outputPath = root.expandHome(saveDir) + "/" + stamp + ".mp4"
    var args = buildCliArgs()
    args.push("-o", outputPath)
    var parts = ["gpu-screen-recorder"]
    for (var i = 0; i < args.length; i++) {
      parts.push(root.shellEscape(String(args[i])))
    }
    var cmd = parts.join(" ") + " >/dev/null 2>&1 &"
    Quickshell.execDetached(["bash", "-lc", cmd])
    root.recording = true
  }

  function stopRecording() {
    if (!root.recording) return
    Quickshell.execDetached(["bash", "-lc", "pkill -f 'gpu-screen-recorder( |$)' || true"])
    root.recording = false
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    active: root.recording
    dimmed: !root.gtkAvailable && !root.recording
    text: root.externalSessionActive ? "\u25CF BUSY" : "\u25CF REC"
    tooltipText: root.recording
      ? "Recording — click to stop"
      : (root.externalSessionActive
        ? "Another gpu-screen-recorder session is already running"
        : (root.gtkAvailable ? "Click to start recording · middle-click for settings" : "Click to start recording (GTK settings app not found)"))

    onPressed: function(b) {
      if (!root.bar) return
      if (b === Qt.MiddleButton) {
        if (root.gtkAvailable) Quickshell.execDetached(["gpu-screen-recorder-gtk"])
        return
      }
      if (root.recording) {
        root.stopRecording()
      } else if (!root.externalSessionActive) {
        root.startRecording()
      }
    }
  }
}
