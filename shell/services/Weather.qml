pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Clima via Open-Meteo (grátis, sem chave). Cidade em config.json › weatherCity.
Singleton {
    id: root
    property bool ready: false
    property string city: ""
    property real temp: 0
    property int code: 0
    property bool isDay: true
    property var days: []        // [{ date, max, min, code }]

    readonly property string icon: iconFor(code, isDay)
    readonly property string desc: descFor(code)

    function iconFor(c, day) {
        if (c === 0 || c === 1) return day ? "sun" : "moon"
        if (c === 2 || c === 3) return "cloud"
        if (c === 45 || c === 48) return "fog"
        if (c >= 51 && c <= 67 || c >= 80 && c <= 82) return "rain"
        if (c >= 71 && c <= 77 || c === 85 || c === 86) return "snow"
        if (c >= 95) return "storm"
        return "cloud"
    }
    function descFor(c) {
        const t = { 0: "Céu limpo", 1: "Quase limpo", 2: "Parcialmente nublado", 3: "Nublado", 45: "Neblina", 48: "Neblina",
            51: "Garoa fraca", 53: "Garoa", 55: "Garoa forte", 61: "Chuva fraca", 63: "Chuva", 65: "Chuva forte",
            71: "Neve fraca", 73: "Neve", 75: "Neve forte", 80: "Pancadas de chuva", 81: "Pancadas de chuva", 82: "Temporal",
            95: "Trovoadas", 96: "Trovoadas com granizo", 99: "Trovoadas com granizo" }
        return t[c] ?? "—"
    }
    function refresh() { locate.running = true }

    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: root.refresh() }
    Connections { target: Config.o; function onWeatherCityChanged() { root.refresh() } }

    Process {
        id: locate
        command: Config.o.weatherCity !== ""
            ? ["curl", "-sf", "--max-time", "10", "https://geocoding-api.open-meteo.com/v1/search?count=1&language=pt&name=" + encodeURIComponent(Config.o.weatherCity)]
            : ["curl", "-sf", "--max-time", "10", "https://ipinfo.io/json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    let lat, lon
                    if (j.results) { lat = j.results[0].latitude; lon = j.results[0].longitude; root.city = j.results[0].name }
                    else { [lat, lon] = j.loc.split(","); root.city = j.city }
                    forecast.command = ["curl", "-sf", "--max-time", "10",
                        `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&current=temperature_2m,weather_code,is_day&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=auto&forecast_days=5`]
                    forecast.running = true
                } catch (e) { }
            }
        }
    }
    Process {
        id: forecast
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text)
                    root.temp = j.current.temperature_2m
                    root.code = j.current.weather_code
                    root.isDay = j.current.is_day === 1
                    const d = j.daily
                    root.days = d.time.map((t, i) => ({ date: t, max: d.temperature_2m_max[i], min: d.temperature_2m_min[i], code: d.weather_code[i] }))
                    root.ready = true
                } catch (e) { }
            }
        }
    }
}
