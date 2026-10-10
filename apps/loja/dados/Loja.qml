pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Cérebro da Loja Cypher: busca nas três fontes (Arch, AUR, Flatpak),
// lista o que está instalado, procura atualizações e abre o terminal para instalar/remover.
// Tudo que vem do usuário vai para os processos como argumento separado, nunca colado no comando.
Singleton {
    id: root

    // ---------- navegação ----------
    readonly property var pages: ["destaques", "pesquisar", "instalados", "atualizacoes"]
    property string page: "destaques"
    property var selected: null          // pacote aberto no painel de detalhes
    signal focusSearchRequested()
    signal clearRequested()            // Esc: limpa a busca e os filtros

    function go(p) { if (pages.indexOf(p) >= 0) page = p }

    // ---------- ferramentas disponíveis ----------
    property bool toolsReady: false
    property string terminal: ""         // cypher-term | foot
    property string helper: ""           // paru | yay | ""
    property bool hasFlatpak: false
    property bool hasCheckupdates: false
    property bool needHelperDialog: false // aviso "instale o paru"

    Process {
        running: true
        command: ["sh", "-c", "for t in cypher-term foot paru yay flatpak checkupdates; do command -v \"$t\" >/dev/null 2>&1 && echo \"$t\"; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.split("\n")
                root.terminal = t.indexOf("cypher-term") >= 0 ? "cypher-term" : "foot"
                root.helper = t.indexOf("paru") >= 0 ? "paru" : t.indexOf("yay") >= 0 ? "yay" : ""
                root.hasFlatpak = t.indexOf("flatpak") >= 0
                root.hasCheckupdates = t.indexOf("checkupdates") >= 0
                root.toolsReady = true
                root.refreshInstalled()
                if (root.page === "atualizacoes") root.refreshUpdates()
            }
        }
    }

    // ---------- avisos rápidos (toast) ----------
    property string notice: ""
    function toast(msg) { notice = msg; noticeTimer.restart() }
    Timer { id: noticeTimer; interval: 4200; onTriggered: root.notice = "" }

    // ---------- página inicial opcional ----------
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    FileView {
        path: root.runtimeDir + "/cypheros-loja-pagina"
        onLoaded: root.go(text().trim().toLowerCase())
    }

    // ---------- fim de uma ação no terminal ----------
    // o script do terminal grava a hora neste arquivo ao terminar; aí a lista é atualizada
    FileView {
        id: doneFile
        path: root.runtimeDir + "/cypheros-loja-fim"
        watchChanges: true
        onFileChanged: { reload(); root.refreshAll() }
        onLoadFailed: err => { if (err === FileViewError.FileNotFound) setText("0\n") }
    }

    function refreshAll() {
        refreshInstalled()
        if (updatesLoaded) refreshUpdates()
    }

    // Roda um script no terminal. `script` é fixo (escrito aqui); dados do usuário vão em `args` ("$1", "$@").
    function runInTerminal(script, args) {
        const tail = '; rc=$?; echo; if [ "$rc" -eq 0 ]; then echo "Tudo certo."; else echo "Algo deu errado (código $rc)."; fi; '
                   + 'date +%s > "${XDG_RUNTIME_DIR:-/tmp}/cypheros-loja-fim" 2>/dev/null; '
                   + 'printf "Pronto. Enter para fechar..."; read _'
        const cmd = [terminal || "foot", "-e", "sh", "-c", script + tail, "sh"].concat(args || [])
        Quickshell.execDetached(cmd)
    }

    function install(pkg) {
        if (!pkg) return
        if (pkg.source === "flatpak") {
            if (!hasFlatpak) { toast("O Flatpak não está instalado neste sistema."); return }
            runInTerminal('flatpak install -y flathub "$1"', [pkg.id])
        } else if (pkg.source === "aur") {
            if (helper === "") { needHelperDialog = true; return }
            runInTerminal(helper + ' -S --needed "$@"', [pkg.id])
        } else {
            runInTerminal('sudo pacman -S --needed -- "$@"', [pkg.id])
        }
        toast("Abrindo o terminal para instalar " + pkg.name + "…")
    }

    function remove(pkg) {
        if (!pkg) return
        if (pkg.source === "flatpak") runInTerminal('flatpak uninstall -y "$1"', [pkg.id])
        else runInTerminal('sudo pacman -Rns -- "$@"', [pkg.id])
        toast("Abrindo o terminal para remover " + pkg.name + "…")
    }

    function installParu() {
        needHelperDialog = false
        runInTerminal("sudo pacman -S --needed base-devel git && rm -rf /tmp/paru-bin && git clone https://aur.archlinux.org/paru-bin.git /tmp/paru-bin && cd /tmp/paru-bin && makepkg -si", [])
        toast("Instalando o paru no terminal. Depois volte aqui e instale do AUR.")
        // o paru passa a existir depois; checa de novo quando o terminal terminar
        helperCheck.running = false
        helperCheckTimer.restart()
    }
    Timer { id: helperCheckTimer; interval: 15000; repeat: true; onTriggered: if (root.helper === "") helperCheck.running = true; else stop() }
    Process {
        id: helperCheck
        command: ["sh", "-c", "command -v paru >/dev/null && echo paru || { command -v yay >/dev/null && echo yay; }"]
        stdout: StdioCollector { onStreamFinished: { const h = text.trim(); if (h !== "") { root.helper = h; helperCheckTimer.stop() } } }
    }

    function updateAll() {
        const steps = []
        steps.push('echo "== Pacotes do sistema" ; ' + (helper !== "" ? helper + " -Syu" : "sudo pacman -Syu"))
        if (hasFlatpak) steps.push('echo; echo "== Flatpak" ; flatpak update -y')
        runInTerminal(steps.join(" ; "), [])
        toast("Abrindo o terminal para atualizar tudo…")
    }

    // Abre um app instalado pelo atalho (.desktop); tenta adivinhar pelo nome do pacote.
    function openApp(pkg) {
        if (!pkg) return
        const wanted = (pkg.desktop || []).concat([pkg.id]).map(s => s.toLowerCase())
        const base = pkg.id.toLowerCase().replace(/-(bin|git|desktop|fresh|studio|stable)$/, "")
        let best = null
        for (const e of DesktopEntries.applications.values) {
            const eid = (e.id || "").toLowerCase().replace(/\.desktop$/, "")
            const bin = ((e.command ?? [])[0] || "").split("/").pop().toLowerCase()
            if (wanted.indexOf(eid) >= 0) { best = e; break }
            if (!best && (eid === base || eid.endsWith("." + base) || bin === pkg.id.toLowerCase() || bin === base)) best = e
        }
        if (best) { best.execute(); toast("Abrindo " + (best.name || pkg.name) + "…"); return }
        if (pkg.source === "flatpak") { Quickshell.execDetached(["flatpak", "run", pkg.id]); return }
        toast("Não achei um atalho para abrir " + pkg.name + ". Ele pode ser um programa de terminal.")
    }

    // ---------- o que está instalado ----------
    property var archInstalled: ({})    // nome -> versão (todos os pacotes)
    property var foreign: ({})          // nome -> true (vindos do AUR ou de fora)
    property var flatInstalled: ({})    // id -> versão
    property var installedList: []      // [{ name, id, source, version }] explícitos + flatpaks
    property bool installedLoading: false
    property string installedError: ""

    // pacotes essenciais: sem botão Remover para não quebrar o sistema
    readonly property var protectedPkgs: ["base", "base-devel", "linux", "linux-lts", "linux-zen", "linux-firmware", "systemd", "pacman", "sudo",
        "grub", "efibootmgr", "mkinitcpio", "networkmanager", "hyprland", "quickshell", "quickshell-git", "pipewire", "wireplumber", "mesa", "glibc", "bash", "coreutils"]
    function isProtected(pkg) { return pkg && pkg.source !== "flatpak" && protectedPkgs.indexOf(pkg.id) >= 0 }

    function isInstalled(pkg) {
        if (!pkg) return false
        return pkg.source === "flatpak" ? flatInstalled[pkg.id] !== undefined : archInstalled[pkg.id] !== undefined
    }
    // destaque: qualquer uma das fontes instalada? devolve a fonte ou null
    function installedSource(entry) {
        for (const s of entry.sources) if (isInstalled(s)) return s
        return null
    }

    property var _explicit: []
    property var _flats: []
    function _mergeInstalled() {
        installedList = _explicit.concat(_flats).sort((a, b) => a.name.localeCompare(b.name))
    }
    function refreshInstalled() {
        installedLoading = true
        installedError = ""
        if (!qProc.running) qProc.running = true
        if (hasFlatpak) { if (!flProc.running) flProc.running = true }
        else { _flats = []; flatInstalled = ({}) }
    }

    Process {
        id: qProc
        environment: ({ LC_ALL: "C" })
        command: ["sh", "-c", "pacman -Qe; echo ::; pacman -Qqm; echo ::; pacman -Q"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.split("::\n")
                const fr = {}
                for (const n of (parts[1] || "").split("\n")) if (n.trim()) fr[n.trim()] = true
                const all = {}
                for (const l of (parts[2] || "").split("\n")) { const [n, v] = l.trim().split(" "); if (n) all[n] = v || "" }
                const ex = []
                for (const l of (parts[0] || "").split("\n")) {
                    const [n, v] = l.trim().split(" ")
                    if (n) ex.push({ name: n, id: n, version: v || "", source: fr[n] ? "aur" : "arch", desc: "" })
                }
                root.foreign = fr
                root.archInstalled = all
                root._explicit = ex
                root._mergeInstalled()
            }
        }
        onExited: code => {
            root.installedLoading = flProc.running
            if (code !== 0 && root._explicit.length === 0) root.installedError = "Não consegui ler a lista de pacotes do pacman."
        }
    }
    Process {
        id: flProc
        environment: ({ LC_ALL: "C" })
        command: ["flatpak", "list", "--app", "--columns=name,application,version"]
        stdout: StdioCollector {
            onStreamFinished: {
                const map = {}, out = []
                for (const l of text.split("\n")) {
                    const c = l.split("\t")
                    if (c.length < 2 || !c[1]) continue
                    map[c[1]] = c[2] || ""
                    out.push({ name: c[0] || c[1], id: c[1], version: c[2] || "", source: "flatpak", desc: "" })
                }
                root.flatInstalled = map
                root._flats = out
                root._mergeInstalled()
            }
        }
        onExited: root.installedLoading = qProc.running
    }

    // ---------- atualizações ----------
    property bool updatesLoaded: false
    property var upArch: []
    property var upAur: []
    property var upFlat: []
    property string upArchState: "idle"   // idle | loading | ok | error | missing
    property string upAurState: "idle"
    property string upFlatState: "idle"
    readonly property bool updatesLoading: upArchState === "loading" || upAurState === "loading" || upFlatState === "loading"
    readonly property var updates: upArch.concat(upAur, upFlat)

    onPageChanged: if (page === "atualizacoes" && !updatesLoaded && toolsReady) refreshUpdates()

    function _parseArrow(txt, source) {
        // "nome 1.0-1 -> 1.1-1"
        const out = []
        for (const l of txt.split("\n")) {
            const m = l.trim().match(/^(\S+)\s+(\S+)\s+->\s+(\S+)/)
            if (m) out.push({ name: m[1], id: m[1], source, version: m[3], oldVersion: m[2], desc: "" })
        }
        return out
    }

    function refreshUpdates() {
        updatesLoaded = true
        if (hasCheckupdates) { upArchState = "loading"; if (!cuProc.running) cuProc.running = true }
        else { upArch = []; upArchState = "missing" }
        if (helper !== "") { upAurState = "loading"; if (!auProc.running) { auProc.command = [helper, "-Qua"]; auProc.running = true } }
        else { upAur = []; upAurState = "missing" }
        if (hasFlatpak) { upFlatState = "loading"; if (!fuProc.running) fuProc.running = true }
        else { upFlat = []; upFlatState = "missing" }
    }

    Process {
        id: cuProc
        environment: ({ LC_ALL: "C" })
        command: ["checkupdates"]
        stdout: StdioCollector { onStreamFinished: root.upArch = root._parseArrow(text, "arch") }
        // checkupdates: 0 = há atualizações, 2 = nada novo, 1 = erro
        onExited: code => root.upArchState = code === 0 || code === 2 ? "ok" : "error"
    }
    Process {
        id: auProc
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector { onStreamFinished: root.upAur = root._parseArrow(text, "aur") }
        // -Qua sai com 1 quando não há nada para atualizar
        onExited: code => root.upAurState = code === 0 || code === 1 ? "ok" : "error"
    }
    Process {
        id: fuProc
        environment: ({ LC_ALL: "C" })
        command: ["flatpak", "remote-ls", "--updates", "--app", "--columns=name,application,version"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const l of text.split("\n")) {
                    const c = l.split("\t")
                    if (c.length >= 2 && c[1]) out.push({ name: c[0] || c[1], id: c[1], source: "flatpak", version: c[2] || "", oldVersion: root.flatInstalled[c[1]] || "", desc: "" })
                }
                root.upFlat = out
            }
        }
        onExited: code => root.upFlatState = code === 0 ? "ok" : "error"
    }

    // ---------- pesquisa nas três fontes ----------
    property string query: ""
    property string _running: ""          // busca em andamento; saídas de buscas antigas são ignoradas
    property var resArch: []
    property var resAur: []
    property var resFlat: []
    property string archState: "idle"     // idle | loading | ok | error | missing
    property string aurState: "idle"
    property string flatState: "idle"
    readonly property bool searching: archState === "loading" || aurState === "loading" || flatState === "loading"
    readonly property int maxPerSource: 40
    readonly property int maxResults: 90

    function search(q) {
        query = q.trim()
        // mata o que estava rodando; o debounce começa as novas buscas
        _running = ""
        pacSearch.running = false; aurSearch.running = false; flatSearch.running = false
        if (query.length < 2) {
            debounce.stop()
            resArch = []; resAur = []; resFlat = []
            archState = aurState = flatState = "idle"
            return
        }
        archState = aurState = "loading"
        flatState = hasFlatpak ? "loading" : "missing"
        debounce.interval = 350
        debounce.restart()
    }

    Timer {
        id: debounce
        interval: 350
        onTriggered: {
            // espera as buscas antigas terminarem de morrer
            if (pacSearch.running || aurSearch.running || flatSearch.running) { interval = 80; restart(); return }
            interval = 350
            const q = root.query
            root._running = q
            pacSearch.command = ["pacman", "-Ss", "--", q]
            pacSearch.running = true
            aurSearch.command = ["curl", "-sf", "--max-time", "12", "https://aur.archlinux.org/rpc/v5/search/" + encodeURIComponent(q) + "?by=name-desc"]
            aurSearch.running = true
            if (root.hasFlatpak) {
                flatSearch.command = ["flatpak", "search", "--columns=name,description,application,version", q]
                flatSearch.running = true
            }
        }
    }

    // nome igual vem primeiro, depois começa com, depois contém; o resto pela descrição
    function score(p, q) {
        const n = p.name.toLowerCase(), id = p.id.toLowerCase()
        let s = 0
        if (n === q || id === q || id.endsWith("." + q)) s = 1000
        else if (n.startsWith(q) || id.startsWith(q)) s = 600 - n.length
        else if (n.includes(q) || id.includes(q)) s = 300 - n.length
        else s = 50
        if (p.source === "arch") s += 30
        else if (p.source === "flatpak") s += 15
        else s += Math.min(40, Math.log(1 + (p.votes || 0)) * 5)
        return s
    }
    function _rank(list) {
        const q = _running.toLowerCase()
        return list.map(p => Object.assign({ s: score(p, q) }, p)).sort((a, b) => b.s - a.s).slice(0, maxPerSource)
    }

    readonly property var results: {
        const all = resArch.concat(resAur, resFlat)
        all.sort((a, b) => b.s - a.s || a.name.localeCompare(b.name))
        return all.slice(0, maxResults)
    }

    Process {
        id: pacSearch
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                if (root._running === "" || !pacSearch.command || pacSearch.command[3] !== root._running) return
                const out = []
                let cur = null
                for (const l of text.split("\n")) {
                    if (l.startsWith(" ") || l.startsWith("\t")) {
                        if (cur) cur.desc = (cur.desc ? cur.desc + " " : "") + l.trim()
                        continue
                    }
                    const m = l.match(/^([^\/\s]+)\/(\S+)\s+(\S+)(.*)$/)
                    if (!m) continue
                    cur = { name: m[2], id: m[2], repo: m[1], version: m[3], desc: "", source: "arch", installedTag: m[4].indexOf("[installed") >= 0 }
                    out.push(cur)
                }
                root.resArch = root._rank(out)
                root.archState = "ok"
            }
        }
        // pacman -Ss sai com 1 quando não acha nada; isso não é erro
        onExited: code => { if (code > 1 && root.archState === "loading" && root._running !== "") root.archState = "error" }
    }
    Process {
        id: aurSearch
        stdout: StdioCollector {
            onStreamFinished: {
                if (root._running === "") return
                if (text.trim() === "") return       // erro: tratado no onExited
                try {
                    const j = JSON.parse(text)
                    if (j.type === "error") { root.resAur = []; root.aurState = j.error && j.error.indexOf("Too many") >= 0 ? "toomany" : "error"; return }
                    root.resAur = root._rank((j.results || []).map(r => ({
                        name: r.Name, id: r.Name, version: r.Version || "", desc: r.Description || "",
                        source: "aur", votes: r.NumVotes || 0, popularity: r.Popularity || 0, outOfDate: !!r.OutOfDate
                    })))
                    root.aurState = "ok"
                } catch (e) { root.resAur = []; root.aurState = "error" }
            }
        }
        onExited: code => { if (code !== 0 && root.aurState === "loading" && root._running !== "") { root.resAur = []; root.aurState = "error" } }
    }
    Process {
        id: flatSearch
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: {
                if (root._running === "") return
                const out = []
                for (const l of text.split("\n")) {
                    const c = l.split("\t")
                    if (c.length < 3 || !c[2] || c[2].indexOf(".") < 0) continue   // ignora "No matches found"
                    out.push({ name: c[0] || c[2], desc: c[1] || "", id: c[2], version: c[3] || "", source: "flatpak" })
                }
                root.resFlat = root._rank(out)
                root.flatState = "ok"
            }
        }
        onExited: code => { if (code !== 0 && root.flatState === "loading" && root._running !== "") root.flatState = "error" }
    }

    // ---------- destaques (curadoria) ----------
    readonly property var categories: [
        { id: "internet", name: "Internet", icon: "wifi" },
        { id: "midia", name: "Música e vídeo", icon: "music" },
        { id: "jogos", name: "Jogos", icon: "gamepad" },
        { id: "criacao", name: "Criação", icon: "palette" },
        { id: "escritorio", name: "Escritório", icon: "file" },
        { id: "dev", name: "Desenvolvimento", icon: "terminal" }
    ]

    // sources: a primeira é a recomendada; as outras aparecem como alternativa no painel
    readonly property var featured: [
        { cat: "internet", name: "Firefox", desc: "Navegador livre, rápido e que respeita sua privacidade", icons: ["firefox"],
          sources: [{ source: "arch", id: "firefox" }, { source: "flatpak", id: "org.mozilla.firefox" }] },
        { cat: "internet", name: "Chromium", desc: "Navegador de código aberto que deu origem ao Chrome", icons: ["chromium", "chromium-browser"],
          sources: [{ source: "arch", id: "chromium" }, { source: "flatpak", id: "org.chromium.Chromium" }] },
        { cat: "internet", name: "Discord", desc: "Voz, vídeo e chat para comunidades e amigos", icons: ["discord"],
          sources: [{ source: "flatpak", id: "com.discordapp.Discord" }, { source: "arch", id: "discord" }] },
        { cat: "internet", name: "Telegram", desc: "Mensagens rápidas e sincronizadas em todos os aparelhos", icons: ["telegram", "org.telegram.desktop", "telegram-desktop"], desktop: ["org.telegram.desktop"],
          sources: [{ source: "arch", id: "telegram-desktop" }, { source: "flatpak", id: "org.telegram.desktop" }] },
        { cat: "midia", name: "Spotify", desc: "Milhões de músicas e podcasts para ouvir à vontade", icons: ["spotify-client", "spotify", "com.spotify.Client"],
          sources: [{ source: "aur", id: "spotify" }, { source: "flatpak", id: "com.spotify.Client" }] },
        { cat: "midia", name: "VLC", desc: "Toca praticamente qualquer vídeo ou música", icons: ["vlc"],
          sources: [{ source: "arch", id: "vlc" }, { source: "flatpak", id: "org.videolan.VLC" }] },
        { cat: "midia", name: "mpv", desc: "Player de vídeo leve, minimalista e poderoso", icons: ["mpv"],
          sources: [{ source: "arch", id: "mpv" }, { source: "flatpak", id: "io.mpv.Mpv" }] },
        { cat: "midia", name: "OBS Studio", desc: "Grave a tela e faça transmissões ao vivo", icons: ["com.obsproject.Studio", "obs"], desktop: ["com.obsproject.studio"],
          sources: [{ source: "arch", id: "obs-studio" }, { source: "flatpak", id: "com.obsproject.Studio" }] },
        { cat: "jogos", name: "Steam", desc: "Sua biblioteca de jogos, com Proton para jogos do Windows", icons: ["steam"],
          sources: [{ source: "arch", id: "steam" }, { source: "flatpak", id: "com.valvesoftware.Steam" }] },
        { cat: "jogos", name: "Lutris", desc: "Reúne jogos de várias lojas e emuladores num lugar só", icons: ["lutris", "net.lutris.Lutris"], desktop: ["net.lutris.lutris"],
          sources: [{ source: "arch", id: "lutris" }, { source: "flatpak", id: "net.lutris.Lutris" }] },
        { cat: "criacao", name: "GIMP", desc: "Edição de fotos e imagens, com camadas e filtros", icons: ["gimp", "org.gimp.GIMP"], desktop: ["gimp", "org.gimp.gimp"],
          sources: [{ source: "arch", id: "gimp" }, { source: "flatpak", id: "org.gimp.GIMP" }] },
        { cat: "criacao", name: "Inkscape", desc: "Desenho vetorial para logos, ícones e ilustrações", icons: ["inkscape", "org.inkscape.Inkscape"], desktop: ["org.inkscape.inkscape"],
          sources: [{ source: "arch", id: "inkscape" }, { source: "flatpak", id: "org.inkscape.Inkscape" }] },
        { cat: "criacao", name: "Krita", desc: "Pintura digital feita por artistas, para artistas", icons: ["krita", "org.kde.krita"], desktop: ["org.kde.krita"],
          sources: [{ source: "arch", id: "krita" }, { source: "flatpak", id: "org.kde.krita" }] },
        { cat: "criacao", name: "Blender", desc: "Modelagem 3D, animação e efeitos visuais", icons: ["blender", "org.blender.Blender"],
          sources: [{ source: "arch", id: "blender" }, { source: "flatpak", id: "org.blender.Blender" }] },
        { cat: "criacao", name: "Kdenlive", desc: "Editor de vídeo completo e fácil de aprender", icons: ["kdenlive", "org.kde.kdenlive"], desktop: ["org.kde.kdenlive"],
          sources: [{ source: "arch", id: "kdenlive" }, { source: "flatpak", id: "org.kde.kdenlive" }] },
        { cat: "escritorio", name: "LibreOffice", desc: "Textos, planilhas e apresentações, compatível com Office", icons: ["libreoffice-startcenter", "libreoffice-main", "org.libreoffice.LibreOffice"], desktop: ["libreoffice-startcenter", "startcenter"],
          sources: [{ source: "arch", id: "libreoffice-fresh" }, { source: "flatpak", id: "org.libreoffice.LibreOffice" }] },
        { cat: "escritorio", name: "Obsidian", desc: "Notas em Markdown ligadas entre si, tudo no seu computador", icons: ["obsidian", "md.obsidian.Obsidian"],
          sources: [{ source: "flatpak", id: "md.obsidian.Obsidian" }, { source: "arch", id: "obsidian" }] },
        { cat: "dev", name: "Visual Studio Code", desc: "Editor de código da Microsoft, cheio de extensões", icons: ["visual-studio-code", "code", "com.visualstudio.code"], desktop: ["code", "visual-studio-code"],
          sources: [{ source: "aur", id: "visual-studio-code-bin" }, { source: "flatpak", id: "com.visualstudio.code" }] },
        { cat: "dev", name: "Zed", desc: "Editor de código moderno, rapidíssimo e colaborativo", icons: ["zed", "dev.zed.Zed"], desktop: ["dev.zed.zed", "zed"],
          sources: [{ source: "arch", id: "zed" }, { source: "flatpak", id: "dev.zed.Zed" }] }
    ]

    // transforma um destaque num pacote para o painel (com fonte escolhida e alternativas)
    function featuredPkg(entry, src) {
        const s = src || installedSource(entry) || entry.sources[0]
        return { name: entry.name, id: s.id, source: s.source, desc: entry.desc, icons: entry.icons, desktop: entry.desktop || [],
                 version: "", entry: entry, alternatives: entry.sources }
    }

    // ---------- textos ----------
    function sourceLabel(src) { return src === "aur" ? "AUR" : src === "flatpak" ? "Flatpak" : "Arch" }
}
