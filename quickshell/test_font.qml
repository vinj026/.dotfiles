import QtQuick
import Quickshell

ShellRoot {
    Text {
        id: testText
        font.family: "Fira Code"
        Component.onCompleted: {
            console.log("Fira Code Font family:", font.family)
            console.log("Fira Code Font weight:", font.weight)
            console.log("Fira Code Font italic:", font.italic)
            Qt.quit()
        }
    }
}
