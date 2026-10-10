// Loja Cypher: instala, remove e atualiza apps do Arch, do AUR e do Flathub.
// Roda com: qs -p ~/.config/cypheros/apps/loja (ou pelo atalho da Loja)

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.services
import qs.components
import qs.dados
import qs.ui
import qs.pages

ShellRoot {
    AppWindow {
        id: win
        appTitle: "Loja Cypher"
        appIcon: "apps"
        implicitWidth: 1180 * Theme.s
        implicitHeight: 760 * Theme.s

        headerExtra: [
            IconButton {
                icon: "refresh"; iconSize: 15 * Theme.s
                implicitWidth: 34 * Theme.s; implicitHeight: 34 * Theme.s
                tooltip: "Atualizar listas"
                onClicked: { Loja.refreshAll(); Loja.toast("Listas atualizadas.") }
            }
        ]

        // ao voltar para a janela (depois do terminal), atualiza o que está instalado
        property real lastRefresh: 0
        Connections {
            target: win
            ignoreUnknownSignals: true
            function onActiveChanged() {
                if (win.active === true && Date.now() - win.lastRefresh > 5000) {
                    win.lastRefresh = Date.now()
                    Loja.refreshInstalled()
                }
            }
        }

        // atalhos de teclado
        Shortcut {
            sequence: "Ctrl+F"
            onActivated: { Loja.selected = null; Loja.go("pesquisar"); Qt.callLater(() => Loja.focusSearchRequested()) }
        }
        Shortcut {
            sequence: "Escape"
            onActivated: {
                if (Loja.needHelperDialog) Loja.needHelperDialog = false
                else if (Loja.selected !== null) Loja.selected = null
                else Loja.clearRequested()
            }
        }

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // barra lateral
            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: 224 * Theme.s
                Layout.fillWidth: false

                ColumnLayout {
                    anchors { fill: parent; margins: 14 * Theme.s }
                    spacing: 4 * Theme.s

                    Repeater {
                        model: [
                            { id: "destaques", name: "Destaques", icon: "star", hint: "" },
                            { id: "pesquisar", name: "Pesquisar", icon: "search", hint: "Ctrl+F" },
                            { id: "instalados", name: "Instalados", icon: "package", hint: "" },
                            { id: "atualizacoes", name: "Atualizações", icon: "update", hint: "" }
                        ]
                        delegate: Rectangle {
                            id: nav
                            required property var modelData
                            readonly property bool sel: Loja.page === modelData.id
                            readonly property int badge: modelData.id === "atualizacoes" ? Loja.updates.length : 0
                            Layout.fillWidth: true
                            implicitHeight: 42 * Theme.s
                            radius: Theme.radiusSmall
                            color: sel ? Qt.alpha(Theme.accent, 0.13) : navMouse.containsMouse ? Theme.hover : "transparent"
                            border.width: sel ? 1 : 0
                            border.color: Qt.alpha(Theme.accent, 0.35)

                            // marcador luminoso da página atual
                            Rectangle {
                                visible: nav.sel
                                width: 3 * Theme.s; height: parent.height * 0.5; radius: width / 2
                                anchors { left: parent.left; leftMargin: 4 * Theme.s; verticalCenter: parent.verticalCenter }
                                color: Theme.accent
                                RectangularShadow { anchors.fill: parent; radius: parent.radius; blur: 10; color: Theme.glowColor(Theme.accent, 0.8); z: -1 }
                            }

                            RowLayout {
                                anchors { fill: parent; leftMargin: 16 * Theme.s; rightMargin: 10 * Theme.s }
                                spacing: 12 * Theme.s
                                Icon { name: nav.modelData.icon; size: 17 * Theme.s; color: nav.sel ? Theme.accent : Theme.muted }
                                Label {
                                    Layout.fillWidth: true
                                    text: nav.modelData.name
                                    font.weight: nav.sel ? Font.DemiBold : Font.Normal
                                    color: nav.sel ? Theme.text : Qt.alpha(Theme.text, 0.85)
                                }
                                Rectangle {
                                    visible: nav.badge > 0
                                    implicitWidth: Math.max(implicitHeight, bn.implicitWidth + 12 * Theme.s)
                                    implicitHeight: 20 * Theme.s
                                    radius: implicitHeight / 2
                                    gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Theme.accent2 } }
                                    Label { id: bn; anchors.centerIn: parent; text: nav.badge > 99 ? "99+" : String(nav.badge); color: Theme.inkOnAccent; font.pixelSize: 11 * Theme.s; font.weight: Font.Bold }
                                }
                                Label {
                                    visible: nav.modelData.hint !== "" && navMouse.containsMouse
                                    kind: "mono"; color: Theme.muted; font.pixelSize: 10.5 * Theme.s
                                    text: nav.modelData.hint
                                }
                            }
                            MouseArea {
                                id: navMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { Loja.selected = null; Loja.go(nav.modelData.id) }
                            }
                            Behavior on color { ColorAnimation { duration: Theme.durFast } }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    // rodapé: de onde vêm os apps
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: foot.implicitHeight + 24 * Theme.s
                        radius: Theme.radiusSmall
                        color: Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: Theme.stroke
                        ColumnLayout {
                            id: foot
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 * Theme.s }
                            spacing: 6 * Theme.s
                            Label { kind: "muted"; text: "Fontes" }
                            Flow {
                                Layout.fillWidth: true
                                spacing: 6 * Theme.s
                                SourceBadge { source: "arch" }
                                SourceBadge { source: "aur"; opacity: Loja.helper !== "" ? 1 : 0.5 }
                                SourceBadge { source: "flatpak"; opacity: Loja.hasFlatpak ? 1 : 0.4 }
                            }
                            Label {
                                Layout.fillWidth: true
                                kind: "muted"
                                font.pixelSize: 11 * Theme.s
                                wrapMode: Text.WordWrap
                                elide: Text.ElideNone
                                text: !Loja.toolsReady ? "Verificando…"
                                    : (Loja.helper !== "" ? "AUR via " + Loja.helper : "AUR: instale o paru")
                                      + (Loja.hasFlatpak ? "" : " · sem Flatpak")
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillHeight: true; implicitWidth: 1; color: Theme.stroke }

            // páginas
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: Math.max(0, Loja.pages.indexOf(Loja.page))
                Destaques {}
                Pesquisar {}
                Instalados {}
                Atualizacoes {}
            }
        }

        // detalhes do pacote (desliza da direita)
        DetailPanel { anchors.fill: parent }

        // aviso: AUR precisa do paru
        Item {
            anchors.fill: parent
            visible: dlg.opacity > 0
            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(0.016, 0.024, 0.055, 0.55)
                opacity: dlg.opacity
                MouseArea { anchors.fill: parent; onClicked: Loja.needHelperDialog = false }
            }
            Glass {
                id: dlg
                level: 2
                width: Math.min(440 * Theme.s, parent.width - 40 * Theme.s)
                height: dcol.implicitHeight + 48 * Theme.s
                anchors.centerIn: parent
                opacity: Loja.needHelperDialog ? 1 : 0
                scale: Loja.needHelperDialog ? 1 : 0.94
                Behavior on opacity { NumberAnimation { duration: Loja.needHelperDialog ? Theme.durEnter : Theme.durExit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }
                Behavior on scale { NumberAnimation { duration: Loja.needHelperDialog ? Theme.durEnter : Theme.durExit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }
                MouseArea { anchors.fill: parent }

                ColumnLayout {
                    id: dcol
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 24 * Theme.s }
                    spacing: 12 * Theme.s
                    SourceBadge { source: "aur" }
                    Label { Layout.fillWidth: true; kind: "display"; font.pixelSize: 20 * Theme.s; font.weight: Font.DemiBold; wrapMode: Text.WordWrap; text: "Falta o ajudante do AUR" }
                    Label {
                        Layout.fillWidth: true
                        kind: "muted"; font.pixelSize: 13 * Theme.s
                        wrapMode: Text.WordWrap; elide: Text.ElideNone
                        text: "Apps do AUR são compilados no seu computador com a ajuda do paru. Ele ainda não está instalado. Vamos instalar agora? Um terminal vai abrir e pedir sua senha."
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 6 * Theme.s
                        spacing: 8 * Theme.s
                        Item { Layout.fillWidth: true }
                        PButton { text: "Agora não"; onClicked: Loja.needHelperDialog = false }
                        PButton { kind: "primary"; icon: "terminal"; text: "Instalar o paru"; onClicked: Loja.installParu() }
                    }
                }
            }
        }

        // aviso rápido no rodapé
        Glass {
            id: toast
            level: 1
            radius: height / 2
            width: tl.implicitWidth + 44 * Theme.s
            height: 42 * Theme.s
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height - (Loja.notice !== "" ? height + 20 * Theme.s : -10 * Theme.s)
            opacity: Loja.notice !== "" ? 1 : 0
            visible: opacity > 0
            Behavior on y { NumberAnimation { duration: Theme.durEnter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }
            Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
            property string last: ""
            Connections { target: Loja; function onNoticeChanged() { if (Loja.notice !== "") toast.last = Loja.notice } }
            Row {
                anchors.centerIn: parent
                spacing: 10 * Theme.s
                Rectangle { width: 8 * Theme.s; height: width; radius: width / 2; color: Theme.accent; anchors.verticalCenter: parent.verticalCenter }
                Label { id: tl; text: toast.last; font.pixelSize: 13 * Theme.s; anchors.verticalCenter: parent.verticalCenter }
            }
        }
    }
}
