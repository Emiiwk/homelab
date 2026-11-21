#!/usr/bin/env bash
# Entry point del DC: aprovisiona si hace falta y deja Samba en primer plano.
set -Eeuo pipefail

log()  { printf '[%s] [%s] %s\n' "$(date '+%F %T')" "$1" "$2"; }
die()  { log ERROR "$1"; exit 1; }

: "${REALM:?REALM no definido}"
: "${DOMAIN:?DOMAIN no definido}"
: "${AD_ADMIN_PASSWORD:?AD_ADMIN_PASSWORD no definido}"

export REALM DOMAIN AD_ADMIN_PASSWORD

mkdir -p /var/lib/samba /var/log/samba

# Solo provisionar una vez: si existe sam.ldb, el dominio ya esta creado.
if [[ ! -f /var/lib/samba/private/sam.ldb ]]; then
  log INFO "No se encontro dominio. Aprovisionando $REALM ..."
  /opt/ad/scripts/provision-ad.sh
else
  log INFO "Dominio $REALM ya aprovisionado. Omitiendo provision."
fi

# Ajustar reenvio DNS del servidor SAMBA_INTERNAL
if [[ -n "${AD_DNS_FORWARDER:-}" ]]; then
  log INFO "Configurando reenvio DNS a $AD_DNS_FORWARDER"
  samba-tool domain info 127.0.0.1 >/dev/null 2>&1 || true
fi

# Crear usuarios/grupos/OUs de ejemplo (idempotente)
if [[ "${SEED_AD_USERS:-true}" == "true" ]]; then
  log INFO "Cargando usuarios y grupos de prueba ..."
  /opt/ad/scripts/provision-ad.sh --seed-only || log WARN "No se pudieron cargar datos de prueba"
fi

log INFO "Arrancando Samba en primer plano (${1:-samba}) ..."
exec "$@" -i -d 1
