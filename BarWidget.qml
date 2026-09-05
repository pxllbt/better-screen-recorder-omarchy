import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "thirdparty.gpu-screen-recorder"

  property bool gtkAvailable: true
  property bool sessionActive: false
  property bool recording: false
  property string outputPath: ""
  property var gtkConfig: ({})
  property int gpuIndex: -1

  // Detect GPU: if single GPU, omit -gpu flag; if multiple, prefer discrete.
  Process {
    id: gpuDetectProc
    command: ["bash", "-lc", [
      "cards=(\"$(ls /dev/dri/card* 2>/dev/null)\")",
      "if [ ${#cards[@]} -eq 0 ]; then echo \"none\"; exit 0; fi",
      "if [ ${#cards[@]} -eq 1 ]; then echo \"0\"; exit 0; fi",
      "for card_path in \"${cards[@]}\"; do",
      "  card_name=$(basename \"$card_path\")",
      "  card_num=${card_name#card}",
      "  pci_slot=$(cat /sys/class/drm/${card_name}/device/uevent 2>/dev/null | grep PCI_SLOT_NAME | cut -d= -f2)",
      "  if [ -n \"$pci_slot\" ]; then",
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
    ].join("\\n")]
    stdout: StdioCollector {
      onStreamFinished: function() {
        var text = this.text ? this.text.trim() : ""
        if (text === "none") {
          root.gpuIndex = -1
        } else {
          root.gpuIndex = parseInt(text) || 0
        }
      }
    }
  }

  Process {
    id: sessionProc
    command: ["pgrep", "--quiet", "-f", "gpu-screen-recorder "]
    onExited: function(exitCode) {
      root.sessionActive = exitCode === 0
      if (!root.sessionActive) root.recording = false
    }
  }

  Timer {
    interval: 1000
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
    command: ["bash", "-lc", "cat ~/.config/gpu-screen-recorder/config"]
    stdout: StdioCollector {
      id: configCollector
      onStreamFinished: function() {
        var text = this.text || ""
        var cfg = {}
        if (text) {
          var lines = text.split("\\n")
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
      var device = audioInput.replace(/^device:/, "")
      args.push("-a", device)
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

  function shellEscape(str) {
    return "'" + str.replace(/'/g, "'\\''") + "'"
  }

  function startRecording() {
    if (!root.gtkAvailable || root.recording) return
    var now = new Date()
    var stamp = now.toISOString().replace(/[:.]/g, "-").slice(0, 19)
    var saveDir = getConfigValue("record.save_directory", "~/Videos")
    var outputPath = saveDir + "/" + stamp + ".mp4"
    var args = buildCliArgs()
    args.push("-o", outputPath)
    var parts = ["gpu-screen-recorder"]
    for (var i = 0; i < args.length; i++) {
      parts.push(shellEscape(args[i]))
    }
    var cmd = parts.join(" ") + " >/dev/null 2>&1 &"
    Quickshell.execDetached(["bash", "-lc", cmd])
    root.recording = true
    Quickshell.execDetached(["bash", "-lc", "pkill -f '^gpu-screen-recorder ' || true"])
  }

  function stopRecording() {
    if (!root.recording) return
    Quickshell.execDetached(["bash", "-lc", "pkill -f '^gpu-screen-recorder ' || true"])
    root.recording = false
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    visible: !root.sessionActive || root.recording
    text: root.recording ? "STOP" : (root.gtkAvailable ? "REC" : "REC?")
    tooltipText: root.recording ? "Stop Recording" : (root.gtkAvailable ? "Click to start recording" : "GPU Screen Recorder (GTK not found)")

    onPressed: function(b) {
      if (!root.bar) return
      if (b === Qt.MiddleButton) {
        if (root.gtkAvailable) Quickshell.execDetached(["gpu-screen-recorder-gtk"])
      } else {
        if (!root.recording) {
          root.startRecording()
        } else {
          root.stopRecording()
        }
      }
    }
  }
}
