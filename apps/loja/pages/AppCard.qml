import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.components
import qs.dados
import qs.ui

// Cartão de app em destaque.
Rectangle {
    id: root
    property var entry: ({})
    readonly property var src: Loja.installedSource(entry)        // fonte instalada ou null
    readonly property var primary: entry.sources ? entry.sources[0] : ({ source: "arch", id: "" })

    implicitHeight: 150 * Theme.s
    radius: Theme.radius
    color: mouse.containsMouse ? Qt.rgba(1, 1, 1, 0.08) : Theme.glassBase
    border.width: 1
    border.color: mouse.containsMouse ? Qt.alpha(Theme.accent, 0.35) : Theme.stroke
    scale: mouse.pressed ? 0.985 : 1

    RectangularShadow {
        z: -1
        anchors.fill: parent
        radius: parent.radius
        blur: 30
        offset.y: 8
        opacity: mouse.containsMouse ? 1 : 0
        color: Theme.glowColor(Theme.accent, 0.16)
        Behavior on opacity { NumberAnimation { duration: Theme.durFast } }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Loja.selected = Loja.featuredPkg(root.entry)
    }

    ColumnLayout {
        anchors { fill: parent; margins: 16 * Theme.s }
        spacing: 8 * Theme.s

        RowLayout {
            Layout.fillWidth: true
            spacing: 12 * Theme.s
            PkgIcon { size: 48 * Theme.s; icons: root.entry.icons ?? [] }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4 * Theme.s
                Label { Layout.fillWidth: true; text: root.entry.name ?? ""; font.weight: Font.DemiBold; font.pixelSize: 15 * Theme.s }
                SourceBadge { source: (root.src ?? root.primary).source }
            }
        }
        Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            kind: "muted"
            font.pixelSize: 12.5 * Theme.s
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            verticalAlignment: Text.AlignTop
            text: root.entry.desc ?? ""
        }
        RowLayout {
            Layout.fillWidth: true
            Item { Layout.fillWidth: true }
            PButton {
                visible: root.src === null
                kind: "primary"; icon: "download"; text: "Instalar"
                onClicked: Loja.install(Loja.featuredPkg(root.entry))
            }
            PButton {
                visible: root.src !== null
                icon: "play"; text: "Abrir"
                onClicked: Loja.openApp(Loja.featuredPkg(root.entry))
            }
        }
    }

    Behavior on color { ColorAnimation { duration: Theme.durFast } }
    Behavior on scale { NumberAnimation { duration: Theme.durFast } }
}
