pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Configuração única do CypherOS: ~/.config/cypheros/config.json
// Qualquer mudança no arquivo é aplicada na hora.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/cypheros"
    property alias o: adapter

    function save() { file.writeAdapter() }

    FileView {
        id: file
        path: root.dir + "/config.json"
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) writeAdapter()
        }

        JsonAdapter {
            id: adapter

            // Aparência
            property string theme: "prisma"          // prisma | oceano | por-do-sol | grafite
            property string accent: ""               // vazio = cor do tema
            property string accent2: ""
            property real glassOpacity: 0.62
            property int radius: 18
            property bool glow: true
            property string fontDisplay: "Space Grotesk"
            property string fontBody: "Manrope"
            property string fontMono: "JetBrains Mono"
            property real scale: 1.0

            // Barra
            property string barPosition: "top"       // top | bottom
            property bool barFloating: true
            property bool showWindowTitle: true
            property bool showSysStats: false

            // Dock
            property bool dock: true
            property bool dockAutoHide: false
            property list<string> pinnedApps: ["firefox", "org.gnome.Nautilus", "cypher-term", "cypheros-loja"]

            // Wallpaper
            property string wallpaperMode: "shader"  // shader | image | video
            property string wallpaperShader: "aurora" // aurora | nebulosa | particulas | ondas | pulso
            property string wallpaperImage: ""
            property string wallpaperVideo: ""
            property real wallpaperSpeed: 1.0
            property bool wallpaperGrid: true
            property bool wallpaperMusic: true       // wallpaper reage à música

            // Widgets da área de trabalho
            property bool widgetClock: true
            property bool widgetMedia: true
            property bool widgetSystem: true

            // Notificações
            property bool doNotDisturb: false
            property int notificationTimeout: 6000

            // Clima e widgets extras
            property string weatherCity: ""          // vazio = descobre pela internet
            property bool widgetWeather: true
            property bool widgetNotes: true

            // Modo foco (Pomodoro)
            property int focusMinutes: 25
            property int breakMinutes: 5

            // Perfis de uso: cada um muda tema, wallpaper, notificações e abre apps
            property string profile: "padrao"
            property var profiles: ({
                "padrao":   { name: "Padrão",   icon: "logo",     theme: "prisma",   wallpaper: "aurora",     dnd: false, game: false, focus: false, apps: [] },
                "trabalho": { name: "Trabalho", icon: "terminal", theme: "oceano",   wallpaper: "ondas",      dnd: false, game: false, focus: false, apps: ["firefox"] },
                "estudo":   { name: "Estudo",   icon: "moon",     theme: "grafite",  wallpaper: "particulas", dnd: true,  game: false, focus: true,  apps: [] },
                "jogo":     { name: "Jogo",     icon: "bolt",     theme: "prisma",   wallpaper: "aurora",     dnd: true,  game: true,  focus: false, apps: ["steam"] }
            })

            // Tema por horário
            property bool themeAuto: false
            property string themeDay: "prisma"
            property string themeNight: "grafite"
            property string dayStart: "06:30"
            property string nightStart: "18:30"
            property bool nightLightAuto: true

            // Sons do sistema
            property bool sounds: true
            property real soundVolume: 0.6

            // Tela, teclado e mouse (a Central grava em ~/.config/hypr/central.conf)
            property string kbLayout: "br"
            property string kbVariant: ""
            property real mouseSensitivity: 0
            property bool naturalScroll: true
            property bool tapToClick: true
            property var monitors: ({})              // { "eDP-1": { mode: "1920x1080@60", scale: 1.25 } }

            // Assistente de IA (a chave fica em ~/.config/cypheros/ia-chave)
            property string aiProvider: "anthropic"   // anthropic | ollama | openai
            property string aiModel: ""               // vazio = padrão do provedor
            property string aiEndpoint: ""

            // Loja de temas da comunidade (um repositório com index.json)
            property string themeStoreUrl: "https://raw.githubusercontent.com/sCypher-me/cypheros-temas/main/"

            // Geral
            property string userName: ""
            property bool use24h: true
            property string locale: "pt-BR"
        }
    }
}
