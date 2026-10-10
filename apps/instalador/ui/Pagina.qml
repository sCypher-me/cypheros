import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Base de cada passo: título grande, frase de apoio e o conteúdo embaixo.
// Em telas baixas (notebook pequeno) o conteúdo rola em vez de cortar.
Item {
    id: root
    property string titulo: ""
    property string subtitulo: ""
    property bool pronto: true
    property string falta: ""          // o que ainda falta, mostrado ao lado do botão Continuar
    default property alias conteudo: area.data
    signal avancar()
    signal irPara(int passo)

    Flickable {
        id: rolagem
        anchors.fill: parent
        contentHeight: Math.max(height, tudo.implicitHeight)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height + 1

        ColumnLayout {
            id: tudo
            width: rolagem.width
            height: rolagem.contentHeight
            spacing: 22 * Theme.s
            ColumnLayout {
                visible: root.titulo !== ""
                spacing: 6 * Theme.s
                Label { text: root.titulo; kind: "display"; font.pixelSize: 30 * Theme.s; font.weight: Font.Medium }
                Label { Layout.fillWidth: true; visible: text !== ""; text: root.subtitulo; kind: "muted"; font.pixelSize: 15 * Theme.s; wrapMode: Text.WordWrap; elide: Text.ElideNone }
            }
            ColumnLayout {
                id: area
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 14 * Theme.s
            }
        }
    }

    // indicador de rolagem
    Rectangle {
        visible: rolagem.interactive
        anchors.right: parent.right
        anchors.rightMargin: -18 * Theme.s
        y: rolagem.visibleArea.yPosition * rolagem.height
        width: 4 * Theme.s
        height: rolagem.visibleArea.heightRatio * rolagem.height
        radius: width / 2
        color: Qt.alpha(Theme.text, 0.25)
    }
}
