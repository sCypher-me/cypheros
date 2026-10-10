//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1

// Central CypherOS: todas as configurações do sistema num lugar só.
// Abre com: cypher-app central [página]

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import qs.services
import qs.components

ShellRoot {
    AppWindow {
        id: win
        appTitle: "Central"
        appIcon: "settings"
        implicitWidth: 1100 * Theme.s
        implicitHeight: 740 * Theme.s

        property string current: "aparencia"
        property string query: ""
        readonly property var pages: [
            { id: "aparencia", name: "Aparência", icon: "palette", keys: "tema cor cores vidro transparência fonte letra escala arredondado brilho horário noite" },
            { id: "temas", name: "Loja de temas", icon: "star", keys: "temas loja comunidade baixar instalar compartilhar exportar cores" },
            { id: "wallpaper", name: "Wallpaper", icon: "wallpaper", keys: "fundo papel de parede animado imagem vídeo música grade velocidade" },
            { id: "painel", name: "Barra e dock", icon: "apps", keys: "barra dock widgets relógio clima notas fixar apps cidade" },
            { id: "notificacoes", name: "Notificações e sons", icon: "bell", keys: "notificação não perturbe sons volume foco pomodoro perfis" },
            { id: "conexoes", name: "Internet e Bluetooth", icon: "wifi", keys: "wifi wi-fi rede internet senha bluetooth fone parear" },
            { id: "som", name: "Som", icon: "volume", keys: "áudio saída fone caixa microfone volume apps" },
            { id: "tela", name: "Tela e teclado", icon: "brightness", keys: "monitor resolução escala hz brilho teclado layout abnt mouse touchpad rolagem" },
            { id: "seguranca", name: "Atualizações e segurança", icon: "shield", keys: "atualizar atualização snapshot restaurar voltar backup cópia segurança" },
            { id: "celular", name: "Celular", icon: "phone", keys: "celular telefone kde connect android parear bateria" },
            { id: "assistente", name: "Assistente de IA", icon: "sparkle", keys: "ia inteligência artificial claude ollama chave modelo chat" },
            { id: "sistema", name: "Sobre", icon: "logo", keys: "sistema versão hardware processador memória disco kernel boas-vindas atualizar" }
        ]
        readonly property var shown: {
            const q = query.trim().toLowerCase()
            return q ? pages.filter(p => (p.name + " " + p.keys).toLowerCase().includes(q)) : pages
        }

        // página inicial pedida pelo cypher-app (ex.: cypher-app central wallpaper)
        FileView {
            path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/cypheros-central-pagina"
            onLoaded: {
                const p = text().trim()
                if (win.pages.some(x => x.id === p)) win.current = p
                Quickshell.execDetached(["rm", "-f", path])
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // barra lateral
            ColumnLayout {
                Layout.preferredWidth: 250 * Theme.s
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.margins: 14 * Theme.s
                spacing: 4 * Theme.s

                Rectangle {
                    Layout.fillWidth: true
                    Layout.bottomMargin: 10 * Theme.s
                    implicitHeight: 38 * Theme.s
                    radius: 12 * Theme.s
                    color: Qt.rgba(1, 1, 1, 0.06)
                    border.width: search.activeFocus ? 1 : 0
                    border.color: Qt.alpha(Theme.accent, 0.5)
                    Row {
                        anchors { fill: parent; leftMargin: 12 * Theme.s }
                        spacing: 8 * Theme.s
                        Icon { name: "search"; size: 15 * Theme.s; color: Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                        TextInput {
                            id: search
                            width: parent.width - 40 * Theme.s
                            anchors.verticalCenter: parent.verticalCenter
                            color: Theme.text
                            font.family: Theme.fontBody
                            font.pixelSize: Theme.fs
                            clip: true
                            onTextChanged: { win.query = text; if (win.shown.length && !win.shown.some(p => p.id === win.current)) win.current = win.shown[0].id }
                            Keys.onEscapePressed: text = ""
                            Text { visible: !parent.text; text: "Buscar ajuste"; color: Theme.muted; font: parent.font }
                        }
                    }
                }

                Repeater {
                    model: win.shown
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool sel: win.current === modelData.id
                        Layout.fillWidth: true
                        implicitHeight: 42 * Theme.s
                        radius: 12 * Theme.s
                        color: sel ? Qt.alpha(Theme.accent, 0.14) : m.containsMouse ? Theme.hover : "transparent"
                        Rectangle {
                            visible: parent.sel
                            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                            width: 3; height: parent.height * 0.5; radius: 2
                            gradient: Gradient { GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Theme.accent2 } }
                            RectangularShadow { z: -1; anchors.fill: parent; radius: 2; blur: 10; color: Theme.glowColor(Theme.accent, 0.8) }
                        }
                        Row {
                            anchors { left: parent.left; leftMargin: 14 * Theme.s; verticalCenter: parent.verticalCenter }
                            spacing: 12 * Theme.s
                            Icon { name: modelData.icon; size: 17 * Theme.s; color: parent.parent.sel ? Theme.accent : Theme.muted; anchors.verticalCenter: parent.verticalCenter }
                            Label { text: modelData.name; anchors.verticalCenter: parent.verticalCenter; font.weight: parent.parent.sel ? Font.DemiBold : Font.Normal }
                        }
                        MouseArea { id: m; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: win.current = modelData.id }
                    }
                }
                Label { visible: win.shown.length === 0; kind: "muted"; text: "Nada encontrado."; Layout.leftMargin: 14 * Theme.s }
                Item { Layout.fillHeight: true }
                Label { kind: "muted"; font.pixelSize: 11 * Theme.s; text: "Tudo fica salvo em ~/.config/cypheros"; Layout.leftMargin: 14 * Theme.s }
            }

            Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Theme.stroke }

            Loader {
                id: pageLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                source: "pages/" + ({ aparencia: "Aparencia", temas: "Temas", wallpaper: "Wallpaper", painel: "Painel", notificacoes: "Notificacoes", conexoes: "Conexoes", som: "Som", tela: "Tela", seguranca: "Seguranca", celular: "Celular", assistente: "Assistente", sistema: "Sistema" })[win.current] + ".qml"
                opacity: status === Loader.Ready ? 1 : 0
                onSourceChanged: { opacity = 0; fadeIn.restart() }
                NumberAnimation { id: fadeIn; target: pageLoader; property: "opacity"; from: 0; to: 1; duration: Theme.durEnter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter }
            }
        }
    }
}
