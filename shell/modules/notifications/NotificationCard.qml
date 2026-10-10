import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import qs.services
import qs.components

// Um cartão de notificação (usado no pop-up e no histórico do painel).
Item {
    id: root
    required property Notification notif
    property bool compact: false
    property bool popup: false
    signal closed()

    readonly property bool critical: notif && notif.urgency === NotificationUrgency.Critical
    readonly property string iconPath: !notif ? "" : notif.image !== "" ? notif.image : notif.appIcon !== "" ? Quickshell.iconPath(notif.appIcon, true) : ""
    readonly property date born: new Date()

    implicitHeight: box.implicitHeight

    Rectangle {
        id: box
        width: parent.width
        implicitHeight: content.implicitHeight + 28 * Theme.s
        radius: (root.popup ? 16 : 14) * Theme.s
        color: root.popup ? "transparent" : Qt.rgba(1, 1, 1, 0.05)
        border.width: root.critical ? 1 : 0
        border.color: Qt.alpha(Theme.hot, 0.6)

        RowLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 * Theme.s }
            spacing: 12 * Theme.s

            Rectangle {
                Layout.alignment: Qt.AlignTop
                implicitWidth: (root.compact ? 32 : 40) * Theme.s
                implicitHeight: implicitWidth
                radius: 12 * Theme.s
                gradient: root.iconPath === "" ? grad : null
                color: "transparent"
                clip: true
                Gradient {
                    id: grad
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: root.critical ? Theme.hot : Theme.accent }
                    GradientStop { position: 1; color: Theme.accent2 }
                }
                Image { anchors.fill: parent; visible: root.iconPath !== ""; source: root.iconPath; sourceSize: Qt.size(80, 80); fillMode: Image.PreserveAspectCrop }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3 * Theme.s
                RowLayout {
                    Layout.fillWidth: true
                    Label { Layout.fillWidth: true; kind: "muted"; text: root.notif?.appName || "Sistema" }
                    Label { kind: "muted"; text: Qt.formatTime(root.born, "HH:mm") }
                    Icon {
                        name: "close"; size: 14 * Theme.s; color: Theme.muted
                        MouseArea { anchors.fill: parent; anchors.margins: -6; cursorShape: Qt.PointingHandCursor; onClicked: { root.notif.dismiss(); root.closed() } }
                    }
                }
                Label { Layout.fillWidth: true; text: root.notif?.summary ?? ""; font.weight: Font.DemiBold }
                Text {
                    Layout.fillWidth: true
                    visible: text !== "" && !root.compact
                    text: root.notif?.body ?? ""
                    textFormat: Text.StyledText
                    wrapMode: Text.Wrap
                    maximumLineCount: 4
                    elide: Text.ElideRight
                    color: Qt.lighter(Theme.muted, 1.15)
                    font.family: Theme.fontBody
                    font.pixelSize: 13 * Theme.s
                }
                Row {
                    visible: !root.compact && (root.notif?.actions.length ?? 0) > 0
                    spacing: 8 * Theme.s
                    topPadding: 6 * Theme.s
                    Repeater {
                        model: root.notif?.actions ?? []
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            height: 30 * Theme.s
                            width: act.implicitWidth + 24 * Theme.s
                            radius: 9 * Theme.s
                            color: index === 0 ? Qt.alpha(Theme.accent, actMouse.containsMouse ? 0.26 : 0.16) : actMouse.containsMouse ? Theme.pressed : Theme.hover
                            Label { id: act; anchors.centerIn: parent; text: parent.modelData.text; font.pixelSize: 12 * Theme.s; font.weight: Font.DemiBold; color: parent.index === 0 ? Qt.lighter(Theme.accent, 1.4) : Theme.text }
                            MouseArea { id: actMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { parent.modelData.invoke(); root.closed() } }
                        }
                    }
                }
            }
        }
    }
}
