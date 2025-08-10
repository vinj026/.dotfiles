
import "./weather"
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root

    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    property real useShortenedForm: (Appearance.sizes.barHellaShortenScreenWidthThreshold >= screen?.width) ? 2 : (Appearance.sizes.barShortenScreenWidthThreshold >= screen?.width) ? 1 : 0
    readonly property int centerSideModuleWidth: (useShortenedForm == 2) ? Appearance.sizes.barCenterSideModuleWidthHellaShortened : (useShortenedForm == 1) ? Appearance.sizes.barCenterSideModuleWidthShortened : Appearance.sizes.barCenterSideModuleWidth

    component VerticalBarSeparator: Rectangle {
        Layout.topMargin: Appearance.sizes.baseBarHeight / 3
        Layout.bottomMargin: Appearance.sizes.baseBarHeight / 3
        Layout.fillHeight: true
        implicitWidth: 1
        color: Appearance.colors.colOutlineVariant
    }

    // Background shadow
    Loader {
        active: Config.options.bar.showBackground && Config.options.bar.cornerStyle === 1
        anchors.fill: barBackground
        sourceComponent: StyledRectangularShadow {
            anchors.fill: undefined
            target: barBackground
        }
    }
    // Background
    Rectangle {
        id: barBackground
        anchors.fill: parent
        color: Config.options.bar.showBackground ? Appearance.colors.colLayer0 : "transparent"
        radius: Config.options.bar.cornerStyle === 1 ? Appearance.rounding.windowRounding : 0
        border.width: Config.options.bar.cornerStyle === 1 ? 1 : 0
        border.color: Appearance.colors.colLayer0Border
    }

    RowLayout {
        anchors.fill: parent
        spacing: 10
        RowLayout {
            id: leftSectionRowLayout
            Layout.leftMargin: 8
            
            Taskbar {
                visible: root.useShortenedForm === 0

              }
           
          }




        Item { Layout.fillWidth: true }  // Spacer tengah

        RowLayout {
          id: rightSectionRowLayout
          Layout.rightMargin: 8
          spacing: 5
          
          BarGroup{
          Media {
            visible: root.useShortenedForm === 0

              }
          }
            BarGroup {
                Wifi {
                    visible: root.useShortenedForm === 0
                    Layout.alignment: Qt.AlignVCenter
                }
              }


            BarGroup{
              BatteryIndicator{
                     visible: root.useShortenedForm === 0
                    Layout.alignment: Qt.AlignVCenter
              }
            }

            BarGroup {
              bgColor:Appearance.colors.colPrimaryContainer
              ClockWidget {
                    visible: root.useShortenedForm === 0
                    Layout.alignment: Qt.AlignVCenter
                }
              }
            
       }
    }
}

