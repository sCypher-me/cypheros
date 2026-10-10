import QtQuick
import qs.services

Text {
    property string kind: "body"   // body | display | mono | muted | title
    color: kind === "muted" ? Theme.muted : Theme.text
    font.family: kind === "display" || kind === "title" ? Theme.fontDisplay : kind === "mono" ? Theme.fontMono : Theme.fontBody
    font.pixelSize: kind === "title" ? 16 * Theme.s : kind === "muted" ? 12 * Theme.s : Theme.fs
    font.weight: kind === "title" ? Font.DemiBold : Font.Normal
    elide: Text.ElideRight
    renderType: Text.NativeRendering
}
