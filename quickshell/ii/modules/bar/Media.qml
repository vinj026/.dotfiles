import qs.modules.common
import qs.modules.common.widgets
import qs.services
import qs
import qs.modules.common.functions

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import Quickshell.Hyprland

Item {
    id: root
    property bool borderless: ConfigOptions.bar.borderless
    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle || "") || ""

    readonly property bool hasMedia: activePlayer && !!activePlayer.trackTitle

    readonly property int maxTitleLength: 60
    readonly property string rawTitle: hasMedia 
        ? `${cleanedTitle}${activePlayer?.trackArtist ? ' • ' + activePlayer.trackArtist : ''}` 
        : ""
    readonly property string displayTitle: rawTitle.length > maxTitleLength 
        ? rawTitle.slice(0, maxTitleLength) + "…" 
        : rawTitle

    visible: hasMedia
    opacity: hasMedia ? 1 : 0
    Behavior on opacity { 
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad } 
    }

    Layout.fillHeight: true
    implicitWidth: hasMedia ? rowLayout.implicitWidth + rowLayout.spacing * 0 : 0
    implicitHeight: hasMedia ? 40 : 0

    Timer {
        running: activePlayer?.playbackState == MprisPlaybackState.Playing
        interval: 1000
        repeat: true
        onTriggered: activePlayer.positionChanged()
      }


MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        cursorShape: Qt.PointingHandCursor  
        onPressed: (event) => {
            if (event.button === Qt.MiddleButton) {
                activePlayer.togglePlaying();
            } else if (event.button === Qt.BackButton) {
                activePlayer.previous();
            } else if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                activePlayer.next();
            } else if (event.button === Qt.LeftButton) {
                GlobalStates.mediaControlsOpen = !GlobalStates.mediaControlsOpen
            }
        }
    }
    RowLayout {
        id: rowLayout
        spacing: 6
        anchors.fill: parent
        visible: hasMedia

        MaterialSymbol {
            id: playPauseIcon
            visible: hasMedia
            Layout.alignment: Qt.AlignVCenter
            fill: 1
            text: activePlayer?.isPlaying ? "pause" : "play_arrow"
            iconSize: Appearance.font.pixelSize.medium
            color: Appearance.m3colors.m3onSecondaryContainer

            MouseArea {
                anchors.fill: parent
                onClicked: if (activePlayer) activePlayer.togglePlaying()
            }
        }

        Rectangle {
            id: marqueeContainer
            visible: hasMedia
            Layout.alignment: Qt.AlignVCenter
            height: 20
            color: "transparent"
            clip: true

            property int gap: 40   

 
            Layout.preferredWidth: mediaText.width > 200 ? 200 : mediaText.width + 10

            Item {
                id: marqueeWrapper
                width: mediaText.width > marqueeContainer.width 
                    ? (mediaText.width + marqueeContainer.gap) * 2 
                    : mediaText.width
                height: parent.height
                x: 0

                NumberAnimation on x {
                    id: marqueeAnim
                    from: 0
                    to: -(mediaText.width + marqueeContainer.gap)
                    duration: 12000
                    loops: Animation.Infinite
                    easing.type: Easing.Linear
                    running: mediaText.width > marqueeContainer.width
                }

                StyledText {
                    id: mediaText
                    anchors.verticalCenter: parent.verticalCenter
                    text: displayTitle
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }

                StyledText {
                    visible: mediaText.width > marqueeContainer.width
                    anchors.verticalCenter: parent.verticalCenter
                    x: mediaText.width + marqueeContainer.gap
                    text: displayTitle
                    color: Appearance.colors.colOnLayer1
                    font.pixelSize: Appearance.font.pixelSize.smaller
                }
            }
        }
  }
}

