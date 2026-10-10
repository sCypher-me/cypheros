# CypherOS 0.8 "Gênese"

Sistema próprio baseado no Arch Linux, com o visual **Prisma**: vidro escuro, luz ciano e violeta, efeitos suaves.
Do Arch ficam só o kernel, o pacman e o systemd. Tudo que você vê foi feito do zero para o CypherOS.

## O que tem dentro

| Peça | Onde está |
|---|---|
| Shell do desktop (barra, lançador, notificações, painel de controle, dock, widgets, tela de bloqueio, indicador de volume/brilho, menu de energia) | `shell/` |
| 5 wallpapers animados que rodam na placa de vídeo e dançam com a música: Aurora, Nebulosa, Partículas, Ondas, Pulso | `shell/shaders/` |
| 95 ícones próprios desenhados em código | `shell/services/Icons.qml` |
| Hyprland com bordas em degradê, desfoque de vidro e animações com as curvas do Prisma | `config/hypr/` |
| Cypher Term: terminal com abas, divisões e vidro, nas cores do tema | `term/`, `bin/cypher-term` |
| Apps próprios: Central CypherOS, Loja Cypher e Monitor do sistema | `apps/` |
| Zsh com prompt do CypherOS (o foot fica de reserva) | `config/zsh/`, `config/foot/` |
| Comando `cypher` para trocar tema, cores, wallpaper e mais | `bin/cypher` |
| Tela de login própria (greetd) com troca de usuário e botões de energia | `shell/greeter.qml` |
| Boot animado com o logo do CypherOS (plymouth) | `plymouth/` |
| Assistente de boas-vindas no primeiro login: tema, wallpaper ao vivo, Wi-Fi e atalhos | `shell/modules/welcome/` |
| Visão geral das janelas, captura e gravação de tela, seletor de cor, régua | `shell/modules/overview/`, `shell/modules/capture/` |
| Calendário e agenda, modo foco, perfis, clima, notas, área de transferência e emojis | `shell/modules/`, `shell/services/` |
| 9 sons do sistema próprios | `share/sons/` |
| Ícones Prisma (55, completados pelo Papirus) e cursor Prisma | `icones/`, `cursor/` |
| Loja de temas da comunidade (8 temas extras) e o repositório da loja pronto para publicar | `share/temas/`, `comunidade-temas/` |
| Repositório de pacotes próprio [cypheros] e a publicação automática no GitHub | `repo/`, `.github/workflows/` |
| Site do CypherOS | `site/` |
| Gerador da ISO e instalador | `iso/` |

## Jeito 1: testar no seu Arch agora (sem formatar)

```sh
cd cypheros
./testar-no-meu-arch.sh
```

Ele instala os pacotes, coloca o CypherOS no sistema e guarda as suas configs antigas do Hyprland, foot e fastfetch numa pasta de backup (`~/.config/cypheros-backup-...`). Depois é só sair do Hyprland e entrar de novo.

No final ele pergunta se você quer ligar a tela de login e o boot animado do CypherOS. Dá para ligar depois também: `sudo ./ativar-login-e-boot.sh` (ou só `login`, ou só `boot`).

Para voltar ao que era: apague `~/.config/hypr` e mova a pasta `hypr` do backup de volta.

## Jeito 2: gerar a ISO do CypherOS

```sh
cd cypheros
sudo ./iso/build-iso.sh
```

A ISO sai em `saida/cypheros-AAAA.MM.DD-x86_64.iso` (leva de 10 a 30 minutos e precisa de uns 10 GB livres).
Grave no pendrive:

```sh
sudo dd if=saida/cypheros-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Troque `/dev/sdX` pelo seu pendrive (confira com `lsblk`, isso apaga o pendrive).

### Sem Arch? Gere a ISO pelo GitHub (funciona no Windows)

1. Crie um repositório vazio chamado `cypheros` no seu GitHub e envie esta pasta para ele.
2. A aba **Actions** gera a ISO sozinha (leva uns 30 a 40 minutos). Ela aparece em **Releases** e também nos **Artifacts** da execução.
3. Grave no pendrive com o **balenaEtcher** ou o **Rufus** (no Rufus, escolha "modo imagem DD" quando ele perguntar).
4. No computador, desligue o **Secure Boot** na BIOS antes de dar boot pelo pendrive.

Ao dar boot pelo pendrive, o CypherOS abre direto na sessão ao vivo (usuário `cypher`, senha `cypher`) e o **instalador gráfico** aparece sozinho. É tudo pelo mouse: idioma, internet, fuso e teclado, disco, sua conta e o visual. Fechou o instalador para experimentar o sistema? Ele fica fixado no começo do dock. Quem preferir o modo texto ainda tem `sudo cypher-instalar` no terminal.

Em máquina virtual, ligue a aceleração 3D (o Hyprland precisa de placa de vídeo).

## Novidades da 0.8

- **Instalador gráfico:** abre sozinho no pendrive e não pede comando nenhum. São 7 passos com o visual Prisma:
  - idioma do sistema
  - Wi-Fi
  - fuso detectado pela internet, com a hora para conferir
  - teclado, com um campo para testar
  - disco
  - sua conta, com o usuário sugerido a partir do nome e um medidor de força da senha
  - tema e wallpaper, com prévia ao vivo

  Antes de começar aparece um resumo; o botão "Alterar" volta direto ao passo certo. A instalação mostra a porcentagem real, cada etapa e cartões apresentando o sistema. Se algo falhar, dá para ver os detalhes, copiar o relatório e tentar de novo.
- **Instalar ao lado do Windows:** se o disco tiver pelo menos 20 GB livres, o CypherOS usa só esse espaço e não toca no que já existe. Ao ligar, aparece um menu para escolher o sistema. O instalador mostra como o disco fica antes e depois e explica como liberar espaço no Windows.
- **Criptografia do disco:** uma chave no passo do disco. A mesma senha da conta destrava o disco ao ligar, com a tela do boot animado.
- **Computadores antigos (BIOS):** agora também dá para instalar, apagando o disco inteiro, com GRUB.
- Correções no shell achadas ao renderizar as telas de verdade: a cor `onAccent` era lida como sinal pelo QML e quebrava o tema; o Pomodoro tinha o mesmo problema (`onBreak`); as prévias de wallpaper da Central e das boas-vindas não animavam; e as barras laterais da Central, da Loja e do Monitor esticavam demais.

## Novidades da 0.7

- **Ícones e cursor Prisma:** pastas em degradê ciano e violeta, apps do sistema com o mesmo vidro escuro e um cursor próprio. Os ícones de marcas (Firefox, Steam...) continuam vindo do Papirus.
- **Loja de temas:** Central › Loja de temas. Instale temas da comunidade com um clique, exporte o seu visual como arquivo e compartilhe. Já vêm 8 temas extras (Neon Tóquio, Floresta, Lavanda, Ártico, Rubi, Drácula, Ouro, Matrix). Para a loja online funcionar, publique a pasta `comunidade-temas` como o repositório `cypheros-temas` no seu GitHub (o LEIA-ME de lá explica). Pelo terminal: `cypher temas` e `cypher tema instalar arquivo.json`.
- **Repositório de pacotes [cypheros]:** o CypherOS virou pacote do pacman (`cypheros`, `cypheros-cursor`, `cypheros-icones`). `./repo/construir.sh` monta o repositório no seu Arch; subindo o projeto para o GitHub, o workflow em `.github/workflows` constrói e publica tudo no GitHub Pages sozinho. Depois, em qualquer Arch: `sudo ./repo/ativar-repositorio.sh` e `sudo pacman -S cypheros`, e o CypherOS passa a se atualizar junto com o sistema.
- **Site:** `site/index.html`, com recursos, wallpapers, atalhos, instalação e temas. O mesmo workflow publica o site no GitHub Pages.
- `cypher-aplicar-padrao` aplica as configurações do CypherOS a um usuário que já existia (com backup).

## Novidades da 0.6

- **Pontos de restauração:** o instalador agora usa btrfs com snapper. Antes e depois de cada atualização o sistema guarda um ponto; se algo quebrar, `cypher restaurar` (ou Central › Atualizações e segurança) volta no tempo. Seus arquivos pessoais não são tocados. Num Arch já instalado em ext4 isso não está disponível (o resto funciona).
- **Atualizador na barra:** o sistema confere Arch, AUR e Flatpak a cada 2 horas. Quando tem novidade, aparece um ícone com o número na barra; clique, veja a lista e "Atualizar agora". `cypher atualizar` faz o mesmo pelo terminal.
- **Backup das configurações:** `cypher backup` guarda tema, wallpaper, atalhos, terminal e a lista dos seus apps em `~/CypherOS-backups`. Dá para ligar o backup semanal na Central. `cypher restaurar-backup` traz tudo de volta e reinstala os apps, ótimo para um computador novo.
- **Celular (KDE Connect):** instale o app KDE Connect no celular e pareie pela Central › Celular. Você vê a bateria no painel, recebe as notificações do celular, toca o celular para achar e manda arquivos e o que copiou.
- **Assistente de IA no lançador:** SUPER+A, ou comece a busca com `?`. Ele conhece os atalhos e comandos do CypherOS, e quando sugere um comando aparece o botão "Rodar no terminal". Funciona com Claude (precisa de chave de API), com Ollama no seu computador (grátis, sem internet) ou com qualquer serviço compatível com OpenAI. Configure em Central › Assistente de IA.

## Novidades da 0.5

- **Central CypherOS** (SUPER+I): todas as configurações num app só, com busca. Aparência (tema, cores, vidro, letras, tema por horário), wallpaper com prévia ao vivo, barra, dock e widgets, notificações, sons, foco e perfis, Wi-Fi e Bluetooth, som (saída, microfone e volume por app), tela (resolução e escala), teclado, mouse e touchpad, e "Sobre".
- **Loja Cypher:** destaques por categoria, busca no Arch, no AUR e no Flatpak ao mesmo tempo, apps instalados e atualizações. Instalar e remover abre o terminal para você ver tudo e digitar a senha. Se faltar o ajudante do AUR, ela instala o paru para você.
- **Monitor do sistema** (CTRL+SHIFT+ESC): gráficos ao vivo de CPU (por núcleo), memória, rede, disco, temperatura e GPU, lista de processos com busca e botão de encerrar, e os serviços que iniciam com você.
- **Cypher Term** (SUPER+ENTER): abas, divisões de tela (CTRL+SHIFT+ENTER e CTRL+SHIFT+\\), fundo de vidro e busca no histórico (CTRL+SHIFT+F). As cores seguem o tema na hora.
- **Visual Prisma nos apps:** Nautilus e outros apps GTK ganham as cores do tema, e as bordas das janelas acompanham a cor de destaque.

## Novidades da 0.4

- **Visão geral:** SUPER+TAB (ou o botão ao lado das áreas na barra) mostra todas as áreas de trabalho com miniaturas ao vivo. Clique para ir, arraste uma janela para outra área, botão do meio fecha.
- **Captura de tela:** SUPER+PRINT abre a barra de captura: print da tela, de uma área ou da janela, editar o print (setas, texto, desfoque) e gravar a tela com ou sem som.
- **Gravação:** SUPER+SHIFT+R começa e para. Enquanto grava, uma pílula vermelha com o tempo aparece na barra; clique nela para parar. Os vídeos vão para `~/Vídeos/Gravações`.
- **Seletor de cor:** SUPER+SHIFT+C, clique em qualquer ponto e o código da cor vai para a área de transferência.
- **Régua:** SUPER+SHIFT+M mostra as coordenadas; arraste para medir em pixels, Enter copia.
- **Wallpaper que dança com a música:** quando algo toca, todos os wallpapers pulsam com o grave e um espectro de luz sobe do rodapé. O novo wallpaper **Pulso** é um anel que vira equalizador. Desligue com `cypher musica`.
- **Tema por horário:** um tema de dia e outro de noite, com luz noturna automática. `cypher tema auto prisma grafite` (horários em `config.json › dayStart / nightStart`).

## Novidades da 0.3

- **Busca universal:** o lançador agora procura apps, arquivos da sua pasta pessoal e comandos que você já usou no terminal, tudo junto.
- **Área de transferência:** SUPER+V mostra tudo que você copiou (textos e imagens). Enter cola de volta, Delete apaga.
- **Emojis:** SUPER+PONTO abre o seletor com nomes em português. Enter copia e digita o emoji.
- **Calendário e agenda:** clique no relógio da barra (ou SUPER+C). Escreva `14:30 Dentista` para marcar. Os próximos compromissos aparecem na área de trabalho.
- **Clima:** na barra e num widget com a previsão de 4 dias. A cidade é descoberta pela internet, ou escolha com `cypher cidade Recife`.
- **Notas rápidas:** widget na área de trabalho, salvo sozinho em `~/.config/cypheros/notas.md`.
- **Modo foco (Pomodoro):** SUPER+SHIFT+F esconde barra e dock, silencia notificações e conta 25 min de foco e 5 de pausa. Uma pílula no topo mostra o tempo; clique nela para sair.
- **Perfis de uso:** Padrão, Trabalho, Estudo e Jogo, no painel de controle ou SUPER+SHIFT+P. Cada um troca tema, wallpaper, notificações e abre apps. Edite em `config.json › profiles`.
- **Modo jogo:** SUPER+G desliga desfoque, sombras, animações e pausa o wallpaper.
- **Sons do sistema:** notificação, desbloqueio, senha errada, print e modo foco. `cypher sons desligar` silencia.

## Novidades da 0.2

- **Tela de login:** mesmo visual da tela de bloqueio, com relógio em degradê, anel colorido no avatar e troca de usuário pelas setas.
- **Boot animado:** fundo azul-noite, logo surgindo com brilho pulsando e barra de progresso em degradê. Também pede a senha do disco, se ele for criptografado.
- **Boas-vindas:** aparece no primeiro login. Para ver de novo: lançador › "Boas-vindas".
- O instalador da ISO já liga tudo isso sozinho.

## Atalhos

| Tecla | Faz |
|---|---|
| SUPER + ESPAÇO | Lançador (digite `=` para calcular, `>` para rodar um comando) |
| SUPER + N | Painel de controle e notificações |
| SUPER + ENTER | Cypher Term |
| SUPER + I | Central CypherOS |
| CTRL + SHIFT + ESC | Monitor do sistema |
| SUPER + L | Bloquear a tela |
| SUPER + ESC | Menu de energia |
| SUPER + Q | Fechar janela |
| SUPER + F | Tela cheia |
| SUPER + 1 a 9 | Trocar de área de trabalho |
| SUPER + SHIFT + S | Print de uma área |
| PRINT | Print da tela inteira |
| SUPER + PRINT | Barra de captura (prints, edição, gravação) |
| SUPER + SHIFT + E | Print de uma área e editar |
| SUPER + SHIFT + R | Gravar a tela (de novo para parar) |
| SUPER + SHIFT + C | Seletor de cor |
| SUPER + SHIFT + M | Régua |
| SUPER + TAB | Visão geral |
| SUPER + SHIFT + D | Não perturbe |
| SUPER + V | Histórico da área de transferência |
| SUPER + PONTO | Emojis |
| SUPER + A | Assistente de IA |
| SUPER + C | Calendário e agenda |
| SUPER + SHIFT + F | Modo foco |
| SUPER + SHIFT + P | Próximo perfil |
| SUPER + G | Modo jogo |
| SUPER + SHIFT + V | Janela flutuante |

## Personalizar

Tudo fica em um arquivo só: `~/.config/cypheros/config.json`. Salvou, mudou na hora.
Ou pelo terminal:

```sh
cypher tema oceano            # prisma, oceano, por-do-sol, grafite
cypher cor "#5EEAD4" "#F472B6"
cypher wallpaper nebulosa     # aurora, nebulosa, particulas, ondas, pulso
cypher wallpaper video ~/Vídeos/fundo.mp4
cypher barra baixo
cypher perfil estudo
cypher foco 50             # foco de 50 minutos
```

Suas mudanças no Hyprland (monitores, teclado etc.) vão em `~/.config/hypr/usuario.conf`, que nunca é sobrescrito.

## Se algo der errado

Rode o shell no terminal para ver o erro: `qs -c cypheros`. Me manda o que aparecer.
