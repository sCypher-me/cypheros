import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components
import qs.dados

// Linha de pacote: ícone, nome, selo da fonte, versão, descrição e ação.
// mode: search | installed | update
Rectangle {
    id: root
    property var pkg: ({})
    property string mode: "search"
    readonly property bool installed: Loja.isInstalled(pkg)
    readonly property bool selected: Loja.selected !== null && Loja.selected.id === pkg.id && Loja.selected.source === pkg.source

    implicitHeight: (pkg.desc ? 68 : 58) * Theme.s
    radius: Theme.radiusSmall + 2
    color: selected ? Qt.alpha(Theme.accent, 0.10) : mouse.containsMouse ? Theme.hover : Qt.rgba(1, 1, 1, 0.035)
    border.width: 1
    border.color: selected ? Qt.alpha(Theme.accent, 0.4) : Qt.rgba(1, 1, 1, 0.05)

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Loja.selected = root.pkg
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 12 * Theme.s; rightMargin: 12 * Theme.s }
        spacing: 12 * Theme.s

        PkgIcon {
            size: 36 * Theme.s
            icons: root.pkg.icons ?? [root.pkg.id, (root.pkg.id || "").replace(/-(bin|git|desktop)$/, "")]
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3 * Theme.s
            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * Theme.s
                Label {
                    Layout.maximumWidth: implicitWidth
                    Layout.fillWidth: true
                    text: root.pkg.name ?? ""
                    font.weight: Font.DemiBold
                    font.pixelSize: 14.5 * Theme.s
                }
                SourceBadge { source: root.pkg.source ?? "arch" }
                Label {
                    Layout.fillWidth: true
                    kind: "mono"
                    color: Theme.muted
                    font.pixelSize: 11.5 * Theme.s
                    text: root.mode === "update" ? (root.pkg.oldVersion ? root.pkg.oldVersion + "  →  " : "→ ") + (root.pkg.version ?? "")
                        : (root.pkg.repo ? root.pkg.repo + " · " : "") + (root.pkg.version ?? "")
                }
            }
            Label {
                Layout.fillWidth: true
                visible: !!root.pkg.desc
                kind: "muted"
                font.pixelSize: 12.5 * Theme.s
                text: root.pkg.desc ?? ""
            }
        }

        // votos do AUR
        Row {
            visible: root.pkg.source === "aur" && root.mode === "search"
            spacing: 4 * Theme.s
            Label { kind: "mono"; color: Theme.accent2; font.pixelSize: 12 * Theme.s; text: "▲ " + (root.pkg.votes ?? 0) }
        }

        // ações
        Row {
            spacing: 6 * Theme.s
            Rectangle {
                visible: root.mode === "search" && root.installed
                anchors.verticalCenter: parent.verticalCenter
                implicitWidth: okRow.implicitWidth + 16 * Theme.s
                implicitHeight: 26 * Theme.s
                radius: height / 2
                color: Qt.alpha(Theme.ok, 0.14)
                Row {
                    id: okRow
                    anchors.centerIn: parent
                    spacing: 4 * Theme.s
                    Icon { name: "check"; size: 13 * Theme.s; color: Theme.ok; anchors.verticalCenter: parent.verticalCenter }
                    Label { text: "Instalado"; color: Theme.ok; font.pixelSize: 12 * Theme.s; anchors.verticalCenter: parent.verticalCenter }
                }
            }
            PButton {
                visible: root.mode === "search" && !root.installed
                kind: "primary"; icon: "download"; text: "Instalar"
                onClicked: Loja.install(root.pkg)
            }
            PButton {
                visible: root.mode === "installed"
                kind: "ghost"; icon: "play"; text: "Abrir"
                onClicked: Loja.openApp(root.pkg)
            }
            PButton {
                visible: root.mode === "installed" && !Loja.isProtected(root.pkg)
                kind: "danger"; icon: "trash"; text: "Remover"
                onClicked: Loja.remove(root.pkg)
            }
        }
    }

    Behavior on color { ColorAnimation { duration: Theme.durFast } }
}
