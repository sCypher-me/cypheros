pragma Singleton
import QtQuick
import Quickshell

// Estado da interface: o que está aberto agora.
Singleton {
    id: root
    property bool launcherOpen: false
    property string launcherMode: "apps"   // apps | clip | emoji | ia
    property bool calendarOpen: false
    property bool controlOpen: false
    property bool powerOpen: false
    property bool welcomeOpen: false
    property bool overviewOpen: false
    property bool captureOpen: false
    property bool rulerOpen: false
    property bool updatesOpen: false
    property bool locked: false
    property string osdKind: ""       // volume | brightness
    property real osdValue: 0
    property int osdSerial: 0

    function closeAll() { launcherOpen = false; controlOpen = false; powerOpen = false; calendarOpen = false; overviewOpen = false; captureOpen = false; rulerOpen = false; updatesOpen = false }
    function toggleUpdates() { const v = !updatesOpen; closeAll(); updatesOpen = v }
    function toggleOverview() { const v = !overviewOpen; closeAll(); overviewOpen = v }
    function toggleCapture() { const v = !captureOpen; closeAll(); captureOpen = v }
    function toggleRuler() { const v = !rulerOpen; closeAll(); rulerOpen = v }
    function toggleLauncher(mode) {
        mode = mode || "apps"
        const v = !(launcherOpen && launcherMode === mode)
        closeAll()
        launcherMode = mode
        launcherOpen = v
    }
    function toggleCalendar() { const v = !calendarOpen; closeAll(); calendarOpen = v }
    function toggleControl() { const v = !controlOpen; closeAll(); controlOpen = v }
    function togglePower() { const v = !powerOpen; closeAll(); powerOpen = v }
    function showOsd(kind, value) { osdKind = kind; osdValue = value; osdSerial++ }
}
