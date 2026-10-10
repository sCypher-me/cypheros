import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.components
import "../ui"
import qs

Pagina {
    id: page
    readonly property var c: Instalacao.checagem
    readonly property bool memoriaOk: !c.ramMiB || c.ramMiB >= 1800
    pronto: Instalacao.checado && memoriaOk
    falta: !Instalacao.checado ? "Conferindo o computador..." : !memoriaOk ? "Memória insuficiente" : ""

    Item { Layout.fillHeight: true }

    // logo com brilho e anel girando devagar
    Item {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 150 * Theme.s; implicitHeight: 150 * Theme.s
        RectangularShadow { anchors.centerIn: parent; width: 90; height: 90; radius: 45; blur: 70; color: Theme.glowColor(Theme.accent, 0.5) }
        Rectangle {
            anchors.fill: parent; radius: width / 2; color: "transparent"
            border.width: 1.5; border.color: Qt.alpha(Theme.accent2, 0.35)
            Rectangle { width: 10; height: 10; radius: 5; color: Theme.accent2; x: parent.width / 2 - 5; y: -5 }
            RotationAnimation on rotation { from: 0; to: 360; duration: 14000; loops: Animation.Infinite }
        }
        Icon { anchors.centerIn: parent; name: "logo"; size: 96 * Theme.s; stroke: 1.2; color: Theme.accent }
    }
    Label { Layout.alignment: Qt.AlignHCenter; kind: "display"; font.pixelSize: 42 * Theme.s; font.weight: Font.Medium; text: "Vamos instalar o CypherOS" }
    Label {
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: 560 * Theme.s
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap; elide: Text.ElideNone
        kind: "muted"; font.pixelSize: 15 * Theme.s
        text: "São poucos passos, tudo com o mouse. Você pode voltar e mudar qualquer escolha antes de começar a instalação."
    }

    // idioma do sistema
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 10 * Theme.s
        spacing: 10 * Theme.s
        Label { Layout.alignment: Qt.AlignHCenter; kind: "muted"; text: "Idioma do sistema" }
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 8 * Theme.s
            Repeater {
                model: Instalacao.idiomas
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool sel: Instalacao.idioma === modelData.id
                    width: t.implicitWidth + 28 * Theme.s; height: 36 * Theme.s; radius: 18 * Theme.s
                    color: sel ? Qt.alpha(Theme.accent, 0.16) : im.containsMouse ? Theme.hover : Qt.rgba(1, 1, 1, 0.05)
                    border.width: sel ? 1 : 0; border.color: Qt.alpha(Theme.accent, 0.6)
                    Label { id: t; anchors.centerIn: parent; text: modelData.name; color: sel ? Theme.accent : Theme.text; font.pixelSize: 13 * Theme.s }
                    MouseArea { id: im; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Instalacao.idioma = modelData.id }
                }
            }
        }
    }

    Item { Layout.fillHeight: true }

    // avisos sobre o computador
    ColumnLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: 640 * Theme.s
        spacing: 8 * Theme.s
        Repeater {
            model: [
                { show: !Instalacao.checado, leve: true, icon: "refresh", cor: Theme.muted, txt: "Conferindo o computador..." },
                { show: Instalacao.checado && !page.c.uefi, icon: "alert", cor: Theme.hot, txt: "Este computador iniciou no modo BIOS antigo. Dá para instalar, mas só apagando o disco inteiro e sem criptografia." },
                { show: Instalacao.checado && page.c.naBateria, icon: "battery", cor: Theme.hot, txt: "Ligue o carregador: a instalação pode demorar e não deve ser interrompida." },
                { show: Instalacao.checado && !page.memoriaOk, icon: "memory", cor: Theme.hot, txt: "Este computador tem só " + Math.round(page.c.ramMiB / 1024 * 10) / 10 + " GB de memória. O CypherOS precisa de pelo menos 2 GB." }
            ].filter(a => a.show)
            delegate: RowLayout {
                required property var modelData
                spacing: 10 * Theme.s
                Icon { name: modelData.icon; size: 16 * Theme.s; color: modelData.cor }
                Label { Layout.fillWidth: true; text: modelData.txt; wrapMode: Text.WordWrap; elide: Text.ElideNone; color: modelData.leve ? Theme.muted : Theme.text; font.pixelSize: 13 * Theme.s }
            }
        }
    }
}
