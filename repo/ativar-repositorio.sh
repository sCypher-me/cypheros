#!/usr/bin/env bash
# Liga o repositório [cypheros] neste Arch: depois disso o CypherOS se atualiza junto com o sistema.
# Uso: sudo ./ativar-repositorio.sh [endereço]   (padrão: GitHub Pages do projeto)
set -euo pipefail
SERVIDOR="${1:-https://scypher-me.github.io/cypheros/\$arch}"
[ "$(id -u)" -eq 0 ] || { echo "Rode com sudo."; exit 1; }
if grep -q '^\[cypheros\]' /etc/pacman.conf; then
    echo "O repositório [cypheros] já está no /etc/pacman.conf."
else
    printf '\n[cypheros]\nSigLevel = Optional TrustAll\nServer = %s\n' "$SERVIDOR" >> /etc/pacman.conf
    echo "Repositório [cypheros] adicionado."
fi
pacman -Sy
echo "Pronto. Instale ou atualize com: sudo pacman -S cypheros"
