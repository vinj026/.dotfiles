// Battery.qml — Battery stats singleton using UPower
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Services.Notifications

Singleton {
    id: root
    readonly property UPowerDevice device: UPower.displayDevice
    readonly property int percentage: device ? Math.round(device.percentage * 100) : 0
    readonly property bool isCharging: device ? (device.state === UPowerDevice.Charging || device.state === UPowerDevice.FullyCharged || !UPower.onBattery) : !UPower.onBattery

    readonly property string icon: {
        if (isCharging) return "󰂄"
        if (percentage >= 95) return "󰁹"
        if (percentage >= 90) return "󰂂"
        if (percentage >= 80) return "󰂁"
        if (percentage >= 70) return "󰂀"
        if (percentage >= 60) return "󰁿"
        if (percentage >= 50) return "󰁾"
        if (percentage >= 40) return "󰁽"
        if (percentage >= 30) return "󰁼"
        if (percentage >= 20) return "󰁻"
        if (percentage >= 10) return "󰁺"
        return "󰂎"
    }

    // Power Profiles Integration
    property string activeProfile: "balanced"

    Process {
        id: getProfileProc
        command: ["powerprofilesctl", "get"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                root.activeProfile = text.trim()
            }
        }
    }

    function refreshProfile() {
        getProfileProc.running = true
    }

    function setProfile(profileName) {
        Quickshell.execDetached(["powerprofilesctl", "set", profileName])
        root.activeProfile = profileName

        let summary = ""
        let body = ""
        if (profileName === "performance") {
            summary = "Mode Performa"
            body = "Sistem berjalan pada performa puncak (konsumsi daya tinggi)."
        } else if (profileName === "balanced") {
            summary = "Mode Seimbang"
            body = "Keseimbangan optimal antara performa dan masa pakai baterai."
        } else if (profileName === "power-saver") {
            summary = "Mode Hemat Daya"
            body = "Mengurangi performa untuk memperpanjang masa pakai baterai."
        }

        if (summary !== "") {
            Notifications.addNotification({
                appName: "Sistem Daya",
                summary: summary,
                body: body,
                urgency: 1
            })
        }
    }

    // Lenovo Charging Modes Integration (Conservation Mode & Rapid Charge)
    property string activeChargeType: "Standard"

    Process {
        id: getChargeTypeProc
        command: ["cat", "/sys/class/power_supply/BAT1/charge_types"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                let content = text.trim()
                let match = content.match(/\[([^\]]+)\]/)
                if (match && match[1]) {
                    root.activeChargeType = match[1]
                }
            }
        }
    }

    function refreshChargeType() {
        getChargeTypeProc.running = true
    }

    function setChargeType(type) {
        Quickshell.execDetached(["sh", "-c", "echo " + type + " > /sys/class/power_supply/BAT1/charge_types"])
        root.activeChargeType = type

        let summary = ""
        let body = ""
        if (type === "Long_Life") {
            summary = "Conservation Mode Aktif"
            body = "Pengisian daya dibatasi hingga 60% untuk menjaga kesehatan baterai."
        } else if (type === "Fast") {
            summary = "Rapid Charge Aktif"
            body = "Baterai akan diisi daya dengan kecepatan maksimum."
        } else if (type === "Standard") {
            summary = "Mode Standar Aktif"
            body = "Pengisian daya berjalan secara normal."
        }

        if (summary !== "") {
            Notifications.addNotification({
                appName: "Baterai",
                summary: summary,
                body: body,
                urgency: 1
            })
        }
    }

    // Low battery monitoring logic
    property bool warnedLow: false
    property bool warnedCritical: false

    function checkBatteryStatus() {
        if (isCharging) {
            // Reset warnings when charging
            warnedLow = false
            warnedCritical = false
            return
        }

        if (percentage <= 10) {
            if (!warnedCritical) {
                warnedCritical = true
                warnedLow = true // prevent low warning if critical fires first
                Notifications.addNotification({
                    appName: "Sistem",
                    summary: "Baterai Kritis!",
                    body: "Baterai tinggal " + percentage + "%. Segera colok charger agar laptop tidak mati.",
                    urgency: 2
                })
            }
        } else if (percentage <= 20) {
            if (!warnedLow) {
                warnedLow = true
                Notifications.addNotification({
                    appName: "Sistem",
                    summary: "Baterai Lemah",
                    body: "Baterai tinggal " + percentage + "%. Silakan hubungkan pengisi daya.",
                    urgency: 1
                })
            }
        } else {
            // Reset warning flags if battery is above 20%
            warnedLow = false
            warnedCritical = false
        }
    }

    onPercentageChanged: checkBatteryStatus()
    onIsChargingChanged: checkBatteryStatus()

    Component.onCompleted: {
        refreshProfile()
        refreshChargeType()
        // Run initial check on startup
        checkBatteryStatus()
    }
}

