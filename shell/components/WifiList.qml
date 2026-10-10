import QtQuick
import QtQuick.Layouts
import qs.services

// Lista de redes Wi-Fi com campo de senha embutido.
ColumnLayout {
    id: root
    property string selected: ""
    spacing: 6 * Theme.s

    Component.onCompleted: Network.scan()

    RowLayout {
        Layout.fillWidth: true
        Label { Layout.fillWidth: true; kind: "muted"; text: Network.scanning ? "Procurando redes..." : Network.networks.length + " redes encontradas" }
        IconButton { icon: "restart"; iconSize: 15 * Theme.s; implicitWidth: 32 * Theme.s; implicitHeight: 32 * Theme.s; tooltip: "Procurar de novo"; onClicked: Network.scan() }
    }

    ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 120
        clip: true
        spacing: 6 * Theme.s
        model: Network.networks
        delegate: Rectangle {
            id: net
            required property var modelData
            readonly property bool open: root.selected === modelData.ssid && modelData.secure && !modelData.active
            width: ListView.view.width
            height: (open ? 104 : 52) * Theme.s
            radius: 14 * Theme.s
            color: modelData.active ? Qt.alpha(Theme.accent, 0.12) : m.containsMouse || open ? Theme.hover : Qt.rgba(1, 1, 1, 0.04)
            border.width: modelData.active ? 1 : 0
            border.color: Qt.alpha(Theme.accent, 0.4)
            clip: true
            Behavior on height { NumberAnimation { duration: Theme.durFast } }

            MouseArea {
                id: m
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (net.modelData.active) return
                    root.selected = net.modelData.ssid
                    if (!net.modelData.secure) Network.connectTo(net.modelData.ssid, "")
                    else pw.forceActiveFocus()
                }
            }

            RowLayout {
                x: 14 * Theme.s
                width: parent.width - 28 * Theme.s
                height: 52 * Theme.s
                spacing: 12 * Theme.s
                Icon { name: "wifi"; color: net.modelData.active ? Theme.accent : net.modelData.signal > 50 ? Theme.text : Theme.muted }
                Label { Layout.fillWidth: true; text: net.modelData.ssid; font.weight: net.modelData.active ? Font.DemiBold : Font.Normal }
                Label { visible: Network.connecting === net.modelData.ssid; kind: "muted"; text: "conectando..." }
                Label { visible: net.modelData.active; kind: "muted"; color: Theme.accent; text: "conectado" }
                Icon { visible: net.modelData.secure && !net.modelData.active; name: "lock"; size: 14 * Theme.s; color: Theme.muted }
            }

            Rectangle {
                visible: net.open
                x: 14 * Theme.s; y: 56 * Theme.s
                width: parent.width - 28 * Theme.s; height: 38 * Theme.s
                radius: 10 * Theme.s
                color: Qt.rgba(0, 0, 0, 0.25)
                border.width: 1
                border.color: Network.connectError ? Qt.alpha(Theme.hot, 0.6) : Theme.stroke
                TextInput {
                    id: pw
                    anchors { fill: parent; leftMargin: 12 * Theme.s; rightMargin: 12 * Theme.s }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.text
                    font.pixelSize: 14 * Theme.s
                    onAccepted: Network.connectTo(net.modelData.ssid, text)
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: pw.text === ""
                        kind: "muted"
                        color: Network.connectError ? Theme.hot : Theme.muted
                        text: Network.connectError || "Senha da rede e ENTER"
                    }
                }
            }
        }
    }
}
