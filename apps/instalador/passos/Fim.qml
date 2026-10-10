import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.components
import "../ui"
import qs

Pagina {
    id: page
    readonly property bool ok: Instalacao.estado === "pronto"
    property bool detalhes: false

    Item { Layout.fillHeight: true }

    Item {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: 130 * Theme.s; implicitHeight: 130 * Theme.s
        readonly property color cor: page.ok ? Theme.ok : Theme.hot
        RectangularShadow { anchors.centerIn: parent; width: 90; height: 90; radius: 45; blur: 60; color: Theme.glowColor(parent.cor, 0.5) }
        Rectangle {
            anchors.fill: parent; radius: width / 2
            color: Qt.alpha(parent.cor, 0.14)
            border.width: 2; border.color: parent.cor
            scale: 0.6
            NumberAnimation on scale { to: 1; duration: 600; easing.type: Easing.OutBack }
            Icon { anchors.centerIn: parent; name: page.ok ? "check" : "alert"; size: 58 * Theme.s; stroke: 2.2; color: parent.parent.cor }
        }
    }

    Label {
        Layout.alignment: Qt.AlignHCenter
        kind: "display"; font.pixelSize: 38 * Theme.s; font.weight: Font.Medium
        text: page.ok ? "O CypherOS está instalado" : "A instalação não terminou"
    }
    Label {
        Layout.alignment: Qt.AlignHCenter
        Layout.maximumWidth: 620 * Theme.s
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap; elide: Text.ElideNone
        kind: "muted"; font.pixelSize: 15 * Theme.s
        text: page.ok
            ? "Tire o pendrive e reinicie. Na primeira vez, o CypherOS mostra umas boas-vindas para você terminar de deixar tudo com a sua cara."
            : Instalacao.erroTexto
    }

    RowLayout {
        Layout.alignment: Qt.AlignHCenter
        Layout.topMargin: 14 * Theme.s
        spacing: 12 * Theme.s
        Botao { visible: page.ok; tipo: "simples"; text: "Continuar testando"; onClicked: Qt.quit() }
        Botao { visible: page.ok; text: "Reiniciar agora"; icon: "restart"; onClicked: Instalacao.reiniciar() }
        Botao { visible: !page.ok; tipo: "simples"; text: page.detalhes ? "Esconder detalhes" : "Ver detalhes"; onClicked: page.detalhes = !page.detalhes }
        Botao { visible: !page.ok; tipo: "simples"; text: "Copiar relatório"; icon: "copy"; onClicked: Instalacao.copiarRelatorio() }
        Botao {
            visible: !page.ok
            text: "Tentar de novo"
            icon: "refresh"
            onClicked: { Instalacao.estado = "configurando"; Instalacao.lerDiscos() }
        }
    }

    Rectangle {
        visible: !page.ok && page.detalhes
        Layout.fillWidth: true
        Layout.preferredHeight: 220 * Theme.s
        Layout.topMargin: 8 * Theme.s
        radius: 16 * Theme.s
        color: Qt.rgba(0, 0, 0, 0.3)
        border.width: 1; border.color: Theme.stroke
        ListView {
            anchors { fill: parent; margins: 12 * Theme.s }
            clip: true
            model: Instalacao.log.slice(-120)
            Component.onCompleted: positionViewAtEnd()
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
        visible: !page.ok
        Layout.alignment: Qt.AlignHCenter
        kind: "muted"; font.pixelSize: 12 * Theme.s
        text: "O registro completo fica em /tmp/cypher-instalar.log. \"Copiar relatório\" coloca ele na área de transferência para você me mandar."
    }

    Item { Layout.fillHeight: true }
}
