#!/usr/bin/env bash
# Copia os arquivos do CypherOS para dentro de um sistema.
# Uso: instalar-arquivos.sh <raiz>     (ex.: / ou /mnt ou airootfs da ISO)
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
ROOT="${1:?informe a raiz, ex.: /mnt}"

install -d "$ROOT/etc/xdg/quickshell" "$ROOT/usr/share/cypheros" "$ROOT/usr/bin" \
           "$ROOT/usr/share/fonts/cypheros" "$ROOT/etc/skel/.config" "$ROOT/etc/pacman.d/hooks"

# shell do desktop
rm -rf "$ROOT/etc/xdg/quickshell/cypheros"
cp -r "$SRC/shell" "$ROOT/etc/xdg/quickshell/cypheros"

# apps do CypherOS: Central, Loja e Monitor (configs do Quickshell que reaproveitam services/components do shell)
for app in central loja monitor; do
    dest="$ROOT/etc/xdg/quickshell/cypheros-$app"
    rm -rf "$dest"
    install -d "$dest"
    (cd "$SRC/apps/$app" && find . -mindepth 1 -maxdepth 1 ! -name services ! -name components -exec cp -r {} "$dest/" \;)
    ln -sfn ../cypheros/services "$dest/services"
    ln -sfn ../cypheros/components "$dest/components"
done
install -d "$ROOT/usr/share/applications" "$ROOT/usr/share/cypheros/term"
install -m644 "$SRC"/share/applications/*.desktop "$ROOT/usr/share/applications/"
install -d "$ROOT/usr/lib/systemd/user"
install -m644 "$SRC"/share/systemd/* "$ROOT/usr/lib/systemd/user/"
install -m644 "$SRC"/term/* "$ROOT/usr/share/cypheros/term/"

# ícones Prisma (completados pelo Papirus) e cursor Prisma
if [ "${CYPHER_PACOTE:-0}" != 1 ]; then
    install -d "$ROOT/usr/share/icons"
    rm -rf "$ROOT/usr/share/icons/Prisma"
    cp -r "$SRC/icones/Prisma" "$ROOT/usr/share/icons/Prisma"
    command -v gtk-update-icon-cache >/dev/null && gtk-update-icon-cache -qf "$ROOT/usr/share/icons/Prisma" || true
    if [ -d "$SRC/cursor/Prisma" ]; then
        rm -rf "$ROOT/usr/share/icons/Prisma-cursor"
        cp -r "$SRC/cursor/Prisma" "$ROOT/usr/share/icons/Prisma-cursor"
        while read -r alias alvo; do
            [ -n "$alias" ] && [ "${alias#\#}" = "$alias" ] && ln -sf "$alvo" "$ROOT/usr/share/icons/Prisma-cursor/cursors/$alias"
        done < "$SRC/cursor/aliases.txt"
    fi
fi

# comandos cypher, cypher-term e cypher-app, logo e fontes
install -m755 "$SRC/bin/cypher" "$ROOT/usr/bin/cypher"
install -m755 "$SRC/bin/cypher-term" "$ROOT/usr/bin/cypher-term"
install -m755 "$SRC/bin/cypher-app" "$ROOT/usr/bin/cypher-app"
install -m755 "$SRC/bin/cypher-shell" "$ROOT/usr/bin/cypher-shell"
install -m755 "$SRC/bin/cypher-aplicar-padrao" "$ROOT/usr/bin/cypher-aplicar-padrao"
install -m755 "$SRC/ativar-login-e-boot.sh" "$ROOT/usr/share/cypheros/ativar-login-e-boot.sh"
install -m644 "$SRC/share/logo.txt" "$ROOT/usr/share/cypheros/logo.txt"
install -m644 "$SRC/share/config.json" "$ROOT/usr/share/cypheros/config.json"
install -m644 "$SRC"/share/fonts/* "$ROOT/usr/share/fonts/cypheros/"

# configurações padrão de cada usuário novo
for d in hypr foot fastfetch; do
    rm -rf "$ROOT/etc/skel/.config/$d"
    cp -r "$SRC/config/$d" "$ROOT/etc/skel/.config/$d"
done
install -d "$ROOT/etc/skel/.config/cypheros"
install -m644 "$SRC/share/config.json" "$ROOT/etc/skel/.config/cypheros/config.json"
install -m644 "$SRC/term/cores-prisma.conf" "$ROOT/etc/skel/.config/cypheros/term-cores.conf"
install -d "$ROOT/etc/skel/.config/cypher-term"
[ -f "$ROOT/etc/skel/.config/cypher-term/usuario.conf" ] || echo "# suas mudanças no Cypher Term (fonte, opacidade, atalhos)" > "$ROOT/etc/skel/.config/cypher-term/usuario.conf"
install -m644 "$SRC/config/zsh/zshrc" "$ROOT/etc/skel/.zshrc"
cat > "$ROOT/etc/skel/.zprofile" <<'ZP'
# inicia o CypherOS ao entrar no primeiro terminal
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    if command -v start-hyprland >/dev/null; then exec start-hyprland; else exec Hyprland; fi
fi
ZP
install -d "$ROOT/etc/skel/.config/gtk-3.0" "$ROOT/etc/skel/.config/gtk-4.0"
printf '[Settings]\ngtk-theme-name=adw-gtk3-dark\ngtk-icon-theme-name=Prisma\ngtk-cursor-theme-name=Prisma-cursor\ngtk-cursor-theme-size=24\ngtk-font-name=Manrope 11\ngtk-application-prefer-dark-theme=1\n' \
    | tee "$ROOT/etc/skel/.config/gtk-3.0/settings.ini" > "$ROOT/etc/skel/.config/gtk-4.0/settings.ini"

# tela de login (greetd) e boot animado (plymouth)
install -d "$ROOT/etc/cypheros/greeter" "$ROOT/etc/greetd" "$ROOT/usr/share/plymouth/themes/cypheros"
install -m644 "$SRC/config/greeter/hyprland.conf" "$ROOT/etc/cypheros/greeter/hyprland.conf"
install -m644 "$SRC/config/greeter/config.toml" "$ROOT/etc/cypheros/greeter/greetd.toml"
install -m644 "$SRC"/plymouth/cypheros/* "$ROOT/usr/share/plymouth/themes/cypheros/"
install -m644 "$SRC/share/logo.png" "$ROOT/usr/share/cypheros/logo.png"
install -d "$ROOT/usr/share/cypheros/sons"
install -m644 "$SRC"/share/sons/*.ogg "$ROOT/usr/share/cypheros/sons/"
install -m644 "$SRC/share/emojis.json" "$ROOT/usr/share/cypheros/emojis.json"
install -m644 "$SRC/share/cava.conf" "$ROOT/usr/share/cypheros/cava.conf"
install -d "$ROOT/usr/share/cypheros/temas"
install -m644 "$SRC"/share/temas/*.json "$ROOT/usr/share/cypheros/temas/"

# identidade do sistema (reaplicada depois de cada atualização)
install -m644 "$SRC/share/os-release" "$ROOT/usr/share/cypheros/os-release"
if [ "${CYPHER_SET_OSRELEASE:-1}" = 1 ]; then
    cat > "$ROOT/etc/pacman.d/hooks/cypheros-os-release.hook" <<'HK'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = filesystem

[Action]
Description = Mantendo a identidade do CypherOS...
When = PostTransaction
Exec = /usr/bin/cp /usr/share/cypheros/os-release /usr/lib/os-release
HK
    # dentro do pacote (CYPHER_PACOTE=1) quem copia é o cypheros.install, porque o arquivo pertence ao pacote filesystem
    if [ "${CYPHER_PACOTE:-0}" != 1 ]; then
        install -d "$ROOT/usr/lib"
        cp "$SRC/share/os-release" "$ROOT/usr/lib/os-release"
    fi
fi
echo "arquivos do CypherOS instalados em $ROOT"
