import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    property bool borderless: Config.options.bar.borderless
    readonly property var chargeState: Battery.chargeState
    readonly property bool isCharging: Battery.isCharging
    readonly property bool isPluggedIn: Battery.isPluggedIn
    readonly property real percentage: Battery.percentage
    readonly property bool isLow: percentage <= Config.options.battery.low / 100
    readonly property color batteryLowBackground: Appearance.m3colors.darkmode ? Appearance.m3colors.m3error : Appearance.m3colors.m3errorContainer
    readonly property color batteryLowOnBackground: Appearance.m3colors.darkmode ? Appearance.m3colors.m3errorContainer : Appearance.m3colors.m3error

    implicitWidth: rowLayout.implicitWidth + rowLayout.spacing * 2
    implicitHeight: 32

    RowLayout {
    id: rowLayout
    spacing: 3   
    anchors.centerIn: parent

    MaterialSymbol {
        Layout.alignment: Qt.AlignVCenter
        text: "battery_full"
        iconSize: Appearance.font.pixelSize.smaller
        color: (isLow && !isCharging) ? batteryLowOnBackground : Appearance.m3colors.m3onSecondaryContainer
    }

    StyledText {
        Layout.alignment: Qt.AlignVCenter
        color: Appearance.colors.colOnLayer1
        text:  Math.round(percentage * 100) + "%"
        font.pixelSize: Appearance.font.pixelSize.smaller
        font.family: "monospace"
         font.weight: Font.Bold

    }
}


    Loader {
        id: boltIconLoader
        active: true
        anchors.left: rowLayout.left
        anchors.verticalCenter: rowLayout.verticalCenter

        Connections {
            target: root
            function onIsChargingChanged() {
                if (isCharging) boltIconLoader.active = true
            }
        }

        sourceComponent: MaterialSymbol {
            id: boltIcon

            text: "bolt"
            iconSize: Appearance.font.pixelSize.smaller
            color: Appearance.m3colors.m3onSecondaryContainer
            visible: opacity > 0 // Only show when charging
            opacity: isCharging ? 1 : 0 // Keep opacity for visibility
            onVisibleChanged: {
                if (!visible) boltIconLoader.active = false
            }

            Behavior on opacity {
                animation: Appearance.animation.elementMove.numberAnimation.createObject(this)
            }

        }
    }

}
