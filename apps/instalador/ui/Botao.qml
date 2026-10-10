import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.components

// Botão do instalador: "principal" (degradê com brilho), "perigo" (rosa) ou "simples" (vidro).
Item {
    id: root
    property string text: ""
    property string icon: ""
    property string tipo: "principal"     // principal | perigo | simples
    property bool enabled: true
    signal clicked()
    implicitWidth: label.implicitWidth + (icon !== "" ? 25 * Theme.s : 0) + 44 * Theme.s
    implicitHeight: 46 * Theme.s
    // explícito: alguns Qt não refazem o layout quando o texto do botão muda
    Layout.preferredWidth: implicitWidth
    opacity: enabled ? 1 : 0.4
    Behavior on opacity { NumberAnimation { duration: Theme.durFast } }

    readonly property color cor: tipo === "perigo" ? Theme.hot : Theme.accent

    RectangularShadow {
        anchors.fill: bg
        radius: bg.radius
        blur: m.containsMouse ? 30 : 20
        visible: root.tipo !== "simples" && root.enabled
        color: Theme.glowColor(root.cor, 0.45)
    }
    Rectangle {
        id: bg
        anchors.fill: parent
        radius: 14 * Theme.s
        color: root.tipo === "simples" ? (m.containsMouse ? Theme.hover : Qt.rgba(1, 1, 1, 0.06)) : root.cor
        gradient: root.tipo === "principal" ? grad : null
        border.width: root.tipo === "simples" ? 1 : 0
        border.color: Theme.stroke
        scale: m.pressed ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
        Gradient { id: grad; orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Qt.tint(Theme.accent, Qt.alpha(Theme.accent2, 0.55)) } }
        Row {
            id: row
            anchors.centerIn: parent
            spacing: 8 * Theme.s
            Icon { visible: root.icon !== ""; name: root.icon || "logo"; size: 17 * Theme.s; color: label.color; anchors.verticalCenter: parent.verticalCenter }
            Label { id: label; text: root.text; font.weight: Font.Bold; font.pixelSize: 15 * Theme.s; color: root.tipo === "simples" ? Theme.text : Theme.inkOnAccent; anchors.verticalCenter: parent.verticalCenter }
        }
    }
    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; enabled: root.enabled; cursorShape: Qt.PointingHandCursor; onClicked: root.clicked() }
    Accessible.role: Accessible.Button
    Accessible.name: text
}
