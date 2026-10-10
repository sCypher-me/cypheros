#!/usr/bin/env bash
# Gera a ISO do CypherOS. Rode no seu Arch: sudo ./iso/build-iso.sh
# Resultado: ./saida/cypheros-AAAA.MM.DD-x86_64.iso
set -euo pipefail
SRC="$(cd "$(dirname "$0")/.." && pwd)"
WORK="${CYPHER_WORK:-/tmp/cypheros-build}"
OUT="$SRC/saida"
C=$'\e[38;2;56;225;255m'; R=$'\e[0m'

[ "$(id -u)" -eq 0 ] || { echo "Rode com sudo: sudo $0"; exit 1; }
command -v mkarchiso >/dev/null || pacman -S --needed --noconfirm archiso
command -v jq >/dev/null || pacman -S --needed --noconfirm jq
command -v qsb >/dev/null || [ -x /usr/lib/qt6/bin/qsb ] || pacman -S --needed --noconfirm qt6-shadertools

echo "${C}1/5${R} Preparando o perfil a partir do releng oficial..."
rm -rf "$WORK"
mkdir -p "$WORK"
cp -r /usr/share/archiso/configs/releng "$WORK/perfil"
P="$WORK/perfil"

echo "${C}2/5${R} Adicionando os pacotes do CypherOS..."
# o instalador gráfico precisa destes (a maioria já vem no releng)
{ echo; echo "# CypherOS"; grep -v -e '^#' -e '^$' "$SRC/pacotes.txt"; printf '%s\n' git gptfdisk parted cryptsetup dosfstools btrfs-progs grub jq curl; } >> "$P/packages.x86_64"
sort -u -o "$P/packages.x86_64" "$P/packages.x86_64"

sed -i \
    -e 's/^iso_name=.*/iso_name="cypheros"/' \
    -e 's/^iso_label=.*/iso_label="CYPHEROS_$(date --date="@${SOURCE_DATE_EPOCH:-$(date +%s)}" +%Y%m)"/' \
    -e 's/^iso_publisher=.*/iso_publisher="CypherOS <https:\/\/github.com\/sCypher-me>"/' \
    -e 's/^iso_application=.*/iso_application="CypherOS Live"/' \
    "$P/profiledef.sh"
cat >> "$P/profiledef.sh" <<'PD'
file_permissions+=(
  ["/usr/local/bin/cypher-instalar"]="0:0:755"
  ["/usr/share/cypheros/src/instalar-arquivos.sh"]="0:0:755"
  ["/usr/share/cypheros/src/ativar-login-e-boot.sh"]="0:0:755"
  ["/usr/share/cypheros/src/bin/cypher"]="0:0:755"
  ["/usr/bin/cypher"]="0:0:755"
)
PD

echo "${C}3/5${R} Compilando os wallpapers e copiando o sistema..."
"$SRC/shell/shaders/build.sh"
A="$P/airootfs"
"$SRC/instalar-arquivos.sh" "$A"
# cópia completa para o instalador usar
install -d "$A/usr/share/cypheros/src"
cp -r "$SRC/shell" "$SRC/config" "$SRC/bin" "$SRC/share" "$SRC/plymouth" "$SRC/pacotes.txt" "$SRC/instalar-arquivos.sh" "$SRC/ativar-login-e-boot.sh" "$A/usr/share/cypheros/src/"
install -Dm755 "$SRC/iso/cypher-instalar" "$A/usr/local/bin/cypher-instalar"

# instalador gráfico (só na ISO): app Quickshell que usa os services e components do shell
I="$A/etc/xdg/quickshell/cypheros-instalador"
rm -rf "$I"; install -d "$I"
(cd "$SRC/apps/instalador" && find . -mindepth 1 -maxdepth 1 ! -name services ! -name components -exec cp -r {} "$I/" \;)
ln -sfn ../cypheros/services "$I/services"
ln -sfn ../cypheros/components "$I/components"
install -Dm644 "$SRC/iso/cypheros-instalador.desktop" "$A/usr/share/applications/cypheros-instalador.desktop"

# sessão ao vivo: usuário "cypher" (senha "cypher"), entra direto no desktop
# o instalador fica fixado no começo do dock e as boas-vindas do primeiro login não aparecem
CFG="$A/etc/skel/.config/cypheros/config.json"
jq '.userName = "CypherOS" | .pinnedApps = (["cypheros-instalador"] + (.pinnedApps - ["cypheros-instalador"]))' "$CFG" > "$CFG.tmp" && mv "$CFG.tmp" "$CFG"
touch "$A/etc/skel/.config/cypheros/.boas-vindas-ok"
cat >> "$A/etc/skel/.config/hypr/usuario.conf" <<'HC'
# sessão ao vivo: o instalador gráfico abre sozinho (fechou? clique no ícone dele no dock)
exec-once = sleep 3 && cypher-app instalador
HC
cat > "$A/etc/systemd/system/cypher-live-user.service" <<'SV'
[Unit]
Description=Cria o usuário da sessão ao vivo do CypherOS
Before=getty@tty1.service
ConditionPathExists=!/home/cypher

[Service]
Type=oneshot
ExecStart=/usr/bin/useradd -m -G wheel,video,audio,input -s /bin/zsh cypher
ExecStart=/usr/bin/sh -c "echo cypher:cypher | chpasswd"
ExecStart=/usr/bin/sh -c "echo 'cypher ALL=(ALL:ALL) NOPASSWD: ALL' > /etc/sudoers.d/90-live && chmod 440 /etc/sudoers.d/90-live"

[Install]
WantedBy=multi-user.target
SV
install -d "$A/etc/systemd/system/multi-user.target.wants" "$A/etc/systemd/system/getty@tty1.service.d"
ln -sf ../cypher-live-user.service "$A/etc/systemd/system/multi-user.target.wants/cypher-live-user.service"
printf '[Service]\nExecStart=\nExecStart=-/sbin/agetty -o "-p -f -- \\\\u" --noclear --autologin cypher %%I $TERM\n' \
    > "$A/etc/systemd/system/getty@tty1.service.d/autologin.conf"

# rede pelo NetworkManager (o releng usa iwd + systemd-networkd)
ln -sf /usr/lib/systemd/system/NetworkManager.service "$A/etc/systemd/system/multi-user.target.wants/NetworkManager.service"
ln -sf /usr/lib/systemd/system/bluetooth.service "$A/etc/systemd/system/multi-user.target.wants/bluetooth.service"
rm -f "$A/etc/systemd/system/multi-user.target.wants/iwd.service" \
      "$A/etc/systemd/system/multi-user.target.wants/systemd-networkd.service" \
      "$A/etc/systemd/system/sockets.target.wants/systemd-networkd.socket" \
      "$A/etc/systemd/system/network-online.target.wants/systemd-networkd-wait-online.service"

echo "${C}4/5${R} Trocando os nomes do menu de boot para CypherOS..."
grep -rl "Arch Linux" "$P/efiboot" "$P/syslinux" "$P/grub" 2>/dev/null | while read -r f; do
    sed -i 's/Arch Linux install medium/CypherOS/g; s/Arch Linux/CypherOS/g' "$f"
done

echo "${C}5/5${R} Gerando a ISO (pode levar de 10 a 30 minutos)..."
mkdir -p "$OUT"
mkarchiso -v -w "$WORK/trabalho" -o "$OUT" "$P"
rm -rf "$WORK"
chown -R "${SUDO_UID:-0}:${SUDO_GID:-0}" "$OUT"
echo
echo "${C}◆ ISO pronta:${R} $(ls -1 "$OUT"/cypheros-*.iso | tail -1)"
echo "Grave num pendrive com: sudo dd if=<iso> of=/dev/sdX bs=4M status=progress oflag=sync"
