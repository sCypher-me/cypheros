import QtQuick
import QtQuick.Effects
import qs.services

// Borda "prisma": degradê ciano → violeta → rosa, usada em painéis em foco.
Item {
    id: root
    property real radius: Theme.radius
    property real borderWidth: 1
    property real strength: 1.0

    anchors.fill: parent

    Rectangle {
        id: grad
        anchors.fill: parent
        visible: false
        layer.enabled: true
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.alpha(Theme.accent, 0.75 * root.strength) }
            GradientStop { position: 0.45; color: Qt.alpha(Theme.accent2, 0.18 * root.strength) }
            GradientStop { position: 1.0; color: Qt.alpha(Theme.hot, 0.55 * root.strength) }
        }
    }

    Rectangle {
        id: ring
        anchors.fill: parent
        visible: false
        layer.enabled: true
        color: "transparent"
        radius: root.radius
        border.width: root.borderWidth
        border.color: "white"
    }

    MultiEffect {
        anchors.fill: parent
        source: grad
        maskEnabled: true
        maskSource: ring
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }
}
