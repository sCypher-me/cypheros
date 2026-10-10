import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Página rolável da Central: título grande e as seções empilhadas.
Item {
    id: root
    property string title: ""
    property string subtitle: ""
    default property alias sections: col.data

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: col.implicitHeight + 64 * Theme.s
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: col
            x: 36 * Theme.s
            y: 28 * Theme.s
            width: Math.min(flick.width - 72 * Theme.s, 760 * Theme.s)
            spacing: 26 * Theme.s
            Column {
                Layout.fillWidth: true
                spacing: 4 * Theme.s
                Label { text: root.title; kind: "display"; font.pixelSize: 28 * Theme.s; font.weight: Font.DemiBold }
                Label { visible: root.subtitle !== ""; text: root.subtitle; kind: "muted"; font.pixelSize: 13 * Theme.s }
            }
        }
    }

    // barra de rolagem fininha
    Rectangle {
        visible: flick.contentHeight > flick.height
        x: root.width - 6; width: 3; radius: 2
        y: flick.visibleArea.yPosition * flick.height
        height: flick.visibleArea.heightRatio * flick.height
        color: Qt.alpha(Theme.text, 0.25)
    }
}
