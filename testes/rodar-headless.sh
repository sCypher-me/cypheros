#!/usr/bin/env bash
# Abre o shell e os apps do CypherOS num compositor sem tela (sway headless),
# guarda o log de cada um e tira um print. Roda no GitHub Actions dentro de um Arch.
# Saída: testes/saida/*.log e *.png
set -u
SRC="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$SRC/testes/saida"
rm -rf "$OUT"; mkdir -p "$OUT"

"$SRC/shell/shaders/build.sh"
CYPHER_SET_OSRELEASE=0 "$SRC/instalar-arquivos.sh" /
I=/etc/xdg/quickshell/cypheros-instalador
rm -rf "$I"; mkdir -p "$I"
(cd "$SRC/apps/instalador" && find . -mindepth 1 -maxdepth 1 ! -name services ! -name components -exec cp -r {} "$I/" \;)
ln -sfn ../cypheros/services "$I/services"; ln -sfn ../cypheros/components "$I/components"
install -m755 "$SRC/iso/cypher-instalar" /usr/local/bin/cypher-instalar
cp -r /etc/skel/.config /root/

export XDG_RUNTIME_DIR=/tmp/rt; mkdir -p -m700 "$XDG_RUNTIME_DIR"
export WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 WLR_HEADLESS_OUTPUTS=1
printf 'output HEADLESS-1 resolution 1920x1080\n' > /tmp/sway.conf
sway -c /tmp/sway.conf > "$OUT/sway.log" 2>&1 &
for _ in $(seq 50); do [ -S "$XDG_RUNTIME_DIR/wayland-1" ] && break; sleep 0.2; done
export WAYLAND_DISPLAY=wayland-1 QT_QPA_PLATFORM=wayland QT_QUICK_BACKEND=software

rodar() { # nome segundos comando...
    local nome=$1 seg=$2; shift 2
    echo "::group::$nome"
    "$@" > "$OUT/$nome.log" 2>&1 &
    local pid=$!
    sleep "$seg"
    grim "$OUT/$nome.png" 2>/dev/null || true
    kill "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
    cat "$OUT/$nome.log"
    echo "::endgroup::"
}
rodar shell 15 qs -c cypheros
for app in instalador central loja monitor; do
    rodar "$app" 8 qs -c "cypheros-$app"
done
# resumo: só as linhas de erro/aviso de QML de cada um
for f in "$OUT"/*.log; do
    echo "===== $(basename "$f")"
    grep -E "ERROR|WARN|error|Error|is not a type|not installed|Cannot|failed|TypeError|ReferenceError" "$f" | head -40
done
