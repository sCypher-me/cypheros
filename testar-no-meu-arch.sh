#!/usr/bin/env bash
# Instala o CypherOS no Arch que você já usa, sem formatar nada.
# Suas configs atuais do Hyprland, foot e fastfetch vão para uma pasta de backup.
set -euo pipefail
SRC="$(cd "$(dirname "$0")" && pwd)"
C=$'\e[38;2;56;225;255m'; R=$'\e[0m'

[ "$(id -u)" -eq 0 ] && { echo "Rode como seu usuário normal (o script pede sudo quando precisar)."; exit 1; }
command -v pacman >/dev/null || { echo "Isso precisa rodar no Arch Linux."; exit 1; }

echo "${C}1/4${R} Instalando pacotes..."
mapfile -t PKGS < <(grep -v -e '^#' -e '^$' "$SRC/pacotes.txt")
sudo pacman -S --needed --noconfirm "${PKGS[@]}"

echo "${C}2/4${R} Compilando os wallpapers animados..."
"$SRC/shell/shaders/build.sh"

echo "${C}3/4${R} Instalando o CypherOS no sistema..."
sudo CYPHER_SET_OSRELEASE="${CYPHER_SET_OSRELEASE:-0}" "$SRC/instalar-arquivos.sh" /
sudo fc-cache -f >/dev/null

echo "${C}4/4${R} Aplicando suas configurações (com backup)..."
cypher-aplicar-padrao
# outro daemon de notificação brigaria com o do CypherOS
pkill -x mako 2>/dev/null || true; pkill -x dunst 2>/dev/null || true; pkill -x swaync 2>/dev/null || true
sudo systemctl enable --now NetworkManager bluetooth >/dev/null 2>&1 || true

echo
read -rp "Ativar a tela de login do CypherOS (troca o seu login atual)? [s/N] " L
read -rp "Ativar o boot animado do CypherOS? [s/N] " B
Q=""; [[ "$L" =~ ^[sS] ]] && Q="login"; [[ "$B" =~ ^[sS] ]] && Q="$Q boot"
# shellcheck disable=SC2086
[ -n "$Q" ] && sudo "$SRC/ativar-login-e-boot.sh" $Q

echo
echo "${C}Pronto!${R} Suas configs antigas ficaram em ~/.config/cypheros-backup-*"
echo "Saia do Hyprland (SUPER+M ou 'hyprctl dispatch exit') e entre de novo."
echo "Para usar o zsh do CypherOS como padrão: chsh -s /bin/zsh"
