//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1

// Instalador do CypherOS: tudo pelo mouse, sem digitar comando nenhum.
// Abre sozinho na sessão ao vivo da ISO (e pelo ícone "Instalar o CypherOS" no dock).

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.services
import qs.components
import "ui"
import qs

ShellRoot {
    AppWindow {
        id: win
        appTitle: "Instalar o CypherOS"
        appIcon: "download"
        closable: Instalacao.estado !== "instalando"
        // cabe em telas pequenas (ex.: notebook 1366x768)
        readonly property var tela: Quickshell.screens.length ? Quickshell.screens[0] : null
        implicitWidth: Math.min(1120 * Theme.s, tela ? tela.width - 40 : 1120)
        implicitHeight: Math.min(760 * Theme.s, tela ? tela.height - 90 : 760)

        property int passo: 0
        readonly property var passos: [
            { id: "Inicio", name: "Boas-vindas", icon: "logo" },
            { id: "Internet", name: "Internet", icon: "wifi" },
            { id: "Local", name: "Idioma e teclado", icon: "globe" },
            { id: "Disco", name: "Onde instalar", icon: "disk" },
            { id: "Conta", name: "Sua conta", icon: "profile" },
            { id: "Visual", name: "Visual", icon: "palette" },
            { id: "Resumo", name: "Revisar", icon: "check" }
        ]
        readonly property bool configurando: Instalacao.estado === "configurando"
        readonly property bool ultimo: passo === passos.length - 1

        function avancar() {
            if (!pagina.item || !pagina.item.pronto) return
            if (ultimo) Instalacao.instalar()
            else passo++
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // ------------------------------------------------ passos à esquerda
            ColumnLayout {
                Layout.preferredWidth: 250 * Theme.s
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.margins: 22 * Theme.s
                spacing: 4 * Theme.s

                Repeater {
                    model: win.passos
                    delegate: Rectangle {
                        id: it
                        required property var modelData
                        required property int index
                        readonly property bool atual: win.configurando && index === win.passo
                        readonly property bool feito: !win.configurando || index < win.passo
                        Layout.fillWidth: true
                        implicitHeight: 44 * Theme.s
                        radius: 12 * Theme.s
                        color: atual ? Qt.alpha(Theme.accent, 0.12) : m.containsMouse && podeIr ? Theme.hover : "transparent"
                        readonly property bool podeIr: win.configurando && index < win.passo
                        RowLayout {
                            anchors { fill: parent; leftMargin: 12 * Theme.s; rightMargin: 12 * Theme.s }
                            spacing: 12 * Theme.s
                            Rectangle {
                                implicitWidth: 26 * Theme.s; implicitHeight: 26 * Theme.s; radius: 13 * Theme.s
                                color: it.feito ? Theme.accent : "transparent"
                                border.width: it.feito ? 0 : 1.5
                                border.color: it.atual ? Theme.accent : Theme.strokeStrong
                                Icon { anchors.centerIn: parent; visible: it.feito; name: "check"; size: 13 * Theme.s; stroke: 2.6; color: Theme.inkOnAccent }
                                Label { anchors.centerIn: parent; visible: !it.feito; text: it.index + 1; font.pixelSize: 12 * Theme.s; font.weight: Font.Bold; color: it.atual ? Theme.accent : Theme.muted }
                            }
                            Label { Layout.fillWidth: true; text: it.modelData.name; color: it.atual ? Theme.text : it.feito ? Theme.text : Theme.muted; font.weight: it.atual ? Font.DemiBold : Font.Normal }
                        }
                        MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; enabled: it.podeIr; cursorShape: Qt.PointingHandCursor; onClicked: win.passo = it.index }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    Layout.topMargin: 8 * Theme.s
                    implicitHeight: 44 * Theme.s
                    radius: 12 * Theme.s
                    color: !win.configurando ? Qt.alpha(Theme.accent2, 0.14) : "transparent"
                    RowLayout {
                        anchors { fill: parent; leftMargin: 12 * Theme.s; rightMargin: 12 * Theme.s }
                        spacing: 12 * Theme.s
                        Rectangle {
                            implicitWidth: 26 * Theme.s; implicitHeight: 26 * Theme.s; radius: 13 * Theme.s
                            color: Instalacao.estado === "pronto" ? Theme.ok : "transparent"
                            border.width: Instalacao.estado === "pronto" ? 0 : 1.5
                            border.color: win.configurando ? Theme.strokeStrong : Theme.accent2
                            Icon { anchors.centerIn: parent; name: Instalacao.estado === "pronto" ? "check" : "download"; size: 13 * Theme.s; stroke: 2.2; color: Instalacao.estado === "pronto" ? Theme.inkOnAccent : win.configurando ? Theme.muted : Theme.accent2 }
                        }
                        Label { Layout.fillWidth: true; text: "Instalação"; color: win.configurando ? Theme.muted : Theme.text; font.weight: win.configurando ? Font.Normal : Font.DemiBold }
                    }
                }

                Item { Layout.fillHeight: true }
                Label { kind: "muted"; text: "CypherOS " + (Instalacao.checagem.versao || "") }
                Label { kind: "muted"; text: "baseado no Arch Linux"; opacity: 0.7 }
            }

            Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Theme.stroke }

            // ------------------------------------------------ conteúdo
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Loader {
                    id: pagina
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 34 * Theme.s
                    source: win.configurando ? "passos/" + win.passos[win.passo].id + ".qml"
                          : Instalacao.estado === "instalando" ? "passos/Progresso.qml" : "passos/Fim.qml"
                    // troca de página com um deslizar suave
                    onLoaded: { entrada.restart() }
                    ParallelAnimation {
                        id: entrada
                        NumberAnimation { target: pagina.item; property: "opacity"; from: 0; to: 1; duration: Theme.durEnter; easing.type: Easing.OutCubic }
                        NumberAnimation { target: pagina.item; property: "x"; from: 24 * Theme.s; to: 0; duration: Theme.durEnter; easing.type: Easing.OutCubic }
                    }
                    Connections {
                        target: pagina.item
                        ignoreUnknownSignals: true
                        function onAvancar() { win.avancar() }
                        function onIrPara(i) { win.passo = i }
                    }
                }

                // navegação
                Rectangle { visible: win.configurando; Layout.fillWidth: true; implicitHeight: 1; color: Theme.stroke }
                RowLayout {
                    visible: win.configurando
                    Layout.fillWidth: true
                    Layout.margins: 20 * Theme.s
                    Layout.leftMargin: 34 * Theme.s
                    Layout.rightMargin: 34 * Theme.s
                    spacing: 12 * Theme.s
                    Botao { visible: win.passo > 0; tipo: "simples"; text: "Voltar"; onClicked: win.passo-- }
                    Botao { visible: win.passo === 0; tipo: "simples"; text: "Experimentar primeiro"; onClicked: Qt.quit() }
                    Label {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1      // ocupa só a sobra, nunca empurra os botões
                        horizontalAlignment: Text.AlignRight
                        kind: "muted"
                        text: pagina.item && !pagina.item.pronto ? (pagina.item.falta || "") : ""
                    }
                    Botao {
                        // largura fixa: o texto muda a cada passo e o botão não deve "pular"
                        Layout.preferredWidth: 190 * Theme.s
                        Layout.minimumWidth: 190 * Theme.s
                        text: win.passo === 0 ? "Começar" : win.ultimo ? "Instalar agora" : "Continuar"
                        icon: win.ultimo ? "download" : ""
                        tipo: win.ultimo && Instalacao.modo === "apagar" ? "perigo" : "principal"
                        enabled: !!pagina.item && pagina.item.pronto
                        onClicked: win.avancar()
                    }
                }
            }
        }
    }
}
