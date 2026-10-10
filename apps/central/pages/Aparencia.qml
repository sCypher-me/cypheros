import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import qs.services
import qs.components
import "../ui"

Page {
    id: page
    readonly property var themeList: Object.keys(Theme.palettes).map(id => ({ id: id, name: Theme.palettes[id].name ?? id }))
    title: "Aparência"
    subtitle: "Tema, cores, vidro e letras. Tudo muda na hora."

    Section {
        title: "Tema"
        subtitle: "Mais temas na Loja de temas, aqui na Central"
        GridLayout {
            Layout.fillWidth: true
            Layout.margins: 12 * Theme.s
            columns: 4
            columnSpacing: 12 * Theme.s
            rowSpacing: 12 * Theme.s
            Repeater {
                model: page.themeList
                delegate: Rectangle {
                    required property var modelData
                    readonly property var pal: Theme.palettes[modelData.id]
                    readonly property bool sel: Config.o.theme === modelData.id
                    Layout.fillWidth: true
                    implicitHeight: 104 * Theme.s
                    radius: 14 * Theme.s
                    color: pal.bg
                    border.width: sel ? 2 : 1
                    border.color: sel ? pal.accent : Qt.rgba(1, 1, 1, 0.1)
                    RectangularShadow { z: -1; anchors.fill: parent; radius: parent.radius; blur: 24; visible: parent.sel; color: Qt.alpha(parent.pal.accent, 0.35) }
                    Rectangle { x: 12; y: 12; width: parent.width * 0.55; height: 10; radius: 5; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: pal.accent } GradientStop { position: 1; color: pal.accent2 } } }
                    Rectangle { x: 12; y: 30; width: parent.width - 24; height: 34; radius: 8; color: Qt.alpha(pal.glass, 0.9); border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.08) }
                    Label { anchors { left: parent.left; bottom: parent.bottom; margins: 12 } text: parent.modelData.name; color: parent.pal.text; font.weight: Font.DemiBold }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Config.o.theme = parent.modelData.id; Config.o.accent = ""; Config.o.accent2 = ""; Config.o.themeAuto = false } }
                }
            }
        }
        SettingRow {
            label: "Tema por horário"
            desc: Config.o.themeAuto ? Config.o.themeDay + " das " + Config.o.dayStart + ", " + Config.o.themeNight + " das " + Config.o.nightStart : "Troca o tema sozinho de dia e de noite"
            separator: false
            SwitchRow { checked: Config.o.themeAuto; onToggled: v => Config.o.themeAuto = v }
        }
    }

    Section {
        title: "Tema por horário"
        visible: Config.o.themeAuto
        SettingRow {
            label: "De dia"
            Chips { options: page.themeList; current: Config.o.themeDay; onChosen: id => Config.o.themeDay = id }
        }
        SettingRow {
            label: "De noite"
            Chips { options: page.themeList; current: Config.o.themeNight; onChosen: id => Config.o.themeNight = id }
        }
        SettingRow {
            label: "Começo do dia e da noite"
            Row {
                spacing: 8 * Theme.s
                Field { width: 80 * Theme.s; mono: true; text: Config.o.dayStart; onAccepted: t => { if (/^\d{1,2}:\d{2}$/.test(t)) Config.o.dayStart = t } }
                Field { width: 80 * Theme.s; mono: true; text: Config.o.nightStart; onAccepted: t => { if (/^\d{1,2}:\d{2}$/.test(t)) Config.o.nightStart = t } }
            }
        }
        SettingRow {
            label: "Luz noturna automática"
            desc: "Tons quentes à noite para cansar menos a vista"
            separator: false
            SwitchRow { checked: Config.o.nightLightAuto; onToggled: v => Config.o.nightLightAuto = v }
        }
    }

    Section {
        title: "Cores de destaque"
        subtitle: "Escolha um par ou digite o seu"
        Flow {
            Layout.fillWidth: true
            Layout.margins: 14 * Theme.s
            spacing: 10 * Theme.s
            Repeater {
                model: [
                    ["", ""], ["#38E1FF", "#A78BFA"], ["#5EEAD4", "#60A5FA"], ["#FB923C", "#F472B6"], ["#A3E635", "#22D3EE"],
                    ["#F472B6", "#818CF8"], ["#FACC15", "#FB7185"], ["#E4E4E7", "#818CF8"], ["#34D399", "#38BDF8"], ["#C084FC", "#F0ABFC"]
                ]
                delegate: Rectangle {
                    required property var modelData
                    readonly property bool isDefault: modelData[0] === ""
                    readonly property bool sel: Config.o.accent === modelData[0] && Config.o.accent2 === modelData[1]
                    width: 44 * Theme.s; height: width; radius: width / 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: isDefault ? Theme.p.accent : modelData[0] }
                        GradientStop { position: 1; color: isDefault ? Theme.p.accent2 : modelData[1] }
                    }
                    border.width: sel ? 3 : 0
                    border.color: Theme.text
                    Label { anchors.centerIn: parent; visible: parent.isDefault; text: "tema"; font.pixelSize: 10 * Theme.s; color: Theme.inkOnAccent }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { Config.o.accent = parent.modelData[0]; Config.o.accent2 = parent.modelData[1] } }
                }
            }
        }
        SettingRow {
            label: "Cor personalizada"
            desc: "Em hexadecimal, como #38E1FF"
            separator: false
            Row {
                spacing: 8 * Theme.s
                Field { width: 110 * Theme.s; mono: true; placeholder: "#38E1FF"; text: Config.o.accent; onAccepted: t => { if (/^#[0-9a-fA-F]{6}$/.test(t)) Config.o.accent = t } }
                Field { width: 110 * Theme.s; mono: true; placeholder: "#A78BFA"; text: Config.o.accent2; onAccepted: t => { if (/^#[0-9a-fA-F]{6}$/.test(t)) Config.o.accent2 = t } }
            }
        }
    }

    Section {
        title: "Vidro e efeitos"
        SettingRow {
            label: "Transparência do vidro"
            SliderRow { icon: "palette"; value: Config.o.glassOpacity; from: 0.3; to: 0.95; text: Math.round(Config.o.glassOpacity * 100) + "%"; onMoved: v => Config.o.glassOpacity = Math.round(v * 100) / 100 }
        }
        SettingRow {
            label: "Arredondamento"
            SliderRow { icon: "apps"; value: Config.o.radius; from: 0; to: 32; stepSize: 1; text: Config.o.radius + " px"; onMoved: v => Config.o.radius = v }
        }
        SettingRow {
            label: "Tamanho da interface"
            SliderRow { icon: "search"; value: Config.o.scale; from: 0.8; to: 1.5; stepSize: 0.05; text: Math.round(Config.o.scale * 100) + "%"; onMoved: v => Config.o.scale = v }
        }
        SettingRow {
            label: "Brilho nos itens ativos"
            desc: "O leve neon em volta do que está ligado"
            separator: false
            SwitchRow { checked: Config.o.glow; onToggled: v => Config.o.glow = v }
        }
    }

    Section {
        title: "Letras"
        SettingRow {
            label: "Títulos e relógio"
            Chips { options: [{ id: "Space Grotesk", name: "Space Grotesk" }, { id: "Manrope", name: "Manrope" }, { id: "JetBrains Mono", name: "JetBrains Mono" }]; current: Config.o.fontDisplay; onChosen: id => Config.o.fontDisplay = id }
        }
        SettingRow {
            label: "Textos"
            separator: false
            Chips { options: [{ id: "Manrope", name: "Manrope" }, { id: "Space Grotesk", name: "Space Grotesk" }, { id: "Noto Sans", name: "Noto Sans" }]; current: Config.o.fontBody; onChosen: id => Config.o.fontBody = id }
        }
    }
}
