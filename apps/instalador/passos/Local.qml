import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import "../ui"
import qs

Pagina {
    id: page
    titulo: "Onde você está e qual é o seu teclado"
    subtitulo: "O fuso foi detectado pela sua conexão. Confira se a hora bate com a do seu relógio."
    pronto: Instalacao.fuso !== "" && !!Instalacao.teclado

    property string busca: ""
    readonly property var achados: {
        const q = busca.trim().toLowerCase().replace(/ /g, "_")
        const l = Instalacao.fusos
        return q ? l.filter(z => z.toLowerCase().includes(q)).slice(0, 200) : l
    }
    function bonito(z) { const p = z.split("/"); return p[p.length - 1].replace(/_/g, " ") }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 26 * Theme.s

        // ---------------- fuso horário
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            spacing: 12 * Theme.s
            Label { text: "Fuso horário"; font.weight: Font.DemiBold }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 86 * Theme.s
                radius: 18 * Theme.s
                color: Qt.alpha(Theme.accent, 0.08)
                border.width: 1; border.color: Qt.alpha(Theme.accent, 0.4)
                RowLayout {
                    anchors { fill: parent; leftMargin: 18 * Theme.s; rightMargin: 18 * Theme.s }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Label { text: page.bonito(Instalacao.fuso); kind: "display"; font.pixelSize: 22 * Theme.s }
                        Label { kind: "muted"; text: Instalacao.fuso.replace(/_/g, " ") }
                    }
                    Item { Layout.fillWidth: true }
                    Label { text: Instalacao.horaNoFuso; kind: "display"; font.pixelSize: 34 * Theme.s; color: Theme.accent }
                }
            }
            Campo { Layout.fillWidth: true; placeholder: "Procurar cidade (ex.: Recife, Lisboa, New York)"; onEditado: t => page.busca = t }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: page.achados
                delegate: Rectangle {
                    required property string modelData
                    readonly property bool sel: Instalacao.fuso === modelData
                    width: ListView.view.width
                    height: 36 * Theme.s
                    radius: 10 * Theme.s
                    color: sel ? Qt.alpha(Theme.accent, 0.14) : fm.containsMouse ? Theme.hover : "transparent"
                    RowLayout {
                        anchors { fill: parent; leftMargin: 12 * Theme.s; rightMargin: 12 * Theme.s }
                        Label { Layout.fillWidth: true; text: page.bonito(modelData); color: sel ? Theme.accent : Theme.text }
                        Label { kind: "muted"; text: modelData.split("/")[0] }
                    }
                    MouseArea { id: fm; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Instalacao.fuso = modelData }
                }
            }
        }

        // ---------------- teclado
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            spacing: 12 * Theme.s
            Label { text: "Teclado"; font.weight: Font.DemiBold }
            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 4 * Theme.s
                model: Instalacao.teclados
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool sel: Instalacao.teclado.id === modelData.id
                    width: ListView.view.width
                    height: 44 * Theme.s
                    radius: 12 * Theme.s
                    color: sel ? Qt.alpha(Theme.accent, 0.14) : km.containsMouse ? Theme.hover : Qt.rgba(1, 1, 1, 0.03)
                    border.width: sel ? 1 : 0; border.color: Qt.alpha(Theme.accent, 0.5)
                    RowLayout {
                        anchors { fill: parent; leftMargin: 14 * Theme.s; rightMargin: 14 * Theme.s }
                        spacing: 12 * Theme.s
                        Icon { name: "keyboard"; size: 17 * Theme.s; color: sel ? Theme.accent : Theme.muted }
                        Label { Layout.fillWidth: true; text: modelData.name; color: sel ? Theme.text : Theme.text; font.weight: sel ? Font.DemiBold : Font.Normal }
                        Icon { visible: sel; name: "check"; size: 15 * Theme.s; color: Theme.accent }
                    }
                    MouseArea { id: km; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Instalacao.escolherTeclado(modelData) }
                }
            }
            Campo {
                Layout.fillWidth: true
                rotulo: "Teste o teclado"
                placeholder: "Digite aqui: ç, á, ~, @, /, ?"
                dica: "Se as letras saírem certas, o teclado está certo."
            }
        }
    }
}
