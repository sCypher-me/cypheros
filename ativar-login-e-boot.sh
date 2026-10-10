#!/usr/bin/env bash
# Liga a tela de login do CypherOS (greetd) e o boot animado (plymouth).
# Uso: sudo ./ativar-login-e-boot.sh [login] [boot]   (sem argumentos = os dois)
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Rode com sudo."; exit 1; }
ROOT="${CYPHER_ROOT:-}"
QUAIS="${*:-login boot}"
run() { if [ -n "$ROOT" ]; then arch-chroot "$ROOT" "$@"; else "$@"; fi; }

if [[ " $QUAIS " == *" login "* ]]; then
    cp "$ROOT/etc/cypheros/greeter/greetd.toml" "$ROOT/etc/greetd/config.toml"
    # desliga outros gerenciadores de login e o login automático
    for dm in sddm gdm lightdm ly; do run systemctl disable "$dm" >/dev/null 2>&1 || true; done
    rm -f "$ROOT/etc/systemd/system/getty@tty1.service.d/autologin.conf"
    run systemctl enable greetd >/dev/null
    echo "tela de login ativada"
fi

if [[ " $QUAIS " == *" boot "* ]]; then
    CONF="$ROOT/etc/mkinitcpio.conf"
    if ! grep -qE '^HOOKS=.*plymouth' "$CONF"; then
        if grep -qE '^HOOKS=.*\bsystemd\b' "$CONF"; then
            sed -i -E '/^HOOKS=/ s/\bsystemd\b/systemd plymouth/' "$CONF"
        else
            sed -i -E '/^HOOKS=/ s/\budev\b/udev plymouth/' "$CONF"
        fi
    fi
    run plymouth-set-default-theme cypheros
    run mkinitcpio -P >/dev/null
    # systemd-boot: garante "quiet splash" nas entradas
    for e in "$ROOT"/boot/loader/entries/*.conf; do
        [ -f "$e" ] || continue
        grep -q '^options.*splash' "$e" || sed -i -E '/^options/ s/$/ quiet splash/' "$e"
    done
    # GRUB
    if [ -f "$ROOT/etc/default/grub" ] && ! grep -q 'splash' "$ROOT/etc/default/grub"; then
        sed -i -E 's/^GRUB_CMDLINE_LINUX_DEFAULT="([^"]*)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 quiet splash"/' "$ROOT/etc/default/grub"
        run grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 || true
    fi
    echo "boot animado ativado"
fi
