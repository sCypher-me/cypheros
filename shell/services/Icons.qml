pragma Singleton
import QtQuick
import Quickshell

// Conjunto de ícones próprio do CypherOS: traço 1.8, grade 24x24, pontas redondas.
// Cada ícone é um caminho SVG desenhado pelo componente Icon.qml.
Singleton {
    function circle(cx, cy, r) {
        return `M${cx - r} ${cy}a${r} ${r} 0 1 0 ${2 * r} 0a${r} ${r} 0 1 0 ${-2 * r} 0`
    }
    function rrect(x, y, w, h, r) {
        return `M${x + r} ${y}h${w - 2 * r}a${r} ${r} 0 0 1 ${r} ${r}v${h - 2 * r}a${r} ${r} 0 0 1 ${-r} ${r}h${-(w - 2 * r)}a${r} ${r} 0 0 1 ${-r} ${-r}v${-(h - 2 * r)}a${r} ${r} 0 0 1 ${r} ${-r}z`
    }

    readonly property var paths: ({
        "logo": "M12 2l9 5v10l-9 5-9-5V7zM12 7.5l4.5 2.5v4.5L12 17l-4.5-2.5V10z",
        "wifi": "M2 9a15 15 0 0 1 20 0M5 13a10 10 0 0 1 14 0M8.5 16.5a5 5 0 0 1 7 0M12 20h.01",
        "wifi-off": "M2 2l20 20M8.5 16.5a5 5 0 0 1 7 0M5 13a10 10 0 0 1 5-2.8M2 9a15 15 0 0 1 4.3-2.8M12 20h.01",
        "ethernet": rrect(3, 3, 18, 13, 2) + "M8 16v5M16 16v5M7 21h10M8 8v3M12 8v3M16 8v3",
        "volume": "M11 5L6 9H2v6h4l5 4zM15.5 8.5a5 5 0 0 1 0 7M19 5a10 10 0 0 1 0 14",
        "volume-low": "M11 5L6 9H2v6h4l5 4zM15.5 8.5a5 5 0 0 1 0 7",
        "volume-mute": "M11 5L6 9H2v6h4l5 4zM22 9l-6 6M16 9l6 6",
        "mic": rrect(9, 2, 6, 12, 3) + "M5 10a7 7 0 0 0 14 0M12 17v5",
        "brightness": circle(12, 12, 4) + "M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4",
        "moon": "M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z",
        "bell": "M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9M10 21a2 2 0 0 0 4 0",
        "bell-off": "M2 2l20 20M10 21a2 2 0 0 0 4 0M18 13c.3 2.6 1.3 3.6 3 4H7M6.3 6.3A6 6 0 0 0 6 8c0 7-3 9-3 9M9 3.3A6 6 0 0 1 18 8v1",
        "bluetooth": "M7 7l10 10-5 5V2l5 5L7 17",
        "battery": rrect(1, 6, 19, 12, 3) + "M23 10v4",
        "bolt": "M13 2L4 14h7l-1 8 9-12h-7z",
        "lock": rrect(5, 11, 14, 10, 2) + "M8 11V7a4 4 0 0 1 8 0v4",
        "power": "M12 2v10M6.3 6.3a8 8 0 1 0 11.4 0",
        "restart": "M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5",
        "logout": "M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9",
        "sleep": "M12 3a9 9 0 1 0 9 9 7 7 0 0 1-9-9zM17 3h4l-4 4h4",
        "settings": circle(12, 12, 3) + "M12 2v3M12 19v3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M2 12h3M19 12h3M4.9 19.1L7 17M17 7l2.1-2.1",
        "search": circle(11, 11, 7) + "M20 20l-4-4",
        "terminal": rrect(3, 4, 18, 16, 3) + "M7 9l3 3-3 3M12 15h5",
        "folder": "M3 7a2 2 0 0 1 2-2h4l2 2h8a2 2 0 0 1 2 2v8a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z",
        "camera": rrect(3, 5, 18, 14, 2) + circle(12, 12, 3),
        "palette": circle(12, 12, 9) + "M12 3a9 9 0 0 0 0 18",
        "play": "M7 4l13 8-13 8z",
        "pause": "M7 5v14M17 5v14",
        "next": "M5 5l10 7-10 7zM19 5v14",
        "prev": "M19 5L9 12l10 7zM5 5v14",
        "close": "M6 6l12 12M18 6L6 18",
        "check": "M5 12l5 5L20 7",
        "chevron-right": "M9 6l6 6-6 6",
        "calc": rrect(5, 2, 14, 20, 2) + "M8 6h8M8 11h.01M12 11h.01M16 11h.01M8 15h.01M12 15h.01M16 15h.01M8 19h8",
        "chip": rrect(6, 6, 12, 12, 2) + "M9 2v4M15 2v4M9 18v4M15 18v4M2 9h4M2 15h4M18 9h4M18 15h4",
        "memory": rrect(2, 7, 20, 10, 2) + "M6 7v10M10 7v10M14 7v10M18 7v10",
        "disk": circle(12, 12, 9) + circle(12, 12, 2),
        "apps": rrect(3, 3, 7, 7, 2) + rrect(14, 3, 7, 7, 2) + rrect(3, 14, 7, 7, 2) + rrect(14, 14, 7, 7, 2),
        "trash": "M3 6h18M8 6V4h8v2M6 6l1 15h10l1-15",
        "music": "M9 18V5l12-2v13M9 18a3 3 0 1 1-6 0 3 3 0 0 1 6 0zM21 16a3 3 0 1 1-6 0 3 3 0 0 1 6 0z",
        "sun": circle(12, 12, 4) + "M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4",
        "cloud": "M7 18a5 5 0 1 1 1-9.9A6 6 0 0 1 19 10a4 4 0 0 1 0 8z",
        "rain": "M7 15a5 5 0 1 1 1-9.9A6 6 0 0 1 19 7a4 4 0 0 1 0 8zM8 18l-1 3M12 18l-1 3M16 18l-1 3",
        "snow": "M7 15a5 5 0 1 1 1-9.9A6 6 0 0 1 19 7a4 4 0 0 1 0 8zM8 19h.01M12 19h.01M16 19h.01M10 22h.01M14 22h.01",
        "storm": "M7 15a5 5 0 1 1 1-9.9A6 6 0 0 1 19 7a4 4 0 0 1 0 8zM13 14l-3 4h4l-3 4",
        "fog": "M4 10h16M4 14h16M6 18h12M7 6h10",
        "calendar": rrect(3, 5, 18, 16, 2) + "M3 10h18M8 3v4M16 3v4",
        "clipboard": rrect(5, 4, 14, 17, 2) + rrect(9, 2, 6, 4, 1) + "M9 11h6M9 15h4",
        "smile": circle(12, 12, 9) + "M8 14s1.5 2 4 2 4-2 4-2M9 9h.01M15 9h.01",
        "file": "M14 3H6a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V9zM14 3v6h6",
        "history": "M3 12a9 9 0 1 0 3-6.7L3 8M3 3v5h5M12 7v5l3 2",
        "focus": circle(12, 12, 9) + circle(12, 12, 5) + circle(12, 12, 1),
        "profile": circle(12, 8, 4) + "M4 21a8 8 0 0 1 16 0",
        "note": "M5 3h14v18l-7-4-7 4z",
        "plus": "M12 5v14M5 12h14",
        "gamepad": rrect(2, 7, 20, 11, 5) + "M7 11v3M5.5 12.5h3M15 12h.01M18 11h.01",
        "crop": "M6 2v14a2 2 0 0 0 2 2h14M2 6h14a2 2 0 0 1 2 2v14",
        "window": rrect(3, 4, 18, 16, 2) + "M3 9h18M6.5 6.5h.01M9.5 6.5h.01",
        "pen": "M16 3l5 5L8 21H3v-5zM13 6l5 5",
        "record": circle(12, 12, 9) + circle(12, 12, 4),
        "dropper": "M15 4l5 5-2 2-5-5zM13 6l-9 9v5h5l9-9M7 17h.01",
        "ruler": "M3 17L17 3l4 4L7 21zM7 13l2 2M10 10l2 2M13 7l2 2",
        "overview": rrect(2, 4, 9, 7, 2) + rrect(13, 4, 9, 7, 2) + rrect(2, 13, 9, 7, 2) + rrect(13, 13, 9, 7, 2),
        "clock": circle(12, 12, 9) + "M12 7v5l3 2",
        "thermometer": "M14 14.8V5a2 2 0 0 0-4 0v9.8a4 4 0 1 0 4 0zM12 9v7",
        "network": "M7 4v14M3.5 14.5L7 18l3.5-3.5M17 20V6M13.5 9.5L17 6l3.5 3.5",
        "gpu": rrect(2, 6, 16, 12, 2) + circle(10, 12, 3) + "M18 9h3v6h-3M6 18v3",
        "update": "M21 12a9 9 0 1 1-3-6.7L21 8M21 3v5h-5M12 8v5l3 2",
        "phone": rrect(6, 2, 12, 20, 3) + "M11 18h2",
        "sparkle": "M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8zM19 15l.7 2.3L22 18l-2.3.7L19 21l-.7-2.3L16 18l2.3-.7z",
        "shield": "M12 2l8 3v6c0 5-3.5 9-8 11-4.5-2-8-6-8-11V5z",
        "archive": rrect(2, 3, 20, 5, 1) + "M4 8v11a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8M10 12h4",
        "send": "M22 2L11 13M22 2l-7 20-4-9-9-4z",
        "copy": rrect(8, 8, 13, 13, 2) + "M16 8V5a2 2 0 0 0-2-2H5a2 2 0 0 0-2 2v9a2 2 0 0 0 2 2h3",
        "star": "M12 3l2.8 5.7 6.2.9-4.5 4.4 1.1 6.2L12 17.3 6.4 20.2l1.1-6.2L3 9.6l6.2-.9z",
        "download": "M12 3v12M7 10l5 5 5-5M4 19h16",
        "refresh": "M20 12a8 8 0 1 1-2.3-5.7L20 8M20 3v5h-5",
        "package": "M12 2l9 5v10l-9 5-9-5V7zM3 7l9 5 9-5M12 12v10",
        "keyboard": rrect(2, 6, 20, 12, 2) + "M6 10h.01M10 10h.01M14 10h.01M18 10h.01M6 14h.01M18 14h.01M9 14h6",
        "globe": circle(12, 12, 9) + "M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18",
        "eye": "M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12z" + circle(12, 12, 3),
        "eye-off": "M2 2l20 20M10.6 5.1A10 10 0 0 1 12 5c6.5 0 10 7 10 7a17 17 0 0 1-2.6 3.5M6.6 6.6A17 17 0 0 0 2 12s3.5 7 10 7a10 10 0 0 0 5.4-1.6M9.9 9.9a3 3 0 0 0 4.2 4.2",
        "alert": "M12 3l10 18H2zM12 10v5M12 18h.01",
        "usb": "M12 2v14M9 5l3-3 3 3M8 10v3l4 3 4-3V9M8 10h.01M16 9h.01" + circle(12, 19, 2),
        "wallpaper": rrect(3, 3, 18, 18, 3) + "M3 16l5-5 4 4 3-3 6 6" + circle(15.5, 8.5, 1.5)
    })

    function get(name) { return paths[name] ?? paths["logo"] }
}
