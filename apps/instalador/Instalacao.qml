pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.services

// Estado do instalador: tudo o que a pessoa escolheu nas telas e o andamento da instalação.
// Quem faz o trabalho pesado é o cypher-instalar (modo --config), rodando como administrador.
Singleton {
    id: root

    // ---------------------------------------------------------------- checagem do computador
    property var checagem: ({ uefi: true, internet: false, ramMiB: 0, fuso: "America/Sao_Paulo", versao: "0.8", naBateria: false })
    property bool checado: false
    function checar() { checador.running = true }

    // ---------------------------------------------------------------- escolhas
    property string idioma: "pt_BR.UTF-8"
    readonly property var idiomas: [
        { id: "pt_BR.UTF-8", name: "Português (Brasil)" },
        { id: "en_US.UTF-8", name: "English (US)" },
        { id: "es_ES.UTF-8", name: "Español" },
        { id: "pt_PT.UTF-8", name: "Português (Portugal)" }
    ]

    property string fuso: "America/Sao_Paulo"
    property var fusos: []
    property string horaNoFuso: ""

    readonly property var teclados: [
        { id: "br",    name: "Português (Brasil, ABNT2)",        xkb: "br",    variante: "",     console: "br-abnt2" },
        { id: "us",    name: "Inglês (EUA)",                     xkb: "us",    variante: "",     console: "us" },
        { id: "us-intl", name: "Inglês (EUA, internacional)",    xkb: "us",    variante: "intl", console: "us-acentos" },
        { id: "pt",    name: "Português (Portugal)",             xkb: "pt",    variante: "",     console: "pt-latin1" },
        { id: "latam", name: "Espanhol (América Latina)",        xkb: "latam", variante: "",     console: "la-latin1" },
        { id: "es",    name: "Espanhol (Espanha)",               xkb: "es",    variante: "",     console: "es" },
        { id: "gb",    name: "Inglês (Reino Unido)",             xkb: "gb",    variante: "",     console: "uk" },
        { id: "fr",    name: "Francês",                          xkb: "fr",    variante: "",     console: "fr" },
        { id: "de",    name: "Alemão",                           xkb: "de",    variante: "",     console: "de" },
        { id: "it",    name: "Italiano",                         xkb: "it",    variante: "",     console: "it" }
    ]
    property var teclado: teclados[0]
    function escolherTeclado(t) {
        teclado = t
        // aplica na hora, para a pessoa testar no campo da tela
        Quickshell.execDetached(["hyprctl", "--batch", "keyword input:kb_layout " + t.xkb + " ; keyword input:kb_variant " + t.variante])
    }

    property var discos: []
    property bool lendoDiscos: false
    property string disco: ""
    property string modo: "apagar"          // apagar | livre
    property bool criptografar: false
    readonly property real minBytes: 20 * 1024 * 1024 * 1024
    readonly property var discoSel: discos.find(d => d.caminho === disco) ?? null
    function lerDiscos() { if (!leitorDiscos.running) { lendoDiscos = true; leitorDiscos.running = true } }
    // dá para instalar ao lado? devolve "" se sim, ou o motivo de não dar
    function motivoSemLado(d) {
        if (!d) return "Escolha um disco."
        if (!checagem.uefi) return "Este computador está no modo BIOS antigo; instalar ao lado de outro sistema precisa de UEFI."
        if (d.tabela !== "gpt") return d.particoes.length === 0 ? "O disco está vazio: use a opção de apagar." : "O disco usa a tabela antiga (MBR)."
        if (d.livre < minBytes) return "Há só " + gb(d.livre) + " livres; são precisos 20 GB."
        return ""
    }

    property string nome: ""
    property string usuario: ""
    property bool usuarioEditado: false
    property string maquina: ""
    property bool maquinaEditada: false
    property string senha: ""
    property string senha2: ""
    onNomeChanged: {
        if (!usuarioEditado) usuario = sugerirUsuario(nome)
        if (!maquinaEditada) maquina = (usuario || "cypher") + "-pc"
    }
    onUsuarioChanged: if (!maquinaEditada) maquina = (usuario || "cypher") + "-pc"
    readonly property bool usuarioValido: /^[a-z_][a-z0-9_-]{0,31}$/.test(usuario)
    readonly property bool maquinaValida: /^[A-Za-z0-9][A-Za-z0-9-]{0,62}$/.test(maquina)
    readonly property int forcaSenha: {
        const s = senha
        if (!s) return 0
        let n = s.length >= 12 ? 2 : s.length >= 8 ? 1 : 0
        if (/[A-Z]/.test(s) && /[a-z]/.test(s)) n++
        if (/[0-9]/.test(s)) n++
        if (/[^A-Za-z0-9]/.test(s)) n++
        return Math.max(1, Math.min(4, n))
    }

    property string tema: Config.o.theme
    property string wallpaper: Config.o.wallpaperShader || "aurora"

    property bool confirmouApagar: false

    function sugerirUsuario(n) {
        const de = "áàâãäéèêëíìîïóòôõöúùûüçñ", para = "aaaaaeeeeiiiiooooouuuucn"
        let s = (n.trim().split(/\s+/)[0] || "").toLowerCase()
        let out = ""
        for (const ch of s) {
            const i = de.indexOf(ch)
            const c = i >= 0 ? para[i] : ch
            if (/[a-z0-9_-]/.test(c)) out += c
        }
        if (/^[0-9-]/.test(out)) out = "u" + out
        return out.slice(0, 32)
    }
    function gb(bytes) {
        const g = bytes / 1024 / 1024 / 1024
        return g >= 1000 ? (g / 1024).toFixed(1).replace(".", ",") + " TB" : g >= 10 ? Math.round(g) + " GB" : g.toFixed(1).replace(".", ",") + " GB"
    }

    // ---------------------------------------------------------------- instalação
    property string estado: "configurando"     // configurando | instalando | pronto | erro
    property int pct: 0
    property string etapaAtual: ""
    property string etapaTexto: ""
    property var etapasFeitas: []
    property string erroTexto: ""
    property var log: []

    readonly property var etapas: [
        { id: "preparar", name: "Preparar o computador" },
        { id: "particionar", name: "Organizar o disco" },
        { id: "criptografar", name: "Criptografar", so: "cripto" },
        { id: "formatar", name: "Criar o sistema de arquivos" },
        { id: "baixar", name: "Baixar e instalar o sistema" },
        { id: "visual", name: "Aplicar o visual do CypherOS" },
        { id: "configurar", name: "Configurar idioma, horário e conta" },
        { id: "snapshots", name: "Ligar os pontos de restauração" },
        { id: "boot", name: "Instalar a inicialização" },
        { id: "login", name: "Tela de login e boot animado" }
    ].filter(e => e.so !== "cripto" || criptografar)

    function instalar() {
        estado = "instalando"
        pct = 0; etapaAtual = ""; etapaTexto = "Começando..."; etapasFeitas = []; erroTexto = ""; log = []
        const conf = {
            disco, modo, criptografar: criptografar && checagem.uefi,
            nome: nome.trim(), usuario, senha, maquina,
            fuso, idioma,
            teclado: { xkb: teclado.xkb, variante: teclado.variante, console: teclado.console },
            tema, wallpaper
        }
        arquivo.setText(JSON.stringify(conf))
        instalador.running = true
    }
    function reiniciar() { Quickshell.execDetached(["systemctl", "reboot"]) }
    function copiarRelatorio() { Quickshell.execDetached(["sh", "-c", "wl-copy < /tmp/cypher-instalar.log"]) }

    function _linha(l) {
        if (l.startsWith("@progresso ")) { pct = Math.max(pct, parseInt(l.slice(11)) || 0); return }
        if (l.startsWith("@etapa ")) {
            const resto = l.slice(7), sp = resto.indexOf(" ")
            const id = sp > 0 ? resto.slice(0, sp) : resto
            if (etapaAtual && etapaAtual !== id) etapasFeitas = etapasFeitas.concat([etapaAtual])
            etapaAtual = id
            etapaTexto = sp > 0 ? resto.slice(sp + 1) : resto
            return
        }
        if (l === "@fim") { etapasFeitas = etapas.map(e => e.id); pct = 100; estado = "pronto"; return }
        if (l.startsWith("@erro ")) { if (!erroTexto) erroTexto = l.slice(6); estado = "erro"; return }
        const novo = log.length > 400 ? log.slice(-300) : log.slice()
        novo.push(l)
        log = novo
    }

    // ---------------------------------------------------------------- processos
    readonly property string arquivoConf: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/cypher-instalar.json"

    FileView {
        id: arquivo
        path: root.arquivoConf
        blockWrites: true     // o arquivo precisa existir antes do motor começar
        printErrors: false
    }

    Process {
        id: checador
        command: ["cypher-instalar", "--checar"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.checagem = JSON.parse(text)
                    root.fuso = root.checagem.fuso || root.fuso
                } catch (e) {}
                root.checado = true
            }
        }
    }

    Process {
        id: leitorDiscos
        command: ["sudo", "-n", "cypher-instalar", "--discos"]
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.discos = JSON.parse(text) } catch (e) { root.discos = [] }
                root.lendoDiscos = false
                // escolhe sozinho quando só existe um disco que serve
                const bons = root.discos.filter(d => d.tamanho >= root.minBytes)
                if (!root.discoSel && bons.length === 1) root.disco = bons[0].caminho
            }
        }
    }

    Process {
        id: listaFusos
        running: true
        command: ["timedatectl", "list-timezones"]
        stdout: StdioCollector { onStreamFinished: root.fusos = text.trim().split("\n").filter(z => z.includes("/")) }
    }

    // hora atual no fuso escolhido, para a pessoa conferir
    Process {
        id: relogio
        command: ["env", "TZ=" + root.fuso, "date", "+%H:%M"]
        stdout: StdioCollector { onStreamFinished: root.horaNoFuso = text.trim() }
    }
    onFusoChanged: relogio.running = true
    Timer { interval: 20000; running: true; repeat: true; triggeredOnStart: true; onTriggered: relogio.running = true }

    Process {
        id: instalador
        command: ["sudo", "-n", "cypher-instalar", "--config", root.arquivoConf]
        stdout: SplitParser { onRead: l => root._linha(l) }
        stderr: SplitParser { onRead: l => root._linha(l) }
        onExited: code => {
            // garante que o arquivo com a senha não fica para trás
            Quickshell.execDetached(["rm", "-f", root.arquivoConf])
            if (root.estado === "instalando") {
                if (code === 0) root.estado = "pronto"
                else { root.erroTexto = root.erroTexto || "A instalação parou de repente (código " + code + ")."; root.estado = "erro" }
            }
        }
    }

    Component.onCompleted: { checar(); lerDiscos() }
}
