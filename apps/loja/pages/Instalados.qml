import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.dados
import qs.ui

// Apps que você instalou: pacotes explícitos do pacman e apps Flatpak.
Page {
    id: root
    property string src: ""          // "" | arch | aur | flatpak

    readonly property var filtered: {
        const q = filter.text.trim().toLowerCase()
        return Loja.installedList.filter(p => (src === "" || p.source === src)
            && (q === "" || p.name.toLowerCase().includes(q) || p.id.toLowerCase().includes(q)))
    }
    Connections { target: Loja; function onClearRequested() { filter.clear() } }

    function count(s) { return Loja.installedList.filter(p => p.source === s).length }

    ColumnLayout {
        anchors { fill: parent; leftMargin: 28 * Theme.s; rightMargin: 28 * Theme.s; topMargin: 24 * Theme.s; bottomMargin: 12 * Theme.s }
        spacing: 14 * Theme.s

        RowLayout {
            Layout.fillWidth: true
            spacing: 10 * Theme.s
            ColumnLayout {
                spacing: 2 * Theme.s
                Label { kind: "display"; font.pixelSize: 22 * Theme.s; font.weight: Font.DemiBold; text: "Instalados" }
                Label { kind: "muted"; text: Loja.installedList.length + " apps e pacotes que você escolheu instalar" }
            }
            Item { Layout.fillWidth: true }
            SearchField {
                id: filter
                Layout.preferredWidth: 260 * Theme.s
                placeholder: "Filtrar pelo nome"
            }
            IconButton { icon: "refresh"; tooltip: "Atualizar a lista"; onClicked: Loja.refreshInstalled() }
        }

        // filtro por fonte
        Row {
            spacing: 8 * Theme.s
            Repeater {
                model: [
                    { id: "", name: "Tudo", n: Loja.installedList.length },
                    { id: "arch", name: "Arch", n: root.count("arch") },
                    { id: "aur", name: "AUR", n: root.count("aur") },
                    { id: "flatpak", name: "Flatpak", n: root.count("flatpak") }
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool sel: root.src === modelData.id
                    visible: modelData.id === "" || modelData.n > 0
                    width: chip.implicitWidth + 24 * Theme.s
                    height: 30 * Theme.s
                    radius: height / 2
                    color: sel ? Theme.accent : chipMouse.containsMouse ? Theme.hover : Qt.rgba(1, 1, 1, 0.07)
                    Label {
                        id: chip
                        anchors.centerIn: parent
                        text: modelData.name + "  " + modelData.n
                        font.pixelSize: 13 * Theme.s
                        font.weight: sel ? Font.DemiBold : Font.Normal
                        color: sel ? Theme.inkOnAccent : Theme.text
                    }
                    MouseArea { id: chipMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.src = modelData.id }
                    Behavior on color { ColorAnimation { duration: Theme.durFast } }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                spacing: 6 * Theme.s
                model: root.filtered
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 600
                delegate: PkgRow {
                    required property var modelData
                    width: list.width
                    pkg: modelData
                    mode: "installed"
                }
            }

            StateMessage {
                anchors.centerIn: parent
                visible: list.count === 0 && Loja.installedLoading
                loading: true
                title: "Lendo o que está instalado…"
            }
            StateMessage {
                anchors.centerIn: parent
                visible: list.count === 0 && !Loja.installedLoading && Loja.installedError !== ""
                icon: "close"
                title: "Algo deu errado"
                subtitle: Loja.installedError
                actionText: "Tentar de novo"
                actionIcon: "restart"
                onAction: Loja.refreshInstalled()
            }
            StateMessage {
                anchors.centerIn: parent
                visible: list.count === 0 && !Loja.installedLoading && Loja.installedError === ""
                icon: filter.text !== "" ? "search" : "apps"
                title: filter.text !== "" ? "Nenhum app com “" + filter.text.trim() + "”" : "Nada por aqui ainda"
                subtitle: filter.text !== "" ? "Confira a grafia ou limpe o filtro." : "Que tal dar uma olhada nos Destaques?"
                actionText: filter.text !== "" ? "" : "Ver destaques"
                actionIcon: "apps"
                onAction: Loja.go("destaques")
            }
        }
    }
}
