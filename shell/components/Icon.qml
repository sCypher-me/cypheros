import QtQuick
import QtQuick.Shapes
import qs.services

// Ícone vetorial do conjunto CypherOS (veja services/Icons.qml).
Item {
    id: root
    property string name: "logo"
    property color color: Theme.text
    property real size: 20 * Theme.s
    property real stroke: 1.8

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        preferredRendererType: Shape.CurveRenderer
        transform: Scale { xScale: root.size / 24; yScale: root.size / 24 }

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.stroke
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: Icons.get(root.name) }
        }
    }

    Behavior on color { ColorAnimation { duration: Theme.durFast } }
}
