import QtQuick
import Quickshell

ShellRoot {
    PanelWindow {
        id: win
        Component.onCompleted: {
            console.log("--- ShellScreen properties ---")
            for (var prop in win.screen) {
                console.log(prop)
            }
            Qt.quit()
        }
    }
}
