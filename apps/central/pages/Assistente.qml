import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.components
import "../ui"

Page {
    id: page
    title: "Assistente de IA"
    subtitle: "Pergunte qualquer coisa no lançador: SUPER+A, ou comece a busca com ?"

    property bool hasKey: false
    Process { id: keyCheck; command: ["test", "-s", Ai.keyFile]; running: true; onExited: code => page.hasKey = code === 0 }

    Section {
        title: "Quem responde"
        SettingRow {
            label: "Serviço"
            desc: Config.o.aiProvider === "ollama" ? "Roda no seu computador, de graça e sem internet. Instale com: sudo pacman -S ollama" : Config.o.aiProvider === "openai" ? "Qualquer serviço compatível com a API da OpenAI" : "Claude, da Anthropic. Precisa de uma chave de API (console.anthropic.com)"
            Chips {
                options: [{ id: "anthropic", name: "Claude" }, { id: "ollama", name: "Ollama (local)" }, { id: "openai", name: "Compatível OpenAI" }]
                current: Config.o.aiProvider
                onChosen: id => { Config.o.aiProvider = id; Config.o.aiModel = ""; Config.o.aiEndpoint = "" }
            }
        }
        SettingRow {
            label: "Modelo"
            desc: "Vazio usa o padrão: " + Ai.model
            Field { placeholder: Ai.model; text: Config.o.aiModel; mono: true; onAccepted: t => Config.o.aiModel = t.trim() }
        }
        SettingRow {
            label: "Endereço"
            desc: Ai.endpoint
            visible: Config.o.aiProvider !== "anthropic"
            Field { placeholder: "padrão"; text: Config.o.aiEndpoint; mono: true; onAccepted: t => Config.o.aiEndpoint = t.trim() }
        }
        SettingRow {
            visible: Config.o.aiProvider !== "ollama"
            label: "Chave de API"
            desc: page.hasKey ? "Guardada em ~/.config/cypheros/ia-chave (só você lê)" : "Nenhuma chave guardada"
            separator: false
            Field {
                id: keyField
                placeholder: page.hasKey ? "••••••••  (cole outra para trocar)" : "cole sua chave aqui"
                echoMode: TextInput.Password
                onAccepted: t => {
                    if (!t.trim()) return
                    Quickshell.execDetached(["sh", "-c", "umask 077; printf '%s' \"$1\" > \"$2\"", "sh", t.trim(), Ai.keyFile])
                    text = ""
                    keyCheck.running = true
                }
            }
        }
    }

    Section {
        title: "Testar"
        SettingRow {
            label: Ai.busy ? "Perguntando..." : Ai.error !== "" ? Ai.error : Ai.answer !== "" ? Ai.answer.slice(0, 160) : "Manda um \"oi\" para ver se está tudo certo"
            separator: false
            Chips { options: [{ id: 1, name: "Testar" }]; onChosen: { Ai.reset(); Ai.ask("Diga oi em uma frase curta.") } }
        }
    }
}
