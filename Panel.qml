import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "tinkin.pangolin"
  ipcTarget: "tinkin.pangolin"
  manageIpc: false

  property string focusSection: "header"
  property int siteIndex: 0
  property bool cursorActive: false

  readonly property bool showLabel: setting("showLabel", true) !== false && !(bar && bar.vertical)
  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family
  readonly property color iconColor: pangolin.active ? foreground : dim
  readonly property color barIconColor: pangolin.active ? barForeground : Qt.darker(barForeground, 1.55)
  readonly property string toggleHint: pangolin.active ? "Disconnect Pangolin" : "Connect Pangolin"
  readonly property bool headerHasCursor: cursorActive && focusSection === "header" && pangolin.installed
  readonly property color hoverFill: bar ? Style.hoverFillFor(bar.foreground, Color.accent) : "transparent"
  readonly property bool showSites: pangolin.active && pangolin.sites.length > 0
  readonly property string barLabel: pangolin.active ? "Pangolin" : "Pangolin off"

  function selectedSite() {
    if (pangolin.sites.length === 0) return null
    return pangolin.sites[Math.max(0, Math.min(siteIndex, pangolin.sites.length - 1))]
  }

  function ensureCursor() {
    if (siteIndex >= pangolin.sites.length) siteIndex = Math.max(0, pangolin.sites.length - 1)
    if (focusSection === "sites" && !showSites) focusSection = "header"
  }

  function moveCursor(dx, dy) {
    cursorActive = true
    ensureCursor()
    if (dy === 0) return
    if (focusSection === "header") {
      if (dy > 0 && showSites) {
        focusSection = "sites"
        siteIndex = 0
        scrollCursorIntoView()
      }
      return
    }
    if (focusSection === "sites") {
      if (dy < 0 && siteIndex === 0) {
        setHeaderCursor()
        return
      }
      siteIndex = Math.max(0, Math.min(pangolin.sites.length - 1, siteIndex + dy))
      scrollCursorIntoView()
    }
  }

  function activateCursor() {
    ensureCursor()
    if (focusSection === "header") pangolin.toggle()
  }

  function setHeaderCursor() {
    cursorActive = true
    focusSection = "header"
    if (panelFlick) panelFlick.contentY = 0
  }

  function setSiteCursor(index) {
    cursorActive = true
    focusSection = "sites"
    siteIndex = index
    scrollCursorIntoView()
  }

  function scrollItemIntoView(item) {
    if (!panelFlick || !item) return
    Qt.callLater(function() {
      if (!item) return
      var margin = Style.space(6)
      var point = item.mapToItem(panelFlick.contentItem, 0, 0)
      var top = point.y
      var bottom = top + item.height
      var viewTop = panelFlick.contentY
      var viewBottom = viewTop + panelFlick.height
      var maxY = Math.max(0, panelFlick.contentHeight - panelFlick.height)
      if (top < viewTop + margin) panelFlick.contentY = Math.max(0, top - margin)
      else if (bottom > viewBottom - margin) panelFlick.contentY = Math.min(maxY, bottom + margin - panelFlick.height)
    })
  }

  function scrollCursorIntoView() {
    if (focusSection === "sites" && siteColumn && siteIndex >= 0 && siteIndex < siteColumn.children.length)
      scrollItemIntoView(siteColumn.children[siteIndex])
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) {
    cursorActive = false
    if (panelFlick) panelFlick.contentY = 0
    pangolin.refresh()
    Qt.callLater(function() { keyCatcher.forceActiveFocus() })
  }
  onSiteIndexChanged: scrollCursorIntoView()

  Service {
    id: pangolin
    settings: root.settings
  }

  Connections {
    target: pangolin
    function onSitesChanged() { root.ensureCursor() }
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): string { pangolin.refresh(); return "ok" }
    function up(): string { pangolin.up(); return "ok" }
    function down(): string { pangolin.down(); return "ok" }
    function togglePangolin(): string { pangolin.toggle(); return "ok" }
    function status(): string { return pangolin.statusText }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    labelVisible: false
    hasVisualContent: true
    tooltipText: {
      if (!pangolin.installed) return "Pangolin CLI is not installed"
      if (pangolin.active) {
        var parts = ["Pangolin connected"]
        if (pangolin.orgId !== "") parts.push(pangolin.orgId)
        if (pangolin.connectedCount > 0) parts.push(pangolin.connectedCount + " site" + (pangolin.connectedCount === 1 ? "" : "s"))
        return parts.join(" · ")
      }
      return "Pangolin disconnected"
    }
    fixedWidth: bar && bar.vertical ? -1 : contentRow.implicitWidth + Style.space(16)
    fixedHeight: bar && bar.vertical ? contentRow.implicitHeight + Style.space(10) : -1
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.RightButton) pangolin.toggle()
      else if (buttonCode === Qt.MiddleButton) pangolin.refresh()
      else root.toggle()
    }

    Row {
      id: contentRow
      anchors.centerIn: parent
      spacing: Style.space(6)

      PangolinIcon {
        id: barIcon
        iconSize: Style.space(11)
        color: root.barIconColor
        crossed: !pangolin.active
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        visible: root.showLabel
        text: root.barLabel
        color: button.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.body
        font.bold: pangolin.active
        anchors.verticalCenter: parent.verticalCenter
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(520))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) {
        if (!root.cursorActive) { root.cursorActive = true; return }
        root.moveCursor(dx, dy)
      }
      onActivateRequested: if (root.cursorActive) root.activateCursor()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) {
        if (t === "t" || t === "T") pangolin.toggle()
        else if (t === "r" || t === "R") pangolin.refresh()
      }

      Flickable {
        id: panelFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickableDirection: Flickable.VerticalFlick
        interactive: contentHeight > height
        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
          id: column
          width: panelFlick.width
          spacing: Style.space(12)

          Item {
            id: header
            width: parent.width
            implicitHeight: hero.implicitHeight
            readonly property bool ringVisible: root.headerHasCursor
            function focusHero() { root.setHeaderCursor() }

            PanelHero {
              id: hero
              width: parent.width
              title: pangolin.installed ? (pangolin.orgId || "Pangolin") : "Pangolin"
              meta: {
                if (!pangolin.installed) return "Pangolin CLI is not installed"
                if (pangolin.active) {
                  var bits = ["Connected"]
                  if (pangolin.ipv4 !== "") bits.push(pangolin.ipv4)
                  return bits.join(" · ")
                }
                return "Pangolin is disconnected"
              }
              foreground: root.foreground
              fontFamily: root.fontFamily
              iconOpacity: pangolin.active ? 1.0 : 0.5
              iconComponent: Component {
                PangolinIcon {
                  iconSize: Style.font.display
                  color: root.iconColor
                  crossed: !pangolin.active
                }
              }

              trailingControl: Component {
                ToggleSwitch {
                  id: powerSwitch
                  visible: pangolin.installed
                  checked: pangolin.active
                  busy: pangolin.busy
                  hasCursor: header.ringVisible
                  foreground: hero.foreground
                  onHovered: function(on) { if (on) header.focusHero() }
                  onToggled: pangolin.toggle()

                  PanelToolTip {
                    visible: powerSwitch.containsMouse
                    text: root.toggleHint
                    fontFamily: hero.fontFamily
                  }
                }
              }
            }
          }

          Text {
            visible: pangolin.actionStatus !== "" || pangolin.lastError !== ""
            width: parent.width
            text: pangolin.actionStatus !== "" ? pangolin.actionStatus : pangolin.lastError
            color: pangolin.lastError !== "" && pangolin.actionStatus === "" ? root.urgent : root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
          }

          CursorSurface {
            visible: !pangolin.installed
            width: parent.width
            implicitHeight: missingText.implicitHeight + Style.spacing.rowPaddingX
            foreground: root.foreground

            Text {
              id: missingText
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.margins: Style.space(12)
              text: "Pangolin CLI is not installed or not on PATH."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              wrapMode: Text.WordWrap
            }
          }

          PanelSeparator {
            visible: pangolin.installed
            foreground: root.foreground
          }

          Column {
            visible: pangolin.installed
            width: parent.width
            spacing: Style.space(10)

            PanelSectionHeader {
              text: "SITES"
              foreground: root.foreground
              fontFamily: root.fontFamily
            }

            Text {
              visible: pangolin.active && pangolin.sites.length === 0
              width: parent.width
              text: "No sites on this connection."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
            }

            Text {
              visible: pangolin.installed && !pangolin.active
              width: parent.width
              text: "Connect to see your Pangolin sites."
              color: root.dim
              font.family: root.fontFamily
              font.pixelSize: Style.font.body
              horizontalAlignment: Text.AlignHCenter
            }

            Column {
              id: siteColumn
              visible: root.showSites
              width: parent.width
              spacing: Style.space(6)

              Repeater {
                model: pangolin.sites
                SiteRow {
                  required property var modelData
                  required property int index
                  width: siteColumn.width
                  peer: modelData
                  rowIndex: index
                }
              }
            }
          }
        }
      }
    }
  }

  component SiteRow: CursorSurface {
    id: siteRow
    property var peer: null
    property int rowIndex: 0
    readonly property string siteName: peer ? String(peer.name || "Unknown") : "Unknown"
    readonly property string siteMeta: {
      var parts = []
      var kind = pangolin.connectionKind(peer)
      if (kind !== "") parts.push(kind)
      var rtt = pangolin.formatRtt(peer ? peer.rtt : 0)
      if (rtt !== "") parts.push(rtt)
      if (peer && peer.endpoint) parts.push(String(peer.endpoint))
      return parts.join(" · ")
    }

    hasCursor: root.cursorActive && root.focusSection === "sites" && root.siteIndex === rowIndex
    current: peer && peer.connected === true
    foreground: root.foreground
    fill: root.hoverFill

    implicitHeight: Math.max(siteContent.implicitHeight, Style.space(40)) + Style.spacing.rowPaddingX

    MouseArea {
      anchors.fill: parent
      hoverEnabled: true
      onContainsMouseChanged: if (containsMouse) root.setSiteCursor(siteRow.rowIndex)
    }

    RowLayout {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: Style.space(10)
      anchors.rightMargin: Style.space(8)
      spacing: Style.space(8)

      Rectangle {
        width: Style.space(8)
        height: Style.space(8)
        radius: width / 2
        color: siteRow.peer && siteRow.peer.connected ? root.foreground : root.dim
        Layout.alignment: Qt.AlignVCenter
      }

      ColumnLayout {
        id: siteContent
        Layout.fillWidth: true
        spacing: Style.space(1)

        Text {
          Layout.fillWidth: true
          text: siteRow.siteName
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.body
          font.bold: siteRow.peer && siteRow.peer.connected
          elide: Text.ElideRight
        }

        Text {
          Layout.fillWidth: true
          visible: siteRow.siteMeta !== ""
          text: siteRow.siteMeta
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
          elide: Text.ElideRight
        }
      }
    }
  }
}
