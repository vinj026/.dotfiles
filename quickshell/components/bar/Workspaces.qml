// Workspaces.qml — Mango WM tag indicator (Japanese Hiragana style)
import QtQuick
import qs.core as C

Rectangle {
    id: container

    property string currentOutput: ""

    // Japanese kanji numerals for tag indices 1 to 10
    readonly property var tagsRoman: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

    // Pill container styling
    implicitWidth: rowLayout.width
    implicitHeight: 22
    width: implicitWidth
    height: implicitHeight
    radius: C.Style.r.xs // Less rounded (sharp terminal style)
    color: "transparent" // Minimalist: no background on the wrapper
    border.width: 0 // No border

    // MouseArea at container level for scrolling anywhere to switch tags
    MouseArea {
        anchors.fill: parent
        onWheel: (wheel) => {
            let cmd = wheel.angleDelta.y > 0 ? "prev" : "next"
            Quickshell.execDetached(["mmsg", "dispatch", "view," + cmd + "," + container.currentOutput])
        }
    }

    Row {
        id: rowLayout
        anchors.centerIn: parent
        spacing: 4

        Repeater {
            model: mangoService.workspaces

            delegate: Rectangle {
                id: tagDelegate
                visible: model.output === container.currentOutput
                
                // Animate width: focused tag is a pill (28px wide), otherwise a circle/square (20px wide)
                width: visible ? (model.isFocused ? 28 : 20) : 0
                height: visible ? 20 : 0
                radius: C.Style.r.xs // Less rounded matching tag buttons


                // Dynamic background colors
                color: {
                    if (model.isFocused)  return C.Colors.accent
                    if (model.isUrgent)   return C.Colors.red
                    if (model.isActive)   return C.Colors.alpha(C.Colors.accent, 0.25)
                    return "transparent"
                }

                // Borderless tags
                border.width: 0

                Text {
                    anchors.centerIn: parent
                    text: container.tagsRoman[model.idx - 1] ?? model.idx.toString()
                    font.pixelSize: 11
                    font.family: C.Style.fontSans
                    font.weight: model.isFocused ? C.Style.fw.bold : C.Style.fw.normal
                    
                    // Contrast colors for readability
                    color: {
                        if (model.isFocused)  return C.Colors.mantle // Contrast dark text on light accent background
                        if (model.isUrgent)   return C.Colors.mantle
                        if (model.isActive)   return C.Colors.accent
                        if (model.isOccupied) return C.Colors.text
                        return C.Colors.alpha(C.Colors.text, 0.35) // Dimmed for empty workspaces
                    }

                    Behavior on color {
                        ColorAnimation { duration: C.Style.durFast }
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mangoService.switchToWorkspace(model.idx, model.output)
                }

                Behavior on width {
                    NumberAnimation { duration: C.Style.durNormal; easing.type: Easing.OutCubic }
                }

                Behavior on color {
                    ColorAnimation { duration: C.Style.durFast }
                }
            }
        }
    }
}

