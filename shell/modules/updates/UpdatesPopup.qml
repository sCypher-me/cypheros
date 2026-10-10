import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Lista de atualizações aberta pelo ícone da barra.
PanelWindow {
    id: win
    visible: Ui.updatesOpen || panel.opacity > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.namespace: "cypheros-control"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.updatesOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    MouseArea { anchors.fill: parent; onClicked: Ui.updatesOpen = false }

    Glass {
        id: panel
        level: 2
        radius: 20 * Theme.s
        width: 380 * Theme.s
        height: col.implicitHeight + 36 * Theme.s
        anchors.right: parent.right
        anchors.rightMargin: 120 * Theme.s
        y: (Config.o.barPosition === "bottom" ? parent.height - height - Theme.barHeight - 24 * Theme.s : Theme.barHeight + 24 * Theme.s) + (Ui.updatesOpen ? 0 : -12)
        opacity: Ui.updatesOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Ui.updatesOpen ? Theme.durEnter : Theme.durExit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }
        Behavior on y { NumberAnimation { duration: Theme.durEnter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }
        MouseArea { anchors.fill: parent }
        focus: Ui.updatesOpen
        Keys.onEscapePressed: Ui.updatesOpen = false

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 * Theme.s }
            spacing: 12 * Theme.s

            RowLayout {
                Icon { name: "update"; color: Theme.accent }
                Column {
                    Layout.fillWidth: true
                    Label { text: Updates.count === 0 ? "Tudo em dia" : Updates.count + (Updates.count === 1 ? " atualização" : " atualizações"); font.weight: Font.DemiBold }
                    Label { kind: "muted"; text: Updates.checking ? "Conferindo..." : Updates.lastCheck ? "Conferido às " + Qt.formatTime(Updates.lastCheck, "HH:mm") : "" }
                }
                IconButton { icon: "refresh"; iconSize: 15 * Theme.s; tooltip: "Conferir de novo"; onClicked: Updates.check() }
            }

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 260 * Theme.s)
                visible: Updates.count > 0
                clip: true
                spacing: 2
                model: Updates.items
                delegate: RowLayout {
                    required property var modelData
                    width: ListView.view.width
                    spacing: 8 * Theme.s
                    Rectangle {
                        implicitWidth: src.implicitWidth + 12; implicitHeight: 18 * Theme.s; radius: 6
                        color: Qt.alpha(modelData.source === "AUR" ? Theme.accent2 : modelData.source === "Flatpak" ? Theme.ok : Theme.accent, 0.16)
                        Label { id: src; anchors.centerIn: parent; text: modelData.source; font.pixelSize: 10 * Theme.s }
                    }
                    Label { Layout.fillWidth: true; text: modelData.name }
                    Label { kind: "mono"; font.pixelSize: 11 * Theme.s; color: Theme.muted; text: modelData.to }
                }
            }

            Row {
                visible: Updates.count > 0
                spacing: 8 * Theme.s
                Icon { name: "shield"; size: 14 * Theme.s; color: Updates.snapshots ? Theme.ok : Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                Label {
                    kind: "muted"; width: 300 * Theme.s; wrapMode: Text.WordWrap
                    text: Updates.snapshots ? "Um ponto de restauração é criado antes. Se algo der errado: cypher restaurar." : "Sem snapshots neste disco (precisa de btrfs com snapper)."
                }
            }

            Rectangle {
                visible: Updates.count > 0
                Layout.fillWidth: true
                implicitHeight: 42 * Theme.s
                radius: 12 * Theme.s
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Theme.accent2 } }
                opacity: Updates.running ? 0.5 : btn.containsMouse ? 1 : 0.9
                Label { anchors.centerIn: parent; text: Updates.running ? "Atualizando no terminal..." : "Atualizar agora"; color: Theme.inkOnAccent; font.weight: Font.DemiBold }
                MouseArea { id: btn; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Updates.upgrade() }
            }
        }
    }
}
