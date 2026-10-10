import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.components
import "../ui"
import qs

Pagina {
    id: page
    property bool detalhes: false
    property int slide: 0
    readonly property var slides: [
        { icon: "history", t: "Pontos de restauração", d: "Antes de cada atualização o CypherOS guarda uma cópia do sistema. Se algo quebrar, é só voltar no tempo pela Central." },
        { icon: "package", t: "Loja Cypher", d: "Programas do Arch, do AUR e Flatpak num lugar só, com um clique para instalar." },
        { icon: "music", t: "Wallpaper que dança", d: "Os wallpapers animados podem reagir à música que estiver tocando." },
        { icon: "sparkle", t: "Assistente no lançador", d: "Aperte SUPER + A e pergunte qualquer coisa. Ele pode até sugerir um comando e rodar para você." },
        { icon: "star", t: "Temas da comunidade", d: "Troque todas as cores do sistema, do terminal e dos apps de uma vez pela loja de temas." },
        { icon: "focus", t: "Modo foco", d: "Esconde a barra e as notificações e liga um Pomodoro. Ótimo para estudar ou trabalhar." },
        { icon: "overview", t: "Visão geral", d: "SUPER + TAB mostra todas as janelas. Arraste uma janela para outra área de trabalho." }
    ]
    Timer { interval: 7000; running: !page.detalhes; repeat: true; onTriggered: page.slide = (page.slide + 1) % page.slides.length }

    // ------------------------------------------------ porcentagem e etapa
    RowLayout {
        Layout.fillWidth: true
        spacing: 18 * Theme.s
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4 * Theme.s
            Label { text: "Instalando o CypherOS"; kind: "display"; font.pixelSize: 30 * Theme.s; font.weight: Font.Medium }
            Label { Layout.fillWidth: true; kind: "muted"; font.pixelSize: 15 * Theme.s; text: Instalacao.etapaTexto + "..." }
        }
        Label { text: Instalacao.pct + "%"; kind: "display"; font.pixelSize: 44 * Theme.s; color: Theme.accent }
    }
    Item {
        Layout.fillWidth: true
        implicitHeight: 10 * Theme.s
        Rectangle { anchors.fill: parent; radius: height / 2; color: Qt.rgba(1, 1, 1, 0.08) }
        RectangularShadow { anchors.fill: fill; radius: fill.radius; blur: 18; color: Theme.glowColor(Theme.accent, 0.55) }
        Rectangle {
            id: fill
            height: parent.height
            width: Math.max(height, parent.width * Instalacao.pct / 100)
            radius: height / 2
            gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Theme.accent2 } }
            Behavior on width { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
            // brilho correndo pela barra
            Rectangle {
                width: 60 * Theme.s; height: parent.height; radius: height / 2
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: "transparent" } GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.5) } GradientStop { position: 1; color: "transparent" } }
                NumberAnimation on x { from: -60 * Theme.s; to: fill.width; duration: 1800; loops: Animation.Infinite }
            }
            clip: true
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.topMargin: 8 * Theme.s
        spacing: 26 * Theme.s

        // etapas
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.preferredWidth: 300 * Theme.s
            spacing: 6 * Theme.s
            Repeater {
                model: Instalacao.etapas
                delegate: RowLayout {
                    required property var modelData
                    readonly property bool feita: Instalacao.etapasFeitas.includes(modelData.id)
                    readonly property bool atual: Instalacao.etapaAtual === modelData.id
                    spacing: 12 * Theme.s
                    Item {
                        implicitWidth: 20 * Theme.s; implicitHeight: 20 * Theme.s
                        Rectangle {
                            anchors.fill: parent; radius: width / 2
                            color: feita ? Theme.ok : "transparent"
                            border.width: feita ? 0 : 1.5
                            border.color: atual ? Theme.accent : Theme.strokeStrong
                            Icon { anchors.centerIn: parent; visible: feita; name: "check"; size: 11 * Theme.s; stroke: 2.8; color: Theme.inkOnAccent }
                        }
                        // anel girando na etapa atual
                        Rectangle {
                            visible: atual
                            anchors.fill: parent; radius: width / 2; color: "transparent"
                            border.width: 2; border.color: "transparent"
                            Rectangle { width: 6 * Theme.s; height: 6 * Theme.s; radius: width / 2; color: Theme.accent; x: parent.width / 2 - width / 2; y: -width / 2 + 1 }
                            RotationAnimation on rotation { running: atual; from: 0; to: 360; duration: 1100; loops: Animation.Infinite }
                        }
                    }
                    Label { text: modelData.name; color: feita || atual ? Theme.text : Theme.muted; font.weight: atual ? Font.DemiBold : Font.Normal }
                }
            }
        }

        // enquanto isso... ou os detalhes técnicos
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10 * Theme.s

            Rectangle {
                visible: !page.detalhes
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 22 * Theme.s
                color: Qt.rgba(1, 1, 1, 0.04)
                border.width: 1; border.color: Theme.stroke
                clip: true
                Rectangle {
                    width: parent.width * 0.8; height: width; radius: width / 2
                    x: parent.width * 0.45; y: -height * 0.45
                    opacity: 0.18
                    gradient: Gradient { GradientStop { position: 0; color: Theme.accent2 } GradientStop { position: 1; color: "transparent" } }
                }
                ColumnLayout {
                    id: cartao
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 34 * Theme.s }
                    spacing: 14 * Theme.s
                    readonly property var s: page.slides[page.slide]
                    Label { kind: "muted"; text: "Enquanto isso, conheça o CypherOS" }
                    Icon { name: cartao.s.icon; size: 44 * Theme.s; stroke: 1.4; color: Theme.accent }
                    Label { text: cartao.s.t; kind: "display"; font.pixelSize: 26 * Theme.s }
                    Label { Layout.fillWidth: true; text: cartao.s.d; wrapMode: Text.WordWrap; elide: Text.ElideNone; font.pixelSize: 15 * Theme.s; color: Theme.muted }
                    Behavior on opacity { NumberAnimation { duration: 300 } }
                }
                Row {
                    anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 18 * Theme.s }
                    spacing: 6 * Theme.s
                    Repeater {
                        model: page.slides.length
                        delegate: Rectangle {
                            required property int index
                            width: (index === page.slide ? 22 : 6) * Theme.s; height: 6 * Theme.s; radius: 3 * Theme.s
                            color: index === page.slide ? Theme.accent : Qt.rgba(1, 1, 1, 0.18)
                            Behavior on width { NumberAnimation { duration: Theme.durEnter } }
                        }
                    }
                }
            }

            Rectangle {
                visible: page.detalhes
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16 * Theme.s
                color: Qt.rgba(0, 0, 0, 0.3)
                border.width: 1; border.color: Theme.stroke
                ListView {
                    id: log
                    anchors { fill: parent; margins: 12 * Theme.s }
                    clip: true
                    model: Instalacao.log
                    onCountChanged: positionViewAtEnd()
                    delegate: Text {
                        required property string modelData
                        width: ListView.view.width
                        text: modelData
                        color: Theme.muted
                        font.family: Theme.fontMono
                        font.pixelSize: 11 * Theme.s
                        elide: Text.ElideRight
                    }
                }
            }

            Label {
                Layout.alignment: Qt.AlignRight
                text: page.detalhes ? "Esconder detalhes" : "Mostrar detalhes"
                color: Theme.accent; font.pixelSize: 13 * Theme.s
                MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: page.detalhes = !page.detalhes }
            }
        }
    }
}
