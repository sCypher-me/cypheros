import QtQuick
import qs.components

Row {
    id: root
    property bool checked: false
    signal toggled(bool v)
    PSwitch { checked: root.checked; onToggled: v => root.toggled(v) }
}
