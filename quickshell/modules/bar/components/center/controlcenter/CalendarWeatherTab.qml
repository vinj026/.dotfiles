import QtQuick
import Quickshell
import "../../../../../theme"
import "../../../../../components"

Item {
    id: root

    property bool active: false
    property string symbolFont: ""

    implicitWidth: 348
    implicitHeight: mainCol.implicitHeight

    // ── Live clock for "today" tracking ──
    property date today: new Date()
    Timer {
        interval: 60000; repeat: true; running: root.active
        onTriggered: root.today = new Date()
    }

    // ── Calendar view state ──
    property int viewYear: new Date().getFullYear()
    property int viewMonth: new Date().getMonth()

    readonly property int daysInMonth: new Date(root.viewYear, root.viewMonth + 1, 0).getDate()
    readonly property int firstWeekday: new Date(root.viewYear, root.viewMonth, 1).getDay() // 0 = Sunday
    readonly property var dayCells: {
        let cells = [];
        for (let i = 0; i < root.firstWeekday; i++) cells.push(0);
        for (let d = 1; d <= root.daysInMonth; d++) cells.push(d);
        while (cells.length % 7 !== 0) cells.push(0);
        return cells;
    }
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property var weekdayLabels: ["S", "M", "T", "W", "T", "F", "S"]

    function shiftMonth(delta) {
        let m = root.viewMonth + delta;
        if (m < 0) { m = 11; root.viewYear--; }
        else if (m > 11) { m = 0; root.viewYear++; }
        root.viewMonth = m;
    }
    function backToToday() {
        root.viewYear = root.today.getFullYear();
        root.viewMonth = root.today.getMonth();
    }

    Column {
        id: mainCol
        width: parent.width
        spacing: 8

        // ── Weather Card (Open-Meteo via WeatherService) ──
        Rectangle {
            width: parent.width; height: 112
            radius: Theme.shapeCornerExtraLarge
            color: Theme.surfaceContainerHigh

            Item {
                anchors.fill: parent; anchors.margins: 14

                Row {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    spacing: 10

                    Rectangle {
                        width: 40; height: 40; radius: 20
                        color: Theme.primaryContainer
                        Text {
                            anchors.centerIn: parent
                            font.family: root.symbolFont; font.pixelSize: 22
                            text: WeatherService.weatherIcon
                            color: Theme.onPrimaryContainer
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold
                            text: WeatherService.cityName; color: Theme.textPrimary
                        }
                        Text {
                            font.family: Theme.fontFamily; font.pixelSize: 11
                            text: WeatherService.conditionText; color: Theme.textMuted
                        }
                    }
                }

                Text {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    font.family: Theme.fontFamily; font.pixelSize: 32; font.weight: Font.Bold
                    text: WeatherService.isLoaded ? (WeatherService.temp + "°") : "--°"
                    color: Theme.textPrimary
                }

                Text {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    font.family: Theme.fontFamily; font.pixelSize: 10
                    text: WeatherService.isLoaded
                        ? "H " + WeatherService.tempMax + "°  L " + WeatherService.tempMin + "°   ·   " + WeatherService.humidity + "% RH   ·   " + WeatherService.windSpeed + " km/h"
                        : "Fetching forecast…"
                    color: Theme.textMuted
                }
            }
        }

        // ── Hourly Strip (next 4 slots) ──
        Rectangle {
            width: parent.width; height: 74
            radius: Theme.shapeCornerExtraLarge
            color: Theme.surfaceContainerHigh

            Row {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Repeater {
                    model: Math.min(4, WeatherService.hourlyForecast.length)

                    Item {
                        id: hourSlot
                        width: (parent.width - 24) / 4
                        height: parent.height

                        readonly property var hData: WeatherService.hourlyForecast[index]

                        Column {
                            anchors.centerIn: parent
                            spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.family: Theme.fontFamily; font.pixelSize: 9; font.weight: Font.Medium
                                text: hourSlot.hData ? hourSlot.hData.time : "--:--"
                                color: Theme.textMuted
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.family: root.symbolFont; font.pixelSize: 16
                                text: hourSlot.hData ? hourSlot.hData.icon : ""
                                color: Theme.primary
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.family: Theme.fontFamily; font.pixelSize: 11; font.weight: Font.Bold
                                text: hourSlot.hData ? (hourSlot.hData.temp + "°") : "--°"
                                color: Theme.textPrimary
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: WeatherService.hourlyForecast.length === 0
                font.family: Theme.fontFamily; font.pixelSize: 10
                text: "Hourly forecast unavailable"
                color: Theme.textMuted
            }
        }

        // ── Interactive Calendar Card ──
        Rectangle {
            width: parent.width
            height: calInner.implicitHeight + 24
            radius: Theme.shapeCornerExtraLarge
            color: Theme.surfaceContainerHigh

            Column {
                id: calInner
                anchors.fill: parent; anchors.margins: 12
                spacing: 6

                // Header: Month & Year + Navigation
                Item {
                    width: parent.width; height: 28

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Theme.fontFamily; font.pixelSize: 13; font.weight: Font.Bold
                        text: root.monthNames[root.viewMonth] + " " + root.viewYear
                        color: Theme.textPrimary
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Rectangle {
                            width: 26; height: 26; radius: 13
                            color: todayMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            Text {
                                anchors.centerIn: parent
                                font.family: root.symbolFont; font.pixelSize: 14
                                text: "\ue8df" // jump to today
                                color: Theme.textMuted
                            }
                            MouseArea {
                                id: todayMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.backToToday()
                            }
                        }

                        Rectangle {
                            width: 26; height: 26; radius: 13
                            color: prevMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            Text {
                                anchors.centerIn: parent
                                font.family: root.symbolFont; font.pixelSize: 16
                                text: "\ue314" // chevron_left
                                color: Theme.textPrimary
                            }
                            MouseArea {
                                id: prevMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.shiftMonth(-1)
                            }
                        }

                        Rectangle {
                            width: 26; height: 26; radius: 13
                            color: nextMouse.containsMouse ? Theme.surfaceContainerHighest : "transparent"
                            Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }
                            Text {
                                anchors.centerIn: parent
                                font.family: root.symbolFont; font.pixelSize: 16
                                text: "\ue315" // chevron_right
                                color: Theme.textPrimary
                            }
                            MouseArea {
                                id: nextMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: root.shiftMonth(1)
                            }
                        }
                    }
                }

                // Day-of-week labels
                Item {
                    width: parent.width; height: 16
                    Row {
                        anchors.fill: parent
                        Repeater {
                            model: 7
                            Text {
                                width: parent.width / 7
                                height: parent.height
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.family: Theme.fontFamily; font.pixelSize: 9; font.weight: Font.Bold
                                text: root.weekdayLabels[index]
                                color: Theme.textMuted
                            }
                        }
                    }
                }

                // Day grid (6 rows max)
                Grid {
                    width: parent.width
                    columns: 7

                    Repeater {
                        model: root.dayCells.length

                        Item {
                            id: dayCell
                            width: parent.width / 7
                            height: 28

                            readonly property int dayNum: root.dayCells[index]
                            readonly property bool isToday: dayNum !== 0
                                && root.viewYear === root.today.getFullYear()
                                && root.viewMonth === root.today.getMonth()
                                && dayNum === root.today.getDate()

                            Rectangle {
                                id: dayBg
                                anchors.centerIn: parent
                                width: 26; height: 26; radius: 13
                                color: dayCell.isToday ? Theme.primary : "transparent"
                                Behavior on color { ColorAnimation { duration: Theme.animDurationFast } }

                                Text {
                                    anchors.centerIn: parent
                                    font.family: Theme.fontFamily
                                    font.pixelSize: 11
                                    font.weight: dayCell.isToday ? Font.Bold : Font.Medium
                                    text: dayCell.dayNum !== 0 ? dayCell.dayNum : ""
                                    color: dayCell.isToday ? Theme.onPrimary : Theme.textPrimary
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}