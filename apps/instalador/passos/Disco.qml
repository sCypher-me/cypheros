import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.components
import "../ui"
import qs

Pagina {
    id: page
    titulo: "Onde instalar"
    subtitulo: "Escolha o disco e como o CypherOS vai ocupar o espaço."
    readonly property var d: Instalacao.discoSel
    readonly property string semLado: Instalacao.motivoSemLado(d)
    readonly property string outro: d && d.temWindows ? "Windows" : "sistema atual"
    pronto: !!d && d.tamanho >= Instalacao.minBytes && (Instalacao.modo === "apagar" || semLado === "")
    falta: !d ? "Escolha um disco" : d.tamanho < Instalacao.minBytes ? "Disco pequeno demais" : "Escolha como instalar"

    // se o modo escolhido deixou de valer ao trocar de disco, volta para "apagar"
    onDChanged: if (Instalacao.modo === "livre" && semLado !== "") Instalacao.modo = "apagar"

        ColumnLayout {
            id: col
            Layout.fillWidth: true
            spacing: 14 * Theme.s

            RowLayout {
                Label { text: "Discos"; font.weight: Font.DemiBold; Layout.fillWidth: true }
                Label { visible: Instalacao.lendoDiscos; kind: "muted"; text: "procurando..." }
                IconButton { icon: "refresh"; iconSize: 15 * Theme.s; implicitWidth: 32 * Theme.s; implicitHeight: 32 * Theme.s; tooltip: "Procurar de novo"; onClicked: Instalacao.lerDiscos() }
            }
            Label { visible: !Instalacao.lendoDiscos && Instalacao.discos.length === 0; kind: "muted"; text: "Nenhum disco encontrado. Conecte um disco e clique em procurar de novo." }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 12 * Theme.s
                rowSpacing: 12 * Theme.s
                Repeater {
                    model: Instalacao.discos
                    delegate: Opcao {
                        required property var modelData
                        readonly property bool cabe: modelData.tamanho >= Instalacao.minBytes
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        icon: modelData.tipo === "usb" ? "usb" : modelData.tipo === "nvme" ? "chip" : "disk"
                        titulo: modelData.modelo || modelData.caminho
                        descricao: Instalacao.gb(modelData.tamanho) + " · " + (modelData.tipo === "nvme" ? "SSD NVMe" : modelData.tipo === "usb" ? "USB" : "Disco") + " · " + modelData.caminho
                                 + (cabe ? "" : "\nPequeno demais: são precisos 20 GB")
                        selo: modelData.temWindows ? "tem Windows" : modelData.temLinux ? "tem Linux" : modelData.particoes.length ? "tem dados" : "vazio"
                        corSelo: modelData.temWindows ? "#60A5FA" : modelData.particoes.length ? Theme.hot : Theme.ok
                        habilitado: cabe
                        escolhido: Instalacao.disco === modelData.caminho
                        onClicked: Instalacao.disco = modelData.caminho
                    }
                }
            }

            // ------------------------------------------------ como fica o disco
            ColumnLayout {
                visible: !!page.d
                Layout.fillWidth: true
                Layout.topMargin: 6 * Theme.s
                spacing: 8 * Theme.s
                Barra { rotulo: "Agora"; disco: page.d; depois: false }
                Barra { rotulo: "Depois"; disco: page.d; depois: true }
            }

            Label { visible: !!page.d; Layout.topMargin: 6 * Theme.s; text: "Como instalar"; font.weight: Font.DemiBold }
            Opcao {
                visible: !!page.d
                Layout.fillWidth: true
                perigo: true
                icon: "trash"
                titulo: "Apagar o disco e instalar"
                descricao: page.d ? "Tudo o que está em " + (page.d.modelo || page.d.caminho) + " será apagado, incluindo outros sistemas e arquivos. Ideal para um disco só do CypherOS." : ""
                escolhido: Instalacao.modo === "apagar"
                onClicked: Instalacao.modo = "apagar"
            }
            Opcao {
                visible: !!page.d
                Layout.fillWidth: true
                icon: "apps"
                titulo: "Instalar ao lado do " + page.outro
                descricao: page.semLado === ""
                    ? "Usa os " + Instalacao.gb(page.d.livre) + " livres sem tocar no que já existe. Ao ligar o computador você escolhe qual sistema abrir."
                    : page.semLado
                selo: page.semLado === "" ? "seguro" : ""
                corSelo: Theme.ok
                habilitado: page.semLado === ""
                escolhido: Instalacao.modo === "livre"
                onClicked: Instalacao.modo = "livre"
            }
            // dica para liberar espaço no Windows
            RowLayout {
                visible: !!page.d && page.d.temWindows && page.semLado !== "" && Instalacao.checagem.uefi
                Layout.fillWidth: true
                spacing: 10 * Theme.s
                Icon { Layout.alignment: Qt.AlignTop; name: "sparkle"; size: 16 * Theme.s; color: Theme.accent2 }
                Label {
                    Layout.fillWidth: true; wrapMode: Text.WordWrap; elide: Text.ElideNone; kind: "muted"; font.pixelSize: 13 * Theme.s
                    text: "Quer manter o Windows? Ligue o computador no Windows, abra o \"Gerenciamento de Disco\", clique com o botão direito no disco C: e escolha \"Diminuir volume\". Deixe pelo menos 20 GB livres e volte aqui."
                }
            }

            // ------------------------------------------------ criptografia
            Rectangle {
                visible: !!page.d && Instalacao.checagem.uefi
                Layout.fillWidth: true
                Layout.topMargin: 4 * Theme.s
                implicitHeight: cr.implicitHeight + 28 * Theme.s
                radius: 18 * Theme.s
                color: Qt.rgba(1, 1, 1, 0.04)
                border.width: 1; border.color: Instalacao.criptografar ? Qt.alpha(Theme.accent2, 0.5) : Theme.stroke
                RowLayout {
                    id: cr
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 16 * Theme.s }
                    spacing: 14 * Theme.s
                    Rectangle {
                        implicitWidth: 42 * Theme.s; implicitHeight: 42 * Theme.s; radius: 12 * Theme.s
                        color: Qt.alpha(Theme.accent2, 0.12)
                        Icon { anchors.centerIn: parent; name: "lock"; size: 20 * Theme.s; color: Theme.accent2 }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3
                        Label { text: "Proteger com criptografia"; font.weight: Font.DemiBold; font.pixelSize: 15 * Theme.s }
                        Label {
                            Layout.fillWidth: true; wrapMode: Text.WordWrap; elide: Text.ElideNone; kind: "muted"; font.pixelSize: 13 * Theme.s
                            text: "Seus arquivos ficam ilegíveis se o computador for perdido ou roubado. Ao ligar, o CypherOS pede a sua senha."
                        }
                    }
                    PSwitch { checked: Instalacao.criptografar; onToggled: v => Instalacao.criptografar = v }
                }
            }
        }

    // barra que desenha as partições do disco (antes) ou o resultado (depois)
    component Barra: RowLayout {
        id: barra
        property string rotulo: ""
        property var disco: null
        property bool depois: false
        Layout.fillWidth: true
        spacing: 12 * Theme.s

        readonly property var partes: {
            if (!disco) return []
            const total = disco.tamanho
            const cy = { nome: "CypherOS", cor: "cypher" }
            if (depois && Instalacao.modo === "apagar") return [Object.assign({ tam: total }, cy)]
            const out = disco.particoes.map(p => ({
                nome: p.windows ? "Windows" : p.esp ? "Boot" : p.rotulo || p.fs || "Partição",
                tam: p.tamanho,
                cor: p.windows ? "#60A5FA" : p.esp ? "#64748B" : p.fs === "ext4" || p.fs === "btrfs" ? "#34D399" : "#A1A1AA"
            }))
            if (disco.livre > 0) out.push(depois ? Object.assign({ tam: disco.livre }, cy) : { nome: "Livre", tam: disco.livre, cor: "livre" })
            return out
        }

        Label { Layout.preferredWidth: 60 * Theme.s; kind: "muted"; text: barra.rotulo }
        Rectangle {
            id: trilho
            Layout.fillWidth: true
            implicitHeight: 34 * Theme.s
            radius: 10 * Theme.s
            color: Qt.rgba(1, 1, 1, 0.04)
            clip: true
            Row {
                anchors.fill: parent
                spacing: 2
                Repeater {
                    model: barra.partes
                    delegate: Rectangle {
                        required property var modelData
                        readonly property real total: barra.partes.reduce((a, p) => a + p.tam, 0)
                        // cada pedaço tem um mínimo visível e divide o resto pelo tamanho
                        width: 6 * Theme.s + Math.max(0, trilho.width - barra.partes.length * (6 * Theme.s + 2)) * modelData.tam / total
                        height: trilho.height
                        radius: 8 * Theme.s
                        color: modelData.cor === "livre" ? "transparent" : modelData.cor === "cypher" ? Theme.accent : modelData.cor
                        opacity: modelData.cor === "cypher" ? 1 : 0.75
                        border.width: modelData.cor === "livre" ? 1 : 0
                        border.color: Theme.strokeStrong
                        gradient: modelData.cor === "cypher" ? g : null
                        Gradient { id: g; orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Theme.accent2 } }
                        Label {
                            anchors.centerIn: parent
                            width: parent.width - 10
                            horizontalAlignment: Text.AlignHCenter
                            visible: parent.width > 70 * Theme.s
                            text: modelData.nome + " · " + Instalacao.gb(modelData.tam)
                            font.pixelSize: 11 * Theme.s
                            font.weight: Font.DemiBold
                            color: modelData.cor === "livre" ? Theme.muted : Theme.inkOnAccent
                        }
                    }
                }
            }
        }
    }
}
