import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls  
import Quickshell

RowLayout {
    id: wifiWidget
    spacing: 6
    Layout.alignment: Qt.AlignVCenter

    MaterialSymbol {
        id: wifiIcon
        text: Network.materialSymbol
        iconSize: Appearance.font.pixelSize.smaller
        color: Appearance.colors.colOnLayer1
    }

    StyledText {
        id: wifiText
        text: Network.networkName || "No Wi-Fi"
        color: Appearance.colors.colOnLayer1
        font.pixelSize: Appearance.font.pixelSize.smaller
        font.family: "monospace"
        font.weight: Font.Bold
    }

    
}
