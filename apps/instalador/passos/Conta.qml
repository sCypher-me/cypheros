import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.services
import qs.components
import "../ui"
import qs

Pagina {
    id: page
    titulo: "Crie a sua conta"
    subtitulo: Instalacao.criptografar ? "A mesma senha entra no sistema e destrava o disco criptografado ao ligar." : "É com ela que você entra no CypherOS e autoriza mudanças no sistema."
    readonly property bool senhasOk: Instalacao.senha.length >= 4 && Instalacao.senha === Instalacao.senha2
    pronto: Instalacao.nome.trim() !== "" && Instalacao.usuarioValido && Instalacao.maquinaValida && senhasOk
    falta: Instalacao.nome.trim() === "" ? "Digite o seu nome"
         : !Instalacao.usuarioValido ? "Nome de usuário inválido"
         : !Instalacao.maquinaValida ? "Nome do computador inválido"
         : Instalacao.senha.length < 4 ? "A senha precisa de 4 caracteres ou mais"
         : "As senhas não são iguais"

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 40 * Theme.s

        // prévia: avatar com o anel em degradê da tela de login
        ColumnLayout {
            Layout.alignment: Qt.AlignTop
            Layout.topMargin: 20 * Theme.s
            Layout.preferredWidth: 220 * Theme.s
            Layout.fillWidth: false
            spacing: 14 * Theme.s
            Item {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 140 * Theme.s; implicitHeight: 140 * Theme.s
                RectangularShadow { anchors.centerIn: parent; width: 100; height: 100; radius: 50; blur: 50; color: Theme.glowColor(Theme.accent2, 0.45) }
                Rectangle {
                    anchors.fill: parent; radius: width / 2
                    gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Theme.accent } GradientStop { position: 1; color: Theme.accent2 } }
                    RotationAnimation on rotation { from: 0; to: 360; duration: 9000; loops: Animation.Infinite }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width - 8 * Theme.s; height: width; radius: width / 2
                    color: Theme.bg
                    Label { anchors.centerIn: parent; text: (Instalacao.nome.trim()[0] || "?").toUpperCase(); kind: "display"; font.pixelSize: 56 * Theme.s; color: Theme.text }
                }
            }
            Label { Layout.alignment: Qt.AlignHCenter; text: Instalacao.nome.trim() || "Seu nome"; kind: "display"; font.pixelSize: 20 * Theme.s; color: Instalacao.nome.trim() ? Theme.text : Theme.muted }
            Label { Layout.alignment: Qt.AlignHCenter; kind: "muted"; text: "É assim que você aparece na tela de login" ; font.pixelSize: 12 * Theme.s }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 16 * Theme.s

            Campo {
                Layout.fillWidth: true
                rotulo: "Seu nome"
                placeholder: "Ex.: Julio Cesar"
                text: Instalacao.nome
                onEditado: t => Instalacao.nome = t
                Component.onCompleted: campo.forceActiveFocus()
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 14 * Theme.s
                Campo {
                    Layout.fillWidth: true
                    rotulo: "Nome de usuário"
                    mono: true
                    text: Instalacao.usuario
                    dica: "Criado a partir do seu nome"
                    erro: Instalacao.usuario !== "" && !Instalacao.usuarioValido ? "Use letras minúsculas, números, - ou _" : ""
                    onEditado: t => { Instalacao.usuarioEditado = true; Instalacao.usuario = t }
                }
                Campo {
                    Layout.fillWidth: true
                    rotulo: "Nome do computador"
                    mono: true
                    text: Instalacao.maquina
                    dica: "Como ele aparece na rede"
                    erro: Instalacao.maquina !== "" && !Instalacao.maquinaValida ? "Use letras, números e hífen" : ""
                    onEditado: t => { Instalacao.maquinaEditada = true; Instalacao.maquina = t }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 14 * Theme.s
                Campo {
                    Layout.fillWidth: true
                    rotulo: "Senha"
                    senha: true
                    text: Instalacao.senha
                    onEditado: t => Instalacao.senha = t
                }
                Campo {
                    Layout.fillWidth: true
                    rotulo: "Repita a senha"
                    senha: true
                    text: Instalacao.senha2
                    erro: Instalacao.senha2 !== "" && Instalacao.senha2 !== Instalacao.senha ? "As senhas não são iguais" : ""
                    onEditado: t => Instalacao.senha2 = t
                }
            }
            // medidor de força da senha
            RowLayout {
                visible: Instalacao.senha !== ""
                Layout.fillWidth: true
                spacing: 6 * Theme.s
                Repeater {
                    model: 4
                    delegate: Rectangle {
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 5 * Theme.s
                        radius: height / 2
                        readonly property color cor: Instalacao.forcaSenha <= 1 ? Theme.hot : Instalacao.forcaSenha === 2 ? "#FACC15" : Theme.ok
                        color: index < Instalacao.forcaSenha ? cor : Qt.rgba(1, 1, 1, 0.1)
                        Behavior on color { ColorAnimation { duration: Theme.durFast } }
                    }
                }
                Label {
                    Layout.leftMargin: 8 * Theme.s
                    kind: "muted"
                    text: ["", "Senha fraca", "Senha razoável", "Senha boa", "Senha forte"][Instalacao.forcaSenha]
                }
            }
        }
    }
}
