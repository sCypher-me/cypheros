pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Notas rápidas da área de trabalho: ~/.config/cypheros/notas.md
Singleton {
    id: root
    property string text: ""
    property bool _loaded: false

    function save(t) {
        text = t
        saver.restart()
    }

    Timer { id: saver; interval: 600; onTriggered: file.setText(root.text) }

    FileView {
        id: file
        path: Config.dir + "/notas.md"
        onLoaded: { if (!root._loaded) { root.text = text(); root._loaded = true } }
        onLoadFailed: root._loaded = true
    }
}
