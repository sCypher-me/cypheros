import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import "../ui"
import qs

Pagina {
    id: page
    titulo: "Tudo certo?"
    subtitulo: "Confira as escolhas. Nada foi mudado no computador até agora."
    readonly property var d: Instalacao.discoSel
    readonly property bool apagar: Instalacao.modo === "apagar"
    pronto: !!d && (!apagar || Instalacao.confirmouApagar)
    falta: "Marque a confirmação acima"
    Component.onCompleted: Instalacao.confirmouApagar = false

    readonly property var linhas: [
        { icon: "globe", nome: "Idioma", valor: (Instalacao.idiomas.find(i => i.id === Instalacao.idioma) || {}).name, passo: 0 },
        { icon: "wifi", nome: "Internet", valor: Network.connected ? Network.label : "Sem conexão", passo: 1 },
        { icon: "clock", nome: "Fuso horário", valor: Instalacao.fuso.replace(/_/g, " ") + " · " + Instalacao.horaNoFuso, passo: 2 },
        { icon: "keyboard", nome: "Teclado", valor: Instalacao.teclado.name, passo: 2 },
        { icon: "disk", nome: "Disco", valor: d ? (d.modelo || d.caminho) + " · " + Instalacao.gb(d.tamanho) : "", passo: 3 },
        { icon: apagar ? "trash" : "apps", nome: "Como", valor: apagar ? "Apagar o disco inteiro" : "Ao lado do sistema atual, usando " + (d ? Instalacao.gb(d.livre) : "") + " livres", passo: 3 },
        { icon: "lock", nome: "Criptografia", valor: Instalacao.criptografar && Instalacao.checagem.uefi ? "Ligada" : "Desligada", passo: 3 },
        { icon: "profile", nome: "Conta", valor: Instalacao.nome.trim() + " (" + Instalacao.usuario + ") no " + Instalacao.maquina, passo: 4 },
        { icon: "palette", nome: "Visual", valor: (Theme.palettes[Instalacao.tema] || {}).name + " com wallpaper " + Instalacao.wallpaper, passo: 5 }
    ]

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: lista.implicitHeight + 12 * Theme.s
        radius: 18 * Theme.s
        color: Qt.rgba(1, 1, 1, 0.04)
        border.width: 1; border.color: Theme.stroke
        ColumnLayout {
            id: lista
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 * Theme.s }
            spacing: 0
            Repeater {
                model: page.linhas
                delegate: RowLayout {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42 * Theme.s
                    Layout.leftMargin: 14 * Theme.s
                    Layout.rightMargin: 14 * Theme.s
                    spacing: 14 * Theme.s
                    Icon { name: modelData.icon; size: 16 * Theme.s; color: Theme.accent }
                    Label { Layout.preferredWidth: 120 * Theme.s; kind: "muted"; text: modelData.nome }
                    Label { Layout.fillWidth: true; text: modelData.valor || "" }
                    Label {
                        text: "Alterar"; color: Theme.accent; font.pixelSize: 13 * Theme.s
                        MouseArea { anchors.fill: parent; anchors.margins: -8; cursorShape: Qt.PointingHandCursor; onClicked: page.irPara(modelData.passo) }
                    }
                }
            }
        }
    }

    // aviso de apagar
    Rectangle {
        visible: page.apagar
        Layout.fillWidth: true
        implicitHeight: av.implicitHeight + 32 * Theme.s
        radius: 18 * Theme.s
        color: Qt.alpha(Theme.hot, 0.08)
        border.width: 1; border.color: Qt.alpha(Theme.hot, 0.45)
        ColumnLayout {
            id: av
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 * Theme.s }
            spacing: 12 * Theme.s
            RowLayout {
                spacing: 10 * Theme.s
                Icon { name: "alert"; size: 18 * Theme.s; color: Theme.hot }
                Label { text: "Tudo em " + (page.d ? page.d.modelo || page.d.caminho : "") + " será apagado"; font.weight: Font.DemiBold; color: Theme.hot }
            }
            Label {
                Layout.fillWidth: true; wrapMode: Text.WordWrap; elide: Text.ElideNone; kind: "muted"; font.pixelSize: 13 * Theme.s
                text: page.d && page.d.temWindows ? "Este disco tem o Windows. Ele e todos os arquivos dele vão sumir. Se quiser mantê-lo, volte e escolha \"Instalar ao lado\"."
                    : "Fotos, documentos e qualquer sistema neste disco vão sumir. Copie o que for importante antes."
            }
            Caixa {
                Layout.fillWidth: true
                cor: Theme.hot
                checked: Instalacao.confirmouApagar
                text: "Entendo que tudo neste disco será apagado"
                onToggled: v => Instalacao.confirmouApagar = v
            }
        }
    }

    Item { Layout.fillHeight: true }
    RowLayout {
        spacing: 10 * Theme.s
        Icon { name: "clock"; size: 15 * Theme.s; color: Theme.muted }
        Label { kind: "muted"; text: "A instalação leva de 10 a 30 minutos, dependendo da sua internet. Deixe o computador ligado na tomada." }
    }
}
