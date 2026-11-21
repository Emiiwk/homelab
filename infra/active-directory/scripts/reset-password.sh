#!/usr/bin/env bash
# Uso: reset-password.sh <usuario> [nueva_password]
# Si no se pasa password, se genera una aleatoria y se muestra por pantalla.
set -Eeuo pipefail

usuario="${1:?Debes indicar el usuario}"
password="${2:-}"

log() { printf '[%s] [%s] %s\n' "$(date '+%F %T')" "$1" "$2"; }

if [[ -z "$password" ]]; then
  password="$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9!@#' | cut -c1-16)Xx1!"
  log INFO "Password generada: $password"
fi

if ! samba-tool user list | grep -qi "^${usuario}$"; then
  log ERROR "El usuario $usuario no existe"
  exit 1
fi

samba-tool user setpassword "$usuario" --newpassword="$password" >/dev/null
samba-tool user unlock "$usuario" >/dev/null 2>&1 || true
log OK "Password actualizada y cuenta desbloqueada: $usuario"

# Registro de auditoria local (sin la password)
echo "$(date '+%F %T') password reset -> $usuario por ${USER:-unknown}" \
  >> /var/log/samba/password-audit.log
