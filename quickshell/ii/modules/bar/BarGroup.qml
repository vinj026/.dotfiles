import qs.modules.common
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property real padding: 5
    property color bgColor: Config.options?.bar.borderless ? "transparent" : Appearance.colors.colLayer2
    implicitHeight: 30
    height: Appearance.sizes.barHeight
    implicitWidth: rowLayout.implicitWidth + padding * 2
    default property alias items: rowLayout.children

    Rectangle {
        id: background
        anchors {
            fill: parent
            topMargin: 4
            bottomMargin: 4
        }
        color: root.bgColor
        radius: Appearance.rounding.unsharpenmore
    }

    RowLayout {
        id: rowLayout
        anchors {
            verticalCenter: parent.verticalCenter
            left: parent.left
            right: parent.right
            leftMargin: root.padding
            rightMargin: root.padding
        }
        spacing: 4

    }
}
