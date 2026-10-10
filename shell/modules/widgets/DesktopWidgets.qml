import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Widgets da área de trabalho: relógio, clima, agenda, mídia, sistema e notas.
PanelWindow {
    id: win
    required property ShellScreen modelData
    screen: modelData
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.namespace: "cypheros-widgets"
    WlrLayershell.keyboardFocus: Config.o.widgetNotes ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { item: col }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    ColumnLayout {
        id: col
        x: 64 * Theme.s
        y: (Config.o.barPosition === "bottom" ? 60 : 110) * Theme.s
        width: 380 * Theme.s
        spacing: 22 * Theme.s

        Column {
            visible: Config.o.widgetClock
            Text {
                font.family: Theme.fontDisplay
                font.weight: Font.Light
                font.pixelSize: 128 * Theme.s
                font.letterSpacing: -4
                text: Qt.formatTime(clock.date, Config.o.use24h ? "HH:mm" : "h:mm")
                color: "white"
                layer.enabled: true
                layer.effect: ShaderEffect {
                    property color c1: "white"
                    property color c2: Theme.accent
                    property color c3: Theme.accent2
                    fragmentShader: Qt.resolvedUrl("../../shaders/textgrad.frag.qsb")
                }
            }
            Label {
                font.pixelSize: 18 * Theme.s
                color: Qt.lighter(Theme.muted, 1.15)
                text: { const s = clock.date.toLocaleDateString(Qt.locale(Config.o.locale), "dddd, d 'de' MMMM"); return s.charAt(0).toUpperCase() + s.slice(1) }
            }
        }

        // Clima de agora e dos próximos dias
        Glass {
            visible: Config.o.widgetWeather && Weather.ready
            level: 0
            Layout.fillWidth: true
            implicitHeight: weatherCol.implicitHeight + 32 * Theme.s
            ColumnLayout {
                id: weatherCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 * Theme.s }
                spacing: 12 * Theme.s
                RowLayout {
                    spacing: 14 * Theme.s
                    Icon { name: Weather.icon; size: 38 * Theme.s; color: Theme.accent }
                    Column {
                        Layout.fillWidth: true
                        Label { kind: "display"; font.pixelSize: 30 * Theme.s; text: Math.round(Weather.temp) + "°" }
                        Label { kind: "muted"; text: Weather.desc + (Weather.city ? " · " + Weather.city : "") }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Repeater {
                        model: Weather.days.slice(1, 5)
                        delegate: Column {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 4 * Theme.s
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                kind: "muted"
                                text: { const d = new Date(modelData.date + "T12:00"); const n = d.toLocaleDateString(Qt.locale(Config.o.locale), "ddd").replace(".", ""); return n.charAt(0).toUpperCase() + n.slice(1) }
                            }
                            Icon { anchors.horizontalCenter: parent.horizontalCenter; name: Weather.iconFor(modelData.code, true); size: 18 * Theme.s; color: Theme.accent2 }
                            Label { anchors.horizontalCenter: parent.horizontalCenter; kind: "mono"; font.pixelSize: 12 * Theme.s; text: Math.round(modelData.max) + "° " + Math.round(modelData.min) + "°" }
                        }
                    }
                }
            }
        }

        // Próximos compromissos
        Glass {
            visible: Agenda.upcoming.length > 0
            level: 0
            Layout.fillWidth: true
            implicitHeight: agendaCol.implicitHeight + 28 * Theme.s
            ColumnLayout {
                id: agendaCol
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 * Theme.s }
                spacing: 8 * Theme.s
                Row {
                    spacing: 8 * Theme.s
                    Icon { name: "calendar"; size: 14 * Theme.s; color: Theme.accent2; anchors.verticalCenter: parent.verticalCenter }
                    Label { kind: "muted"; text: "Próximos"; anchors.verticalCenter: parent.verticalCenter }
                }
                Repeater {
                    model: Agenda.upcoming
                    delegate: RowLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 10 * Theme.s
                        Label {
                            kind: "mono"; font.pixelSize: 12 * Theme.s; color: Theme.accent
                            text: { const d = new Date(modelData.date + "T12:00"); return (modelData.date === Agenda.key(new Date()) ? "hoje" : Qt.formatDate(d, "dd/MM")) + (modelData.time ? " " + modelData.time : "") }
                        }
                        Label { Layout.fillWidth: true; text: modelData.title }
                    }
                }
                MouseArea { Layout.fillWidth: true; implicitHeight: 1 }
            }
            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Ui.toggleCalendar() }
        }

        Glass {
            visible: Config.o.widgetMedia && media.visible
            level: 1
            Layout.fillWidth: true
            implicitHeight: media.implicitHeight + 32 * Theme.s
            MediaCard { id: media; anchors { fill: parent; margins: 16 * Theme.s } }
        }

        Glass {
            visible: Config.o.widgetSystem
            level: 0
            Layout.fillWidth: true
            implicitHeight: 84 * Theme.s
            RowLayout {
                anchors { fill: parent; margins: 16 * Theme.s }
                spacing: 14 * Theme.s
                Repeater {
                    model: [
                        { label: "CPU", value: Math.round(SysInfo.cpu * 100) + "%", pct: SysInfo.cpu, alt: false },
                        { label: "Memória", value: SysInfo.memUsed.toFixed(1) + " GB", pct: SysInfo.mem, alt: false },
                        { label: "Disco", value: Math.round(SysInfo.disk * 100) + "%", pct: SysInfo.disk, alt: true }
                    ]
                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 6 * Theme.s
                        Label { kind: "muted"; text: modelData.label }
                        Label { kind: "mono"; font.pixelSize: 15 * Theme.s; text: modelData.value }
                        Rectangle {
                            Layout.fillWidth: true; implicitHeight: 3; radius: 2; color: Qt.rgba(1, 1, 1, 0.1)
                            Rectangle { height: 3; radius: 2; width: parent.width * Math.min(1, modelData.pct); color: modelData.alt ? Theme.accent2 : Theme.accent; Behavior on width { NumberAnimation { duration: 600 } } }
                        }
                    }
                }
            }
        }

        // Notas rápidas (salvas em ~/.config/cypheros/notas.md)
        Glass {
            visible: Config.o.widgetNotes
            level: 0
            Layout.fillWidth: true
            implicitHeight: Math.max(120 * Theme.s, notesEdit.contentHeight + 64 * Theme.s)
            Row {
                x: 16 * Theme.s; y: 14 * Theme.s
                spacing: 8 * Theme.s
                Icon { name: "note"; size: 14 * Theme.s; color: Theme.hot; anchors.verticalCenter: parent.verticalCenter }
                Label { kind: "muted"; text: "Notas"; anchors.verticalCenter: parent.verticalCenter }
            }
            TextEdit {
                id: notesEdit
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 * Theme.s; topMargin: 40 * Theme.s }
                wrapMode: TextEdit.Wrap
                color: Theme.text
                selectionColor: Qt.alpha(Theme.accent, 0.4)
                font.family: Theme.fontBody
                font.pixelSize: Theme.fs
                text: Notes.text
                onTextChanged: if (activeFocus) Notes.save(text)
                Text { visible: !parent.text && !parent.activeFocus; text: "Clique e escreva algo..."; color: Theme.muted; font: parent.font }
            }
        }
    }
}
