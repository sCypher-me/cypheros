import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.components
import qs.dados
import qs.ui

// Atualizações do sistema (checkupdates), do AUR (paru/yay -Qua) e do Flatpak.
Page {
    id: root
    readonly property int total: Loja.updates.length
    readonly property bool anyError: Loja.upArchState === "error" || Loja.upAurState === "error" || Loja.upFlatState === "error"

    ColumnLayout {
        anchors { fill: parent; leftMargin: 28 * Theme.s; rightMargin: 28 * Theme.s; topMargin: 24 * Theme.s; bottomMargin: 12 * Theme.s }
        spacing: 14 * Theme.s

        // resumo + botão grande
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 112 * Theme.s
            radius: Theme.radius
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Qt.alpha(root.total > 0 ? Theme.accent : Theme.ok, 0.18) }
                GradientStop { position: 1; color: Qt.alpha(Theme.accent2, 0.16) }
            }
            border.width: 1
            border.color: Qt.alpha(Theme.accent, 0.25)

            RowLayout {
                anchors { fill: parent; leftMargin: 24 * Theme.s; rightMargin: 24 * Theme.s }
                spacing: 16 * Theme.s
                Rectangle {
                    implicitWidth: 56 * Theme.s; implicitHeight: implicitWidth; radius: implicitWidth / 2
                    color: Qt.alpha(root.total > 0 ? Theme.accent : Theme.ok, 0.16)
                    Spinner { anchors.centerIn: parent; visible: Loja.updatesLoading; dot: 6 * Theme.s }
                    Icon { anchors.centerIn: parent; visible: !Loja.updatesLoading; name: root.total > 0 ? "restart" : "check"; size: 24 * Theme.s; color: root.total > 0 ? Theme.accent : Theme.ok }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4 * Theme.s
                    Label {
                        Layout.fillWidth: true
                        kind: "display"; font.pixelSize: 22 * Theme.s; font.weight: Font.DemiBold
                        text: Loja.updatesLoading && root.total === 0 ? "Procurando atualizações…"
                            : root.total === 0 ? "Tudo atualizado"
                            : root.total === 1 ? "1 atualização disponível" : root.total + " atualizações disponíveis"
                    }
                    Label {
                        Layout.fillWidth: true
                        kind: "muted"
                        text: root.total === 0 && !Loja.updatesLoading ? "Seu CypherOS está em dia. Bom trabalho!"
                            : "Sistema " + Loja.upArch.length + " · AUR " + Loja.upAur.length + " · Flatpak " + Loja.upFlat.length
                    }
                }
                IconButton { icon: "history"; tooltip: "Procurar de novo"; onClicked: Loja.refreshUpdates() }
                PButton {
                    big: true; kind: "primary"; icon: "refresh"; text: "Atualizar tudo"
                    enabled: root.total > 0 || Loja.upArchState === "missing"
                    onClicked: Loja.updateAll()
                }
            }
        }

        // avisos de ferramentas que faltam
        Repeater {
            model: [
                Loja.upArchState === "missing" ? "Instale o pacote pacman-contrib para ver as atualizações do sistema aqui (o “Atualizar tudo” funciona mesmo assim)." : "",
                Loja.upAurState === "missing" && Loja.toolsReady ? "Sem paru ou yay: as atualizações do AUR não são verificadas." : "",
                root.anyError ? "Não consegui verificar algumas fontes. Confira a internet e clique em procurar de novo." : ""
            ].filter(t => t !== "")
            delegate: Label {
                required property string modelData
                Layout.fillWidth: true
                kind: "muted"
                font.pixelSize: 12.5 * Theme.s
                wrapMode: Text.WordWrap
                elide: Text.ElideNone
                text: "•  " + modelData
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
                model: Loja.updates
                boundsBehavior: Flickable.StopAtBounds
                delegate: PkgRow {
                    required property var modelData
                    width: list.width
                    pkg: modelData
                    mode: "update"
                }
            }
            StateMessage {
                anchors.centerIn: parent
                visible: list.count === 0 && Loja.updatesLoading
                loading: true
                title: "Conferindo os repositórios…"
                subtitle: "Isso pode levar alguns segundos."
            }
            StateMessage {
                anchors.centerIn: parent
                visible: list.count === 0 && !Loja.updatesLoading && Loja.updatesLoaded
                icon: "check"
                title: "Nenhuma atualização pendente"
                subtitle: "Volte mais tarde ou clique em procurar de novo."
            }
        }
    }
}
