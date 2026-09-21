pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string cityName: "Local"
    property real temp: 27
    property int weatherCode: 1
    property string conditionText: "Partly Cloudy"
    property string weatherIcon: "\ue2c6"
    property real tempMax: 30
    property real tempMin: 25
    property real humidity: 80
    property real windSpeed: 12
    property var hourlyForecast: [] // array of { time: "14:00", temp: 29, icon: "\ue2c6" }

    property bool isLoaded: false

    Timer {
        id: refreshTimer
        interval: 1800000 // 30 minutes
        repeat: true
        running: true
        onTriggered: root.fetchWeather()
    }

    Component.onCompleted: {
        root.fetchLocation();
    }

    function codeToCondition(code: int): var {
        // WMO Weather interpretation codes (WW)
        if (code === 0) return { text: "Clear Sky", icon: "\ue518" }; // clear_day
        if (code === 1) return { text: "Mainly Clear", icon: "\ue518" };
        if (code === 2) return { text: "Partly Cloudy", icon: "\ue2c6" }; // partly_cloudy_day
        if (code === 3) return { text: "Overcast", icon: "\ue2c7" }; // cloud
        if (code >= 45 && code <= 48) return { text: "Foggy", icon: "\ue818" }; // fog
        if (code >= 51 && code <= 55) return { text: "Drizzle", icon: "\uf172" }; // rainy_light
        if (code >= 61 && code <= 65) return { text: "Rain", icon: "\ue814" }; // rainy
        if (code >= 71 && code <= 77) return { text: "Snow", icon: "\ueb3b" }; // weather_snowy
        if (code >= 80 && code <= 82) return { text: "Rain Showers", icon: "\uf172" };
        if (code >= 95) return { text: "Thunderstorm", icon: "\uebdc" }; // thunderstorm
        return { text: "Cloudy", icon: "\ue2c6" };
    }

    function fetchLocation(): void {
        let xhr = new XMLHttpRequest();
        xhr.open("GET", "http://ip-api.com/json");
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        let res = JSON.parse(xhr.responseText);
                        if (res && res.status === "success") {
                            root.cityName = res.city || "Local";
                            root.fetchWithCoords(res.lat, res.lon);
                            return;
                        }
                    } catch (e) {}
                }
                // Fallback coordinates
                root.fetchWithCoords(-1.25, 116.88);
            }
        };
        xhr.send();
    }

    function fetchWeather(): void {
        fetchLocation();
    }

    function fetchWithCoords(lat: real, lon: real): void {
        let url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat +
                  "&longitude=" + lon +
                  "&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m" +
                  "&hourly=temperature_2m,weather_code" +
                  "&daily=weather_code,temperature_2m_max,temperature_2m_min" +
                  "&timezone=auto";

        let xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    let data = JSON.parse(xhr.responseText);
                    if (data && data.current) {
                        root.temp = Math.round(data.current.temperature_2m);
                        root.humidity = Math.round(data.current.relative_humidity_2m || 0);
                        root.windSpeed = Math.round(data.current.wind_speed_10m || 0);
                        root.weatherCode = data.current.weather_code || 0;

                        let cond = root.codeToCondition(root.weatherCode);
                        root.conditionText = cond.text;
                        root.weatherIcon = cond.icon;

                        if (data.daily && data.daily.temperature_2m_max && data.daily.temperature_2m_max.length > 0) {
                            root.tempMax = Math.round(data.daily.temperature_2m_max[0]);
                            root.tempMin = Math.round(data.daily.temperature_2m_min[0]);
                        }

                        // Parse next 4-6 hourly forecast slots
                        let hForecast = [];
                        if (data.hourly && data.hourly.time && data.hourly.temperature_2m) {
                            let currHourStr = data.current.time.substring(0, 13); // e.g. "2026-09-09T22"
                            let startIndex = data.hourly.time.findIndex(t => t.startsWith(currHourStr));
                            if (startIndex === -1) startIndex = 0;

                            for (let i = 1; i <= 5; i++) {
                                let idx = startIndex + i * 2; // every 2 hours
                                if (idx < data.hourly.time.length) {
                                    let timePart = data.hourly.time[idx].substring(11, 16); // "hh:mm"
                                    let hTemp = Math.round(data.hourly.temperature_2m[idx]);
                                    let hCode = data.hourly.weather_code[idx];
                                    let hCond = root.codeToCondition(hCode);
                                    hForecast.push({
                                        time: timePart,
                                        temp: hTemp,
                                        icon: hCond.icon
                                    });
                                }
                            }
                        }
                        root.hourlyForecast = hForecast;
                        root.isLoaded = true;
                    }
                } catch (e) {
                    console.warn("Error parsing weather JSON:", e);
                }
            }
        };
        xhr.send();
    }
}
