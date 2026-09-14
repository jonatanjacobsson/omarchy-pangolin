import QtQuick
import qs.Commons
import qs.Ui

Item {
  id: root

  property real iconSize: Style.font.icon
  property color color: Color.foreground
  property bool crossed: false

  width: iconSize
  height: iconSize
  implicitWidth: iconSize
  implicitHeight: iconSize

  // Official Fossorial pixel mark (5×4), same silhouette as the Pangolin app icon.
  readonly property real cell: iconSize / 5
  readonly property real y0: (iconSize - cell * 4) / 2
  readonly property var cells: [
    [0, 0], [1, 0], [3, 0], [4, 0],
    [1, 1], [2, 1], [3, 1],
    [2, 2],
    [1, 3], [3, 3]
  ]

  Repeater {
    model: root.cells

    Rectangle {
      required property var modelData
      x: modelData[0] * root.cell
      y: root.y0 + modelData[1] * root.cell
      width: root.cell
      height: root.cell
      color: root.color
    }
  }

  Rectangle {
    visible: root.crossed
    anchors.centerIn: parent
    width: parent.width * 1.18
    height: Math.max(2, parent.height * 0.14)
    radius: height / 2
    color: root.color
    rotation: -45
  }
}
