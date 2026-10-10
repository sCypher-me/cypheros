import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.dados
import qs.ui

// Busca ao mesmo tempo no Arch (pacman), no AUR e no Flathub.
Page {
    id: root

    function focusSearch() { field.focusField() }
    Connections {
        target: Loja
        function onFocusSearchRequested() { root.focusSearch() }
        function onClearRequested() { field.clear() }
    }
    onCurrentChanged: if (current) Qt.callLater(root.focusSearch)

    readonly property bool allFailed: Loja.archState === "error" && Loja.aurState !== "ok" && Loja.flatState !== "ok"

    ColumnLayout {
        anchors { fill: parent; leftMargin: 28 * Theme.s; rightMargin: 28 * Theme.s; topMargin: 24 * Theme.s; bottomMargin: 12 * Theme.s }
        spacing: 14 * Theme.s

        SearchField {
            id: field
            Layout.fillWidth: true
            big: true
            placeholder: "Buscar apps no Arch, no AUR e no Flathub"
            onTextChanged: Loja.search(text)
        }

        // situação de cada fonte
        Row {
            Layout.fillWidth: true
            spacing: 8 * Theme.s
            visible: Loja.query.length >= 2
            Repeater {
                model: [
                    { src: "arch", state: Loja.archState, n: Loja.resArch.length },
                    { src: "aur", state: Loja.aurState, n: Loja.resAur.length },
                    { src: "flatpak", state: Loja.flatState, n: Loja.resFlat.length }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: st.implicitWidth + 20 * Theme.s
                    height: 28 * Theme.s
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.width: 1
                    border.color: Theme.stroke
                    Row {
                        id: st
                        anchors.centerIn: parent
                        spacing: 7 * Theme.s
                        SourceBadge { source: modelData.src; anchors.verticalCenter: parent.verticalCenter }
                        Spinner { visible: modelData.state === "loading"; dot: 5 * Theme.s; anchors.verticalCenter: parent.verticalCenter }
                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: modelData.state !== "loading"
                            font.pixelSize: 12 * Theme.s
                            color: modelData.state === "error" ? Theme.hot : Theme.muted
                            text: modelData.state === "error" ? (modelData.src === "aur" ? "sem conexão" : "falhou")
                                : modelData.state === "toomany" ? "muitos resultados, seja mais específico"
                                : modelData.state === "missing" ? "Flatpak não instalado"
                                : modelData.n === 0 ? "nada" : modelData.n + (modelData.n === 1 ? " resultado" : " resultados")
                        }
                    }
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
                model: Loja.query.length >= 2 ? Loja.results : []
                boundsBehavior: Flickable.StopAtBounds
                delegate: PkgRow {
                    required property var modelData
                    width: list.width
                    pkg: modelData
                    mode: "search"
                }
                footer: Item {
                    width: list.width
                    height: Loja.results.length >= Loja.maxResults ? 44 * Theme.s : 12 * Theme.s
                    Label {
                        anchors.centerIn: parent
                        visible: Loja.results.length >= Loja.maxResults
                        kind: "muted"
                        text: "Mostrando os " + Loja.maxResults + " mais relevantes. Refine a busca para achar outros."
                    }
                }
            }

            // estados
            StateMessage {
                anchors.centerIn: parent
                visible: Loja.query.length < 2
                icon: "search"
                title: "O que você quer instalar hoje?"
                subtitle: "Digite o nome de um app (pelo menos 2 letras). Dica: Ctrl+F volta para cá, Esc limpa."
            }
            StateMessage {
                anchors.centerIn: parent
                visible: Loja.query.length >= 2 && list.count === 0 && Loja.searching
                loading: true
                title: "Procurando…"
                subtitle: "Olhando no Arch, no AUR e no Flathub ao mesmo tempo."
            }
            StateMessage {
                anchors.centerIn: parent
                visible: Loja.query.length >= 2 && list.count === 0 && !Loja.searching && !root.allFailed
                icon: "search"
                title: "Nada encontrado para “" + Loja.query + "”"
                subtitle: "Tente outro nome ou uma palavra em inglês (ex.: “editor”, “video”, “browser”)."
            }
            StateMessage {
                anchors.centerIn: parent
                visible: Loja.query.length >= 2 && list.count === 0 && !Loja.searching && root.allFailed
                icon: "wifi-off"
                title: "Não consegui buscar agora"
                subtitle: "Verifique sua conexão com a internet e tente de novo."
                actionText: "Tentar de novo"
                actionIcon: "restart"
                onAction: Loja.search(field.text)
            }
        }
    }
}
