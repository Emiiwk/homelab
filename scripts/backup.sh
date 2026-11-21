#!/usr/bin/env bash
# Backup cifrado con restic. Requiere RESTIC_REPOSITORY y RESTIC_PASSWORD_FILE.
set -Eeuo pipefail
source "$(dirname "$0")/lib/common.sh"

load_env

RESTIC_REPOSITORY="${RESTIC_REPOSITORY:-$ROOT_DIR/backups/restic}"
RESTIC_PASSWORD_FILE="${RESTIC_PASSWORD_FILE:-$HOME/.restic-pass}"
export RESTIC_REPOSITORY RESTIC_PASSWORD_FILE

command -v restic >/dev/null || die "Falta restic (https://restic.net)"

if [[ ! -f "$RESTIC_PASSWORD_FILE" ]]; then
  die "No existe $RESTIC_PASSWORD_FILE. Crealo con: openssl rand -base64 32 > ~/.restic-pass && chmod 600 ~/.restic-pass"
fi

[[ -d "$RESTIC_REPOSITORY" ]] || {
  info "Inicializando repositorio restic ..."
  restic init
}

info "Volcando MariaDB ..."
dump="$ROOT_DIR/backups/glpi-$(date +%Y%m%d-%H%M).sql"
compose exec -T glpi-db mariadb-dump \
  -u"${GLPI_DB_USER:-glpi}" -p"${GLPI_DB_PASSWORD:?}" \
  "${GLPI_DB_NAME:-glpi}" > "$dump"
chmod 600 "$dump"
ok "Dump creado: $dump"

info "Backup de configuracion y volumenes ..."
restic backup \
  "$ROOT_DIR/infra" \
  "$ROOT_DIR/docs" \
  "$ROOT_DIR/.env" \
  "$dump" \
  --tag homelab --tag scheduled \
  --exclude '*.img' --exclude '*.iso'

info "Verificando integridad ..."
restic check
restic forget --keep-daily 7 --keep-weekly 4 --keep-monthly 3 --prune

ok "Backup completado"
restic snapshots --latest 5
