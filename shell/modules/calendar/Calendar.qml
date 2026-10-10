import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.services
import qs.components

// Calendário e agenda: abre ao clicar no relógio da barra (ou SUPER+C).
PanelWindow {
    id: win
    visible: Ui.calendarOpen || panel.opacity > 0
    color: "transparent"
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 0
    WlrLayershell.namespace: "cypheros-control"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: Ui.calendarOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property date today: new Date()
    property date selected: new Date()
    property int month: today.getMonth()
    property int year: today.getFullYear()

    readonly property var loc: Qt.locale(Config.o.locale)
    readonly property var cells: {
        const first = new Date(year, month, 1)
        const offset = first.getDay()          // domingo primeiro, como no Brasil
        const out = []
        for (let i = 0; i < 42; i++) out.push(new Date(year, month, 1 - offset + i))
        return out
    }
    readonly property var dayEvents: { Agenda.events; return Agenda.on(selected) }

    function shift(n) {
        let m = month + n, y = year
        if (m < 0) { m = 11; y-- } else if (m > 11) { m = 0; y++ }
        month = m; year = y
    }
    function same(a, b) { return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate() }

    Connections {
        target: Ui
        function onCalendarOpenChanged() {
            if (!Ui.calendarOpen) return
            win.today = new Date(); win.selected = win.today
            win.month = win.today.getMonth(); win.year = win.today.getFullYear()
        }
    }

    MouseArea { anchors.fill: parent; onClicked: Ui.calendarOpen = false }

    Glass {
        id: panel
        level: 2
        radius: 22 * Theme.s
        width: 360 * Theme.s
        height: col.implicitHeight + 36 * Theme.s
        anchors.right: parent.right
        anchors.rightMargin: 16 * Theme.s
        y: (Config.o.barPosition === "bottom" ? parent.height - height - Theme.barHeight - 24 * Theme.s : Theme.barHeight + 24 * Theme.s) + (Ui.calendarOpen ? 0 : -12)
        opacity: Ui.calendarOpen ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Ui.calendarOpen ? Theme.durEnter : Theme.durExit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }
        Behavior on y { NumberAnimation { duration: Theme.durEnter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }

        MouseArea { anchors.fill: parent }
        focus: Ui.calendarOpen
        Keys.onEscapePressed: Ui.calendarOpen = false

        ColumnLayout {
            id: col
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 18 * Theme.s }
            spacing: 12 * Theme.s

            RowLayout {
                Label {
                    Layout.fillWidth: true
                    kind: "display"; font.pixelSize: 18 * Theme.s; font.weight: Font.DemiBold
                    text: { const s = win.loc.standaloneMonthName(win.month); return s.charAt(0).toUpperCase() + s.slice(1) + " " + win.year }
                }
                IconButton { icon: "chevron-right"; rotation: 180; onClicked: win.shift(-1) }
                IconButton { icon: "calendar"; tooltip: "Hoje"; onClicked: { win.month = win.today.getMonth(); win.year = win.today.getFullYear(); win.selected = win.today } }
                IconButton { icon: "chevron-right"; onClicked: win.shift(1) }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 7
                rowSpacing: 2 * Theme.s
                columnSpacing: 2 * Theme.s
                Repeater {
                    model: 7
                    Label {
                        required property int index
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        kind: "muted"
                        text: win.loc.dayName(index, Locale.ShortFormat).charAt(0).toUpperCase()
                    }
                }
                Repeater {
                    model: win.cells
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool inMonth: modelData.getMonth() === win.month
                        readonly property bool isToday: win.same(modelData, win.today)
                        readonly property bool isSel: win.same(modelData, win.selected)
                        Layout.fillWidth: true
                        implicitHeight: 38 * Theme.s
                        radius: 10 * Theme.s
                        color: isToday ? "transparent" : isSel ? Qt.alpha(Theme.accent, 0.16) : dayMouse.containsMouse ? Theme.hover : "transparent"
                        gradient: isToday ? grad : null
                        Gradient { id: grad; orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Theme.accent2 } }
                        Label {
                            anchors.centerIn: parent
                            text: parent.modelData.getDate()
                            color: parent.isToday ? Theme.inkOnAccent : parent.inMonth ? Theme.text : Qt.alpha(Theme.muted, 0.5)
                            font.weight: parent.isToday ? Font.Bold : Font.Normal
                        }
                        Rectangle {
                            visible: { Agenda.events; return Agenda.has(parent.modelData) }
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 * Theme.s }
                            width: 4 * Theme.s; height: width; radius: width / 2
                            color: parent.isToday ? Theme.inkOnAccent : Theme.hot
                        }
                        MouseArea { id: dayMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.selected = parent.modelData }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.stroke }

            Label {
                text: { const s = win.selected.toLocaleDateString(win.loc, "dddd, d 'de' MMMM"); return s.charAt(0).toUpperCase() + s.slice(1) }
                font.weight: Font.DemiBold
            }
            Label { visible: win.dayEvents.length === 0; kind: "muted"; text: "Nada marcado." }
            Repeater {
                model: win.dayEvents
                delegate: RowLayout {
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 10 * Theme.s
                    Rectangle { implicitWidth: 3; implicitHeight: 28 * Theme.s; radius: 2; color: Theme.accent2 }
                    Label { kind: "mono"; color: Theme.accent; text: modelData.time || "dia todo"; font.pixelSize: 12 * Theme.s }
                    Label { Layout.fillWidth: true; text: modelData.title }
                    IconButton { icon: "trash"; iconSize: 14 * Theme.s; implicitWidth: 28 * Theme.s; implicitHeight: 28 * Theme.s; onClicked: Agenda.remove(modelData) }
                }
            }

            // Novo compromisso: "14:30 Dentista" ou só "Aniversário da mãe"
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 40 * Theme.s
                radius: 12 * Theme.s
                color: Qt.rgba(1, 1, 1, 0.06)
                border.width: input.activeFocus ? 1 : 0
                border.color: Qt.alpha(Theme.accent, 0.5)
                Row {
                    anchors { fill: parent; leftMargin: 12 * Theme.s }
                    spacing: 10 * Theme.s
                    Icon { name: "plus"; size: 16 * Theme.s; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                    TextInput {
                        id: input
                        width: parent.width - 40 * Theme.s
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.text
                        font.family: Theme.fontBody
                        font.pixelSize: Theme.fs
                        selectionColor: Qt.alpha(Theme.accent, 0.4)
                        clip: true
                        Text {
                            visible: !parent.text
                            text: "Adicionar: 14:30 Dentista"
                            color: Theme.muted
                            font: parent.font
                        }
                        onAccepted: {
                            const m = text.match(/^\s*(\d{1,2}[:h]\d{2})\s+(.*)$/)
                            if (m) Agenda.add(win.selected, m[1].replace("h", ":").padStart(5, "0"), m[2])
                            else Agenda.add(win.selected, "", text)
                            text = ""
                        }
                    }
                }
            }
        }
    }
}
