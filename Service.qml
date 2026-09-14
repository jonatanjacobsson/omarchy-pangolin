import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "Model.js" as Model

Item {
  id: root

  property var settings: ({})

  property bool installed: false
  property bool running: false
  property int _desired: -1
  readonly property bool active: _desired === -1 ? running : (_desired === 1)
  property bool refreshing: false
  property string statusText: "Checking…"
  property string orgId: ""
  property string ipv4: ""
  property string version: ""
  property var sites: []
  property int connectedCount: 0
  property string actionStatus: ""
  property string lastError: ""
  property string binaryPath: ""

  readonly property int refreshIntervalSec: intSetting("refreshIntervalSec", 5, 3, 60)
  readonly property bool busy: whichProcess.running || statusProcess.running || actionProcess.running

  property string _statusOutput: ""
  property string _statusError: ""
  property string _whichOutput: ""
  property string _actionOutput: ""
  property string _actionError: ""

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function intSetting(name, fallback, min, max) {
    var n = parseInt(String(setting(name, fallback)), 10)
    if (!isFinite(n)) n = fallback
    if (n < min) n = min
    if (n > max) n = max
    return n
  }

  function connectionKind(peer) {
    return Model.connectionKind(peer)
  }

  function formatRtt(ns) {
    return Model.formatRtt(ns)
  }

  function pluginDir() {
    var path = Qt.resolvedUrl(".").toString()
    if (path.indexOf("file://") === 0)
      path = decodeURIComponent(path.slice(7))
    while (path.length > 1 && path.charAt(path.length - 1) === "/")
      path = path.slice(0, path.length - 1)
    return path
  }

  function pangolinCmd(args) {
    var cmd = [binaryPath !== "" ? binaryPath : "pangolin"]
    for (var i = 0; i < args.length; i++) cmd.push(args[i])
    return cmd
  }

  function refresh() {
    if (installed && binaryPath !== "") {
      refreshStatus()
      return
    }
    if (!whichProcess.running) {
      refreshing = true
      _whichOutput = ""
      whichProcess.running = true
    }
  }

  function refreshStatus() {
    if (!installed || statusProcess.running) return
    _statusOutput = ""
    _statusError = ""
    refreshing = true
    statusProcess.command = pangolinCmd(["status", "--json"])
    statusProcess.running = true
    if (!pollWatchdog.running) pollWatchdog.start()
  }

  function elideStatus(text) {
    var value = String(text || "").replace(/\s+/g, " ").trim()
    return value.length > 140 ? value.substring(0, 137) + "…" : value
  }

  function resetUnavailable(message) {
    running = false
    _desired = -1
    statusText = message
    orgId = ""
    ipv4 = ""
    version = ""
    sites = []
    connectedCount = 0
  }

  function parseStatus(raw) {
    var parsed = Model.parseStatus(raw)
    if (!parsed.ok) {
      resetUnavailable(parsed.message || "Status error")
      lastError = parsed.error || "Failed to parse pangolin status"
      console.warn("pangolin", lastError)
      return
    }

    running = parsed.running === true
    if (_desired !== -1 && running === (_desired === 1)) _desired = -1
    orgId = parsed.orgId || ""
    ipv4 = parsed.ipv4 || ""
    version = parsed.version || ""
    sites = parsed.sites || []
    connectedCount = parsed.connectedCount || 0
    statusText = parsed.message || (running ? "Connected" : "Disconnected")
    lastError = ""
  }

  function toggle() {
    if (!installed) return
    if (active) down()
    else up()
  }

  function up() {
    _desired = 1
    runAction(["pkexec", "/bin/bash", pluginDir() + "/connect.sh"], "Approve the system prompt to start Pangolin…")
  }

  function down() {
    _desired = 0
    runAction([pluginDir() + "/disconnect.sh"], "")
  }

  function runAction(command, label) {
    if (actionProcess.running) return
    _actionOutput = ""
    _actionError = ""
    actionStatus = label || ""
    actionProcess.command = command
    actionProcess.running = true
  }

  Timer {
    id: refreshTimer
    interval: root.refreshIntervalSec * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: startupRamp
    property int ticks: 0
    interval: 1500
    repeat: true
    running: true
    onTriggered: {
      ticks += 1
      if (root.running || ticks >= 12) startupRamp.running = false
      else root.refresh()
    }
  }

  Timer {
    id: delayedRefresh
    interval: 500
    repeat: false
    onTriggered: root.refresh()
  }

  Timer {
    id: pollWatchdog
    interval: 8000
    repeat: false
    onTriggered: {
      if (statusProcess.running) statusProcess.running = false
    }
  }

  Timer {
    id: actionStatusTimer
    interval: 2200
    repeat: false
    onTriggered: root.actionStatus = ""
  }

  Process {
    id: whichProcess
    running: false
    command: ["bash", "-c", "PATH=\"$HOME/.local/bin:/usr/local/bin:$PATH\" command -v pangolin"]
    stdout: StdioCollector { id: whichStdout; waitForEnd: true; onStreamFinished: root._whichOutput = text }
    onExited: function(exitCode) {
      var path = String(whichStdout.text || root._whichOutput || "").trim().split("\n")[0]
      root.installed = exitCode === 0 && path !== ""
      root.binaryPath = root.installed ? path : ""
      if (root.installed) root.refreshStatus()
      else {
        root.refreshing = false
        root.resetUnavailable("Not installed")
      }
    }
  }

  Process {
    id: statusProcess
    running: false
    command: []
    stdout: StdioCollector { id: statusStdout; waitForEnd: true; onStreamFinished: root._statusOutput = text }
    stderr: StdioCollector { id: statusStderr; waitForEnd: true; onStreamFinished: root._statusError = text }
    onExited: function(exitCode) {
      root.refreshing = false
      var stdout = String(statusStdout.text || root._statusOutput || "")
      var stderr = String(statusStderr.text || root._statusError || "")
      if (stdout.trim() !== "") root.parseStatus(stdout)
      else {
        root.resetUnavailable("Disconnected")
        if (exitCode !== 0) root.lastError = root.elideStatus(stderr)
      }
    }
  }

  Process {
    id: actionProcess
    running: false
    command: []
    stdout: StdioCollector { id: actionStdout; waitForEnd: true; onStreamFinished: root._actionOutput = text }
    stderr: StdioCollector { id: actionStderr; waitForEnd: true; onStreamFinished: root._actionError = text }
    onExited: function(exitCode) {
      var stdout = String(actionStdout.text || root._actionOutput || "")
      var stderr = String(actionStderr.text || root._actionError || "")
      if (exitCode !== 0) {
        root._desired = -1
        var combined = String(stderr || stdout || "Pangolin command failed")
        if (/terminal is required|a password is required|sudo:/i.test(combined))
          combined = "Pangolin needs admin permission to create the tunnel. Try connecting again and approve the prompt."
        root.lastError = root.elideStatus(combined)
        root.actionStatus = root.lastError
        actionStatusTimer.restart()
      } else {
        root.lastError = ""
        root.actionStatus = ""
      }
      delayedRefresh.restart()
    }
  }
}
