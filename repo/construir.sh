#!/usr/bin/env bash
# Constrói os pacotes do CypherOS e monta o repositório [cypheros] em saida/repo/x86_64.
# Rode como usuário comum (não root), num Arch com base-devel.
set -euo pipefail
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
DEST="$RAIZ/saida/repo/x86_64"
mkdir -p "$DEST"
cd "$RAIZ/repo/cypheros"
PKGDEST="$DEST" makepkg -cf --nodeps
cd "$DEST"
rm -f cypheros.db* cypheros.files*
repo-add -q cypheros.db.tar.gz ./*.pkg.tar.zst
# pacotes antigos: mantém só a versão mais nova de cada um
ls -1t ./*.pkg.tar.zst | awk -F'-[0-9]' '{ if (seen[$1]++) print }' | xargs -r rm -f
echo
echo "Repositório pronto em: $DEST"
echo "Para testar localmente, adicione ao /etc/pacman.conf:"
echo
echo "[cypheros]"
echo "SigLevel = Optional TrustAll"
echo "Server = file://$DEST"
