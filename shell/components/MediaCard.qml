import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell.Services.Mpris
import qs.services

// Player de mídia (qualquer app que fale MPRIS: Spotify, Firefox, mpv...).
Item {
    id: root
    readonly property var players: Mpris.players.values
    readonly property MprisPlayer player: players.find(p => p.isPlaying) ?? players[0] ?? null
    visible: player !== null
    implicitHeight: col.implicitHeight

    ColumnLayout {
        id: col
        width: parent.width
        spacing: 14 * Theme.s

        RowLayout {
            spacing: 14 * Theme.s
            Layout.fillWidth: true
            Rectangle {
                implicitWidth: 58 * Theme.s; implicitHeight: implicitWidth
                radius: 14 * Theme.s
                clip: true
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.accent2 }
                    GradientStop { position: 1; color: Theme.hot }
                }
                Image { anchors.fill: parent; source: root.player?.trackArtUrl ?? ""; fillMode: Image.PreserveAspectCrop; visible: status === Image.Ready }
                Icon { anchors.centerIn: parent; name: "music"; visible: !(root.player?.trackArtUrl); color: "white" }
            }
            Column {
                Layout.fillWidth: true
                Label { width: parent.width; text: root.player?.trackTitle || "Nada tocando"; font.weight: Font.DemiBold; font.pixelSize: 15 * Theme.s }
                Label { width: parent.width; text: root.player?.trackArtist || root.player?.identity || ""; kind: "muted"; font.pixelSize: 13 * Theme.s }
            }
        }

        Item {
            Layout.fillWidth: true
            implicitHeight: 4
            visible: (root.player?.length ?? 0) > 0
            Rectangle { anchors.fill: parent; radius: 2; color: Qt.rgba(1, 1, 1, 0.12) }
            RectangularShadow { anchors.fill: prog; radius: 2; blur: 10; color: Theme.glowColor(Theme.accent, 0.6) }
            Rectangle {
                id: prog
                height: 4; radius: 2
                width: parent.width * Math.min(1, (root.player?.position ?? 0) / Math.max(1, root.player?.length ?? 1))
                gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Theme.accent2 } }
            }
            Timer { running: root.player?.isPlaying ?? false; interval: 1000; repeat: true; onTriggered: root.player.positionChanged() }
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 18 * Theme.s
            IconButton { icon: "prev"; color: "transparent"; tooltip: "Anterior"; enabled: root.player?.canGoPrevious ?? false; onClicked: root.player.previous() }
            Rectangle {
                width: 48 * Theme.s; height: width; radius: width / 2
                color: Theme.text
                RectangularShadow { z: -1; anchors.fill: parent; radius: parent.radius; blur: 20; color: Theme.glowColor(Theme.text, 0.3) }
                Icon { anchors.centerIn: parent; name: root.player?.isPlaying ? "pause" : "play"; color: Theme.bg; stroke: 2.4; size: 16 * Theme.s }
                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.player.togglePlaying() }
                Accessible.role: Accessible.Button
                Accessible.name: "Tocar ou pausar"
            }
            IconButton { icon: "next"; color: "transparent"; tooltip: "Próxima"; enabled: root.player?.canGoNext ?? false; onClicked: root.player.next() }
        }
    }
}
