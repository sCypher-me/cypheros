import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.dados

// Painel lateral com os detalhes do pacote escolhido e as ações Instalar / Remover / Abrir.
Item {
    id: root
    readonly property var pkg: Loja.selected
    readonly property bool open: pkg !== null
    readonly property bool installed: open && Loja.isInstalled(pkg)
    property var shown: null      // mantém o conteúdo enquanto o painel sai

    onPkgChanged: if (pkg) shown = pkg

    // o que vai rodar no terminal, para o usuário saber antes
    readonly property string preview: {
        const p = shown
        if (!p) return ""
        if (Loja.isInstalled(p) && Loja.isProtected(p)) return "pacote essencial do sistema: melhor não remover"
        if (Loja.isInstalled(p)) return p.source === "flatpak" ? "flatpak uninstall -y " + p.id : "sudo pacman -Rns " + p.id
        if (p.source === "flatpak") return "flatpak install -y flathub " + p.id
        if (p.source === "aur") return Loja.helper !== "" ? Loja.helper + " -S --needed " + p.id : "precisa do paru (ajudante do AUR)"
        return "sudo pacman -S --needed " + p.id
    }

    // fundo: clicar fora fecha
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.016, 0.024, 0.055, 0.35)
        opacity: root.open ? 1 : 0
        visible: opacity > 0
        MouseArea { anchors.fill: parent; enabled: root.open; onClicked: Loja.selected = null }
        Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
    }

    Glass {
        id: card
        level: 2
        width: Math.min(380 * Theme.s, root.width - 40 * Theme.s)
        anchors { top: parent.top; bottom: parent.bottom; margins: 14 * Theme.s }
        x: root.open ? root.width - width - 14 * Theme.s : root.width + 30 * Theme.s
        opacity: root.open ? 1 : 0
        visible: opacity > 0
        Behavior on x { NumberAnimation { duration: root.open ? Theme.durEnter : Theme.durExit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }
        Behavior on opacity { NumberAnimation { duration: root.open ? Theme.durEnter : Theme.durExit; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter } }

        MouseArea { anchors.fill: parent }   // não fecha ao clicar dentro

        IconButton {
            anchors { top: parent.top; right: parent.right; margins: 12 * Theme.s }
            z: 2
            icon: "close"; iconSize: 14 * Theme.s
            implicitWidth: 32 * Theme.s; implicitHeight: 32 * Theme.s
            tooltip: "Fechar detalhes"
            onClicked: Loja.selected = null
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: 22 * Theme.s
            contentHeight: col.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: col
                width: parent.width
                spacing: 14 * Theme.s
                readonly property var p: root.shown ?? ({})

                PkgIcon {
                    Layout.topMargin: 6 * Theme.s
                    size: 76 * Theme.s
                    icons: col.p.icons ?? [col.p.id, (col.p.id || "").replace(/-(bin|git|desktop)$/, "")]
                }
                Label {
                    Layout.fillWidth: true
                    kind: "display"
                    font.pixelSize: 24 * Theme.s
                    font.weight: Font.DemiBold
                    text: col.p.name ?? ""
                    wrapMode: Text.WordWrap
                }
                RowLayout {
                    spacing: 8 * Theme.s
                    SourceBadge { source: col.p.source ?? "arch" }
                    Label { kind: "mono"; color: Theme.muted; font.pixelSize: 12 * Theme.s; text: col.p.id ?? "" }
                }
                Label {
                    Layout.fillWidth: true
                    visible: !!col.p.version || !!col.p.repo
                    kind: "muted"
                    text: (col.p.repo ? "Repositório " + col.p.repo + " · " : "") + (col.p.version ? "versão " + col.p.version : "")
                }
                Label {
                    Layout.fillWidth: true
                    text: col.p.desc || "Sem descrição."
                    wrapMode: Text.WordWrap
                    elide: Text.ElideNone
                    color: Qt.alpha(Theme.text, 0.9)
                    lineHeight: 1.15
                }

                // dados do AUR
                RowLayout {
                    visible: col.p.source === "aur" && col.p.votes !== undefined
                    spacing: 16 * Theme.s
                    Column {
                        Label { kind: "display"; font.pixelSize: 18 * Theme.s; color: Theme.accent2; text: String(col.p.votes ?? 0) }
                        Label { kind: "muted"; text: "votos" }
                    }
                    Column {
                        Label { kind: "display"; font.pixelSize: 18 * Theme.s; color: Theme.accent; text: Number(col.p.popularity ?? 0).toFixed(2).replace(".", ",") }
                        Label { kind: "muted"; text: "popularidade" }
                    }
                }
                Label {
                    Layout.fillWidth: true
                    visible: !!col.p.outOfDate
                    color: Theme.hot
                    wrapMode: Text.WordWrap
                    text: "Este pacote foi marcado como desatualizado no AUR."
                }
                Label {
                    Layout.fillWidth: true
                    visible: col.p.source === "aur"
                    kind: "muted"
                    wrapMode: Text.WordWrap
                    elide: Text.ElideNone
                    text: "Pacotes do AUR são feitos pela comunidade. Eles são compilados no seu computador; confira o PKGBUILD se tiver dúvida."
                }

                // outras fontes (destaques)
                ColumnLayout {
                    visible: (col.p.alternatives ?? []).length > 1
                    spacing: 8 * Theme.s
                    Label { kind: "muted"; text: "Instalar a partir de" }
                    Flow {
                        Layout.fillWidth: true
                        spacing: 8 * Theme.s
                        Repeater {
                            model: col.p.alternatives ?? []
                            delegate: Rectangle {
                                required property var modelData
                                readonly property bool sel: modelData.source === col.p.source
                                width: chipRow.implicitWidth + 22 * Theme.s
                                height: 30 * Theme.s
                                radius: height / 2
                                color: sel ? Qt.alpha(Theme.accent, 0.16) : chipMouse.containsMouse ? Theme.hover : Qt.rgba(1, 1, 1, 0.06)
                                border.width: sel ? 1 : 0
                                border.color: Qt.alpha(Theme.accent, 0.5)
                                Row {
                                    id: chipRow
                                    anchors.centerIn: parent
                                    spacing: 6 * Theme.s
                                    Label { text: Loja.sourceLabel(modelData.source); font.pixelSize: 13 * Theme.s; anchors.verticalCenter: parent.verticalCenter }
                                    Icon { visible: Loja.isInstalled(modelData); name: "check"; size: 13 * Theme.s; color: Theme.ok; anchors.verticalCenter: parent.verticalCenter }
                                }
                                MouseArea {
                                    id: chipMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Loja.selected = Loja.featuredPkg(col.p.entry, modelData)
                                }
                            }
                        }
                    }
                }

                Item { implicitHeight: 4 * Theme.s }

                // situação
                RowLayout {
                    visible: root.installed
                    spacing: 6 * Theme.s
                    Icon { name: "check"; size: 16 * Theme.s; color: Theme.ok }
                    Label { color: Theme.ok; text: "Instalado neste computador" }
                }

                // aviso: AUR sem ajudante
                Rectangle {
                    Layout.fillWidth: true
                    visible: col.p.source === "aur" && Loja.helper === "" && !root.installed && Loja.toolsReady
                    implicitHeight: helpCol.implicitHeight + 24 * Theme.s
                    radius: Theme.radiusSmall
                    color: Qt.alpha(Theme.accent2, 0.10)
                    border.width: 1
                    border.color: Qt.alpha(Theme.accent2, 0.35)
                    ColumnLayout {
                        id: helpCol
                        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 * Theme.s }
                        spacing: 8 * Theme.s
                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            elide: Text.ElideNone
                            text: "Para instalar do AUR, o CypherOS usa o paru. Ele ainda não está instalado."
                        }
                        PButton { text: "Instalar o paru"; icon: "terminal"; onClicked: Loja.installParu() }
                    }
                }

                // ações
                Flow {
                    Layout.fillWidth: true
                    spacing: 8 * Theme.s
                    PButton {
                        visible: !root.installed
                        big: true; kind: "primary"; icon: "download"; text: "Instalar"
                        onClicked: Loja.install(root.shown)
                    }
                    PButton {
                        visible: root.installed
                        big: true; kind: "primary"; icon: "play"; text: "Abrir"
                        onClicked: Loja.openApp(root.shown)
                    }
                    PButton {
                        visible: root.installed && !Loja.isProtected(root.shown)
                        big: true; kind: "danger"; icon: "trash"; text: "Remover"
                        onClicked: Loja.remove(root.shown)
                    }
                }

                // comando que vai rodar
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: cmd.implicitHeight + 18 * Theme.s
                    radius: Theme.radiusSmall
                    color: Qt.rgba(0, 0, 0, 0.25)
                    border.width: 1
                    border.color: Theme.stroke
                    Label {
                        id: cmd
                        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 * Theme.s }
                        kind: "mono"
                        font.pixelSize: 11.5 * Theme.s
                        color: Theme.muted
                        wrapMode: Text.WrapAnywhere
                        elide: Text.ElideNone
                        text: "$ " + root.preview
                    }
                }
                Label {
                    Layout.fillWidth: true
                    kind: "muted"
                    wrapMode: Text.WordWrap
                    elide: Text.ElideNone
                    text: "Abre no terminal para você acompanhar e digitar a senha. Quando terminar, a lista se atualiza sozinha."
                }
            }
        }
    }
}
