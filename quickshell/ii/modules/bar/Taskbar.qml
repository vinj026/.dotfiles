
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland



        RowLayout {
            id: taskbar
            spacing: 2
            height: parent.height
            Layout.alignment: Qt.AlignVCenter

        implicitWidth: childrenRect.width + childrenRect.x
            Repeater {
                model: ToplevelManager.toplevels

                delegate: Rectangle {
                    id: btn
                  Layout.preferredWidth: 80 
                Layout.preferredHeight: 20

                    radius: Appearance.rounding.unsharpenmore

                    color: modelData.activated
                           ? Appearance.colors.colPrimaryActive
                           : Appearance.colors.colLayer3

                    Behavior on color {
                        ColorAnimation {
                            duration: 400
                            easing.type: Easing.InOutCubic
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 400
                            easing.type: Easing.InOutCubic
                        }
                    }

                    states: [
                        State {
                            name: "active"; when: modelData.activated
                            PropertyChanges { target: btn; opacity: 1;  }
                        },
                        State {
                            name: "inactive"; when: !modelData.activated
                            PropertyChanges { target: btn; opacity: 0.75; }
                        }
                    ]

                    transitions: [
                        Transition {
                            NumberAnimation {
                                properties: "opacity,scale"
                                duration: 300
                                easing.type: Easing.OutCubic
                            }
                        }
                    ]

                    RowLayout {
                        anchors.fill: parent
                        spacing: 6

                        Text {
                            id: titleText
                            text: {
                                let t = modelData.title || modelData.appId || "Unknown"
                                return t.length > 10 ? t.slice(0, 8) + "…" : t
                            }

                            color: modelData.activated 
                                   ? Appearance.colors.colOnPrimary 
                                   : Appearance.colors.colOnLayer0

                            font.family: "monospace"
                            font.weight: Font.Bold
                            font.pixelSize: Appearance.font.pixelSize.smaller
                            Layout.fillWidth: true
                            elide: Text.ElideRight

                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter

                            Behavior on color {
                                ColorAnimation { duration: 300; easing.type: Easing.InOutCubic }
                            }

                            states: [
                                State {
                                    name: "active"; when: modelData.activated
                                    PropertyChanges { target: titleText; opacity: 1 }
                                },
                                State {
                                    name: "inactive"; when: !modelData.activated
                                    PropertyChanges { target: titleText; opacity: 0.7 }
                                }
                            ]

                            transitions: [
                                Transition {
                                    NumberAnimation {
                                        properties: "opacity"
                                        duration: 250
                                        easing.type: Easing.OutCubic
                                    }
                                }
                            ]
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (modelData.activated) {
                                modelData.minimized = true
                            } else {
                                modelData.activate()
                            }
                        }
                    }
                }
            }
        }
