pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Assistente de IA do lançador. Fala com a API da Anthropic (Claude), com um Ollama local
// ou com qualquer serviço compatível com OpenAI. A chave fica em ~/.config/cypheros/ia-chave (só você lê).
Singleton {
    id: root
    property var history: []        // [{ role: "user"|"assistant", content }]
    property bool busy: false
    property string error: ""
    readonly property string answer: history.length && history[history.length - 1].role === "assistant" ? history[history.length - 1].content : ""
    readonly property string keyFile: Config.dir + "/ia-chave"

    readonly property string provider: Config.o.aiProvider || "anthropic"
    readonly property string model: Config.o.aiModel || ({ anthropic: "claude-haiku-5-5", ollama: "llama3.2", openai: "gpt-4o-mini" })[provider]
    readonly property string endpoint: Config.o.aiEndpoint || ({ anthropic: "https://api.anthropic.com/v1/messages", ollama: "http://localhost:11434/api/chat", openai: "https://api.openai.com/v1/chat/completions" })[provider]

    readonly property string system: "Você é o assistente do CypherOS, um sistema baseado no Arch Linux com desktop próprio (Hyprland + shell em QML). "
        + "Responda em português do Brasil, curto e direto. Quando sugerir comandos, coloque-os em um bloco ```sh. "
        + "Coisas do sistema: comando `cypher` (tema, cor, wallpaper, foco, perfil, atualizar, snapshots, restaurar, backup), "
        + "Central CypherOS (SUPER+I) para configurações, Loja Cypher para apps (pacman, AUR via paru, Flatpak), "
        + "SUPER+ESPAÇO lançador, SUPER+V área de transferência, SUPER+TAB visão geral, SUPER+PRINT captura, SUPER+N painel. "
        + "Ajustes manuais do Hyprland vão em ~/.config/hypr/usuario.conf."

    // primeiro bloco ```sh da resposta, para o botão "Rodar no terminal"
    readonly property string command: { const m = answer.match(/```(?:sh|bash|zsh)?\n([\s\S]*?)```/); return m ? m[1].trim() : "" }

    function reset() { history = []; error = ""; if (proc.running) proc.running = false; busy = false }

    function ask(text) {
        text = text.trim()
        if (!text || busy) return
        error = ""
        history = history.concat([{ role: "user", content: text }])
        const msgs = history.slice(-12)
        let body
        if (provider === "anthropic") body = { model: model, max_tokens: 1200, system: system, messages: msgs }
        else if (provider === "ollama") body = { model: model, stream: false, messages: [{ role: "system", content: system }].concat(msgs) }
        else body = { model: model, messages: [{ role: "system", content: system }].concat(msgs) }
        busy = true
        proc.command = ["sh", "-c",
            // a chave vai num arquivo temporário só seu (-K), nunca na linha de comando
            "h=\"${XDG_RUNTIME_DIR:-/tmp}/cypher-ia.$$\"; umask 077; : > \"$h\";"
            + "k=$(cat \"$4\" 2>/dev/null | tr -d '\\n');"
            + "case \"$1\" in anthropic) printf 'header = \"x-api-key: %s\"\\nheader = \"anthropic-version: 2023-06-01\"\\n' \"$k\" > \"$h\";;"
            + " openai) [ -n \"$k\" ] && printf 'header = \"Authorization: Bearer %s\"\\n' \"$k\" > \"$h\";; esac;"
            + "curl -sS --max-time 90 -K \"$h\" -H 'content-type: application/json' --data-binary \"$3\" \"$2\"; r=$?; rm -f \"$h\"; exit $r",
            "sh", provider, endpoint, JSON.stringify(body), keyFile]
        proc.running = true
    }

    function runCommand() {
        if (!command) return
        Quickshell.execDetached(["sh", "-c", "t=cypher-term; command -v $t >/dev/null || t=foot; $t -e zsh -ic \"$1; echo; exec zsh\"", "sh", command])
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.busy) return
                root.busy = false
                let txt = ""
                try {
                    const j = JSON.parse(text)
                    if (j.error) root.error = typeof j.error === "string" ? j.error : (j.error.message ?? "Erro do serviço")
                    else if (root.provider === "anthropic") txt = (j.content ?? []).filter(c => c.type === "text").map(c => c.text).join("\n")
                    else if (root.provider === "ollama") txt = j.message?.content ?? ""
                    else txt = j.choices?.[0]?.message?.content ?? ""
                } catch (e) {
                    root.error = text.trim() ? "Resposta inesperada do serviço." : ""
                }
                if (txt) root.history = root.history.concat([{ role: "assistant", content: txt }])
                else if (!root.error) root.error = root.provider === "ollama" ? "O Ollama não respondeu. Ele está rodando? (ollama serve)" : "Sem resposta. Confira a internet e a chave na Central › Assistente."
            }
        }
        onExited: code => {
            if (code !== 0 && root.busy) { root.busy = false; root.error = root.provider === "ollama" ? "Não consegui falar com o Ollama em " + root.endpoint : "Não consegui falar com o serviço de IA (erro " + code + ")." }
        }
    }
}
