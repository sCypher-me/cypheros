import QtQuick
import QtQuick.Layouts
import qs.services

// Base das páginas: entra deslizando de leve quando vira a página atual.
Item {
    id: root
    readonly property bool current: StackLayout.isCurrentItem
    property real shift: 0

    onCurrentChanged: if (current) enter.restart()

    transform: Translate { y: root.shift }

    ParallelAnimation {
        id: enter
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: Theme.durEnter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter }
        NumberAnimation { target: root; property: "shift"; from: 14 * Theme.s; to: 0; duration: Theme.durEnter; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.easeEnter }
    }
}
