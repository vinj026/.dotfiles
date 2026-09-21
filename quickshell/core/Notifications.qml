pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root
    property int defaultExpireTimeout: 10000
    // <= 0 means unlimited popup entries (screen height still limits what is visible).
    property int maxPopupCount: 3
    property int maxHistoryCount: 200

    component NotifObj: QtObject {
        required property var notification
        readonly property int notificationId: notification?.id ?? -1
        property bool popup: true
        property real timestamp: Date.now()
        property var popupTimer: null
        
        readonly property string summary: notification.summary
        readonly property string body: notification.body
        readonly property string appName: notification.appName
        readonly property string appIcon: notification.appIcon
        readonly property string image: notification.image

        // Helper properties for UI
        readonly property string time: Qt.formatTime(new Date(timestamp), "HH:mm")
        readonly property int urgency: notification?.urgency ?? 1
    }

    property list<NotifObj> list: []
    property var popupList: list.filter(notif => notif.popup)
    property bool clearingHistory: false

    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        keepOnReload: true 

        onNotification: (n) => {
            n.tracked = true;

            let newNotif = notifComponent.createObject(root, { "notification": n });
            root.list = [newNotif, ...root.list];

            enforcePopupLimit();
            enforceHistoryLimit();
            startPopupTimer(newNotif, n.expireTimeout);
        }
    }

    Component { id: notifComponent; NotifObj {} }
    Component { id: popupTimerComponent; Timer {} }

    function clearPopupTimer(nObj) {
        if (!nObj || !nObj.popupTimer) return;
        nObj.popupTimer.stop();
        nObj.popupTimer.destroy();
        nObj.popupTimer = null;
    }

    function startPopupTimer(nObj, expireTimeout) {
        if (!nObj) return;
        clearPopupTimer(nObj);

        let timeout = Number(expireTimeout);
        if (isNaN(timeout)) timeout = root.defaultExpireTimeout;
        if (timeout < 0) timeout = root.defaultExpireTimeout;
        if (timeout === 0) return;

        let timer = popupTimerComponent.createObject(root, {
            interval: timeout,
            running: true,
            repeat: false
        });
        nObj.popupTimer = timer;

        timer.triggered.connect(() => {
            root.dismissPopup(nObj);
        });
    }

    function enforcePopupLimit() {
        if (root.maxPopupCount <= 0) return;

        let popupSeen = 0;
        let changed = false;
        for (let i = 0; i < root.list.length; i++) {
            const notif = root.list[i];
            if (!notif.popup) continue;
            popupSeen++;
            if (popupSeen > root.maxPopupCount) {
                notif.popup = false;
                clearPopupTimer(notif);
                changed = true;
            }
        }

        if (changed) {
            triggerListChange();
        }
    }

    function enforceHistoryLimit() {
        while (root.list.length > root.maxHistoryCount) {
            let oldObj = root.list[root.list.length - 1];
            let trimmedList = [];
            for (let i = 0; i < root.list.length - 1; i++) {
                trimmedList.push(root.list[i]);
            }
            root.list = trimmedList;
            dismissPopup(oldObj);
            clearPopupTimer(oldObj);
            oldObj.destroy();
        }
    }

    function dismissPopupById(notificationId) {
        if (notificationId === undefined || notificationId === null) return;
        for (let i = 0; i < root.list.length; i++) {
            const notif = root.list[i];
            if (notif.notificationId === notificationId && notif.popup) {
                clearPopupTimer(notif);
                notif.popup = false;
                triggerListChange();
                break;
            }
        }
    }

    function dismissPopup(nObj) {
        if (!nObj) return;
        if (nObj.notificationId >= 0) {
            dismissPopupById(nObj.notificationId);
            return;
        }
        if (nObj.popup) {
            clearPopupTimer(nObj);
            nObj.popup = false;
            triggerListChange();
        }
    }

    function removeNotification(nObj) {
        if (!nObj) return;
        dismissPopup(nObj);
        nObj.notification.dismiss();
        let newList = [];
        for (let i = 0; i < list.length; i++) {
            if (list[i] !== nObj) newList.push(list[i]);
        }
        root.list = newList;
        clearPopupTimer(nObj);
        nObj.destroy();
    }

    function clearHistory() {
        if (clearingHistory) return;
        if (root.list.length === 0) return;

        clearingHistory = true;
        let itemsToClear = [...root.list];
        let index = itemsToClear.length - 1;

        // Calculate dynamic interval to keep total clearing sequence around 200-250ms
        let interval = Math.max(10, Math.min(50, 250 / itemsToClear.length));

        let staggerTimer = popupTimerComponent.createObject(root, {
            interval: interval,
            running: true,
            repeat: true
        });

        staggerTimer.triggered.connect(() => {
            if (index < 0) {
                staggerTimer.stop();
                staggerTimer.destroy();
                root.list = [];
                clearingHistory = false;
                return;
            }

            let notifObj = itemsToClear[index];

            // Remove from list to trigger ListView's remove transition
            let newList = [];
            for (let i = 0; i < root.list.length; i++) {
                if (root.list[i] !== notifObj) {
                    newList.push(root.list[i]);
                }
            }
            root.list = newList;

            // Defer destroying the object so that the delegate can complete its exit transition
            let destroyTimer = popupTimerComponent.createObject(root, {
                interval: 400,
                running: true,
                repeat: false
            });
            destroyTimer.triggered.connect(() => {
                clearPopupTimer(notifObj);
                notifObj.destroy();
                destroyTimer.destroy();
            });

            index--;
        });
    }

    function triggerListChange() {
        root.list = root.list.slice(0);
    }
}
