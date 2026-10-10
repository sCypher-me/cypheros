import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Barra de captura: prints, edição, gravação, cor e régua. SUPER+PRINT.
PanelWindow {
    id: win
    visible: Ui.captureOpen || bar.opacity > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "cypheros-control"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.captureOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    MouseArea { anchors.fill: parent; onClicked: Ui.captureOpen = false }

    readonly property var groups: [
        { title: "Print", items: [
            { icon: "camera", label: "Tela", run: () => Capture.screen() },
            { icon: "crop", label: "Área", run: () => Capture.area() },
            { icon: "window", label: "Janela", run: () => Capture.window() },
            { icon: "pen", label: "Editar", run: () => Capture.edit() } ] },
        { title: "Gravar", items: [
            { icon: "record", label: "Tela", run: () => Capture.record("screen") },
            { icon: "record", label: "Área", run: () => Capture.record("area") },
            { icon: Capture.withAudio ? "mic" : "volume-mute", label: Capture.withAudio ? "Com som" : "Sem som", toggle: true, run: () => Capture.withAudio = !Capture.withAudio } ] },
        { title: "Ferramentas", items: [
            { icon: "dropper", label: "Cor", run: () => Capture.pickColor() },
            { icon: "ruler", label: "Régua", run: () => Ui.toggleRuler() } ] }
    ]

    Glass {
        id: bar
        level: 2
        radius: 22 * Theme.s
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - height - 48 * Theme.s + (Ui.captureOpen ? 0 : 24)
        width: row.implicitWidth + 32 * Theme.s
        height: row.implicitHeight + 28 * Theme.s
        opacity: Ui.captureOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Ui.captureOpen ? Theme.durEnter : Theme.durExit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }
        Behavior on y { NumberAnimation { duration: Theme.durEnter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeSpring } }

        MouseArea { anchors.fill: parent }
        focus: Ui.captureOpen
        Keys.onEscapePressed: Ui.captureOpen = false

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 18 * Theme.s
            Repeater {
                model: win.groups
                delegate: Row {
                    required property var modelData
                    required property int index
                    spacing: 18 * Theme.s
                    Rectangle { visible: index > 0; width: 1; height: 56 * Theme.s; color: Theme.stroke; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        spacing: 8 * Theme.s
                        Label { kind: "muted"; text: modelData.title }
                        Row {
                            spacing: 6 * Theme.s
                            Repeater {
                                model: modelData.items
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool lit: modelData.toggle && Capture.withAudio
                                    width: 64 * Theme.s; height: 58 * Theme.s
                                    radius: 14 * Theme.s
                                    color: lit ? Qt.alpha(Theme.accent, 0.16) : m.containsMouse ? Theme.hover : Qt.rgba(1, 1, 1, 0.05)
                                    border.width: m.containsMouse || lit ? 1 : 0
                                    border.color: Qt.alpha(modelData.icon === "record" ? Theme.hot : Theme.accent, 0.5)
                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 5 * Theme.s
                                        Icon {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            name: modelData.icon; size: 20 * Theme.s
                                            color: modelData.icon === "record" ? Theme.hot : m.containsMouse || parent.parent.lit ? Theme.accent : Theme.text
                                        }
                                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: modelData.label; font.pixelSize: 11 * Theme.s }
                                    }
                                    MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: modelData.run() }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
