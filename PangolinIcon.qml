import QtQuick
import QtQuick.Effects
import qs.Commons
import qs.Ui

Item {
  id: root

  property real iconSize: Style.font.icon
  property color color: Color.foreground
  property bool filled: true

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  Image {
    id: mark
    anchors.fill: parent
    fillMode: Image.PreserveAspectFit
    source: Qt.resolvedUrl("assets/pangolin.svg")
    sourceSize.width: Math.round(width * 2)
    sourceSize.height: Math.round(height * 2)
    smooth: true
    visible: false
    layer.enabled: true
  }

  MultiEffect {
    anchors.fill: mark
    source: mark
    colorization: root.filled ? 0 : 1.0
    colorizationColor: root.color
    opacity: root.filled ? 1.0 : 0.55
  }
}
