pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "./styles"
import "../../theme"
import "../../components"

PanelWindow {
    id: root

    WlrLayershell.namespace: "shell"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: (root.currentStyle === "notch" && notchView.isOverlayActive)
        ? WlrKeyboardFocus.Exclusive
        : WlrKeyboardFocus.None

    anchors {
        left: true
        right: true
        top: true
    }

    readonly property string currentStyle: ShellConfig.currentStyle

    // For notch mode: Canvas is tall enough to cover the screen for backdrop dismiss and launcher/cc card,
    // while exclusiveZone remains strictly 30px so desktop windows never shift!
    implicitHeight: {
        switch (currentStyle) {
            case "floating":
                return Theme.floatingBarHeight + Theme.floatingBarTopMargin * 2;
            case "classic":
                return Theme.classicBarHeight;
            case "notch":
            default:
                return (root.screen ? root.screen.height : 1080);
        }
    }

    // Exclusive zone remains strictly locked at 30px so windows NEVER shift or jitter!
    exclusiveZone: {
        switch (currentStyle) {
            case "floating":
                return Theme.floatingBarHeight + Theme.floatingBarTopMargin;
            case "classic":
                return Theme.classicBarHeight;
            case "notch":
            default:
                return Math.round(Theme.notchHeight);
        }
    }

    color: "transparent"

    // Wayland Input Masking:
    // When launcher or control center is active: fullMask captures clicks across the screen for backdrop dismissal.
    // When idle/closed: compactMask captures ONLY the 30px notch and battery pill. All desktop space below passes clicks through!
    mask: (root.currentStyle === "notch" && !notchView.isOverlayActive)
        ? compactMask
        : fullMask

    Region {
        id: fullMask
        width: root.width
        height: root.height
    }

    Region {
        id: compactMask
        Region { item: notchView.morphIslandItem }
        Region { item: notchView.batteryPillItem }
    }

    NotchBarView {
        id: notchView
        anchors.fill: parent
        screen: root.screen
        panel: root
        visible: root.currentStyle === "notch"
    }

    FloatingBarView {
        anchors.fill: parent
        screen: root.screen
        panel: root
        visible: root.currentStyle === "floating"
    }

    ClassicBarView {
        anchors.fill: parent
        screen: root.screen
        panel: root
        visible: root.currentStyle === "classic"
    }
}
