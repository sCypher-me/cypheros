import QtQuick
import QtQuick.Layouts
import qs.services
import qs.components

// Linha com controle deslizante entre from e to; text mostra o valor formatado.
Row {
    id: root
    property real value: 0
    property real from: 0
    property real to: 1
    property real stepSize: 0
    property string icon: ""
    property string text: ""
    signal moved(real v)
    Row {
        spacing: 10 * Theme.s
        PSlider {
            width: 220 * Theme.s
            icon: root.icon || "settings"
            showValue: false
            value: (root.value - root.from) / (root.to - root.from)
            onMoved: v => {
                let x = root.from + v * (root.to - root.from)
                if (root.stepSize > 0) x = Math.round(x / root.stepSize) * root.stepSize
                root.moved(x)
            }
        }
        Label { anchors.verticalCenter: parent.verticalCenter; kind: "mono"; width: 64 * Theme.s; horizontalAlignment: Text.AlignRight; text: root.text; color: Theme.accent }
    }
}
