function asObject(value) {
  return value && typeof value === "object" && typeof value.length !== "number" ? value : {}
}

function peerList(peers) {
  var source = asObject(peers)
  var result = []
  for (var id in source) {
    var peer = source[id] || {}
    result.push({
      id: String(peer.siteId || id),
      name: String(peer.name || "Site " + id),
      connected: peer.connected === true,
      endpoint: String(peer.endpoint || ""),
      isRelay: peer.isRelay === true,
      isLocal: peer.isLocal === true,
      rtt: typeof peer.rtt === "number" ? peer.rtt : 0,
      lastSeen: String(peer.lastSeen || "")
    })
  }
  result.sort(function(a, b) {
    if (a.connected !== b.connected) return a.connected ? -1 : 1
    return String(a.name).localeCompare(String(b.name))
  })
  return result
}

function connectionKind(peer) {
  if (!peer) return ""
  if (peer.isLocal === true) return "Local"
  if (peer.isRelay === true) return "Relay"
  return "Direct"
}

function formatRtt(ns) {
  var value = Number(ns)
  if (!isFinite(value) || value <= 0) return ""
  var ms = value / 1000000
  if (ms < 1) return "<1 ms"
  if (ms < 10) return ms.toFixed(1) + " ms"
  return Math.round(ms) + " ms"
}

function parseStatus(raw) {
  var text = String(raw || "").trim()
  if (text === "" || /no client is currently running/i.test(text)) {
    return { ok: true, running: false, loggedIn: true, message: "Disconnected", orgId: "", sites: [] }
  }

  try {
    var data = JSON.parse(text)
    var sites = peerList(data.peers)
    var running = data.connected === true
    var connectedCount = 0
    for (var i = 0; i < sites.length; i++) if (sites[i].connected) connectedCount++

    return {
      ok: true,
      running: running,
      loggedIn: data.registered !== false,
      orgId: String(data.orgId || ""),
      version: String(data.version || ""),
      ipv4: data.networkSettings && data.networkSettings.ipv4_addresses && data.networkSettings.ipv4_addresses.length > 0
        ? String(data.networkSettings.ipv4_addresses[0])
        : "",
      sites: running ? sites : [],
      connectedCount: connectedCount,
      message: running ? "Connected" : "Disconnected"
    }
  } catch (e) {
    return { ok: false, running: false, loggedIn: true, message: "Status error", error: "Failed to parse pangolin status", sites: [] }
  }
}

if (typeof module !== "undefined") {
  module.exports = {
    peerList: peerList,
    connectionKind: connectionKind,
    formatRtt: formatRtt,
    parseStatus: parseStatus
  }
}
