pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property var notifications: []
    readonly property bool hasNotifications: notifications.length > 0

    function playNotificationSound(notif): void {
        if (notif && notif.hints && notif.hints["suppress-sound"]) {
            return;
        }

        let soundPath = (notif && notif.hints && notif.hints["sound-file"]) 
            ? notif.hints["sound-file"] 
            : "/home/vin/.config/quickshell/assets/sounds/notification.wav";

        try {
            Quickshell.execDetached(["pw-play", soundPath]);
        } catch (e) {
            try {
                Quickshell.execDetached(["canberra-gtk-play", "-i", "message"]);
            } catch (err) {}
        }
    }

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        imageSupported: true

        onNotification: notif => {
            notif.tracked = true;

            let list = root.notifications.slice();
            
            // If already exists, update in-place
            let existingIdx = list.findIndex(n => n.id === notif.id);
            if (existingIdx !== -1) {
                list[existingIdx] = notif;
            } else {
                // Add new notifications to the end of the stack (chronological stack)
                list.push(notif);
                root.playNotificationSound(notif);
            }

            // Cap to at most 4 simultaneous popups
            if (list.length > 4) {
                let removed = list.shift();
                if (removed) {
                    try { removed.dismiss(); } catch(e) {}
                }
            }

            root.notifications = list;
        }
    }

    function clearAll(): void {
        let list = root.notifications.slice();
        root.notifications = [];
        for (let i = 0; i < list.length; i++) {
            try { list[i].dismiss(); } catch(e) {}
        }
    }

    function removeNotification(notif): void {
        if (!notif) return;

        let list = root.notifications.slice();
        let idx = list.indexOf(notif);
        if (idx !== -1) {
            list.splice(idx, 1);
            root.notifications = list;
        }
        try {
            notif.dismiss();
        } catch(e) {}
    }
}
