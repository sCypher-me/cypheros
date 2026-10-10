import QtQuick
import qs.services
import qs.components

// Selo da fonte do pacote: Arch (ciano), AUR (violeta) ou Flatpak (rosa).
Rectangle {
    id: root
    property string source: "arch"
    readonly property color tint: source === "aur" ? Theme.accent2 : source === "flatpak" ? Theme.hot : Theme.accent

    implicitWidth: lbl.implicitWidth + 14 * Theme.s
    implicitHeight: 20 * Theme.s
    radius: height / 2
    color: Qt.alpha(tint, 0.14)
    border.width: 1
    border.color: Qt.alpha(tint, 0.45)

    Label {
        id: lbl
        anchors.centerIn: parent
        text: root.source === "aur" ? "AUR" : root.source === "flatpak" ? "Flatpak" : "Arch"
        kind: "mono"
        font.pixelSize: 10.5 * Theme.s
        font.weight: Font.DemiBold
        color: Qt.lighter(root.tint, 1.15)
    }
}
