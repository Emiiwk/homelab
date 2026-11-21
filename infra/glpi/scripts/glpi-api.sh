#!/usr/bin/env bash
# Pequeño cliente GLPI para operaciones habituales.
# Uso: glpi-api.sh <list|create|stats|users> [argumentos]
set -Eeuo pipefail

GLPI_URL="${GLPI_URL:-http://127.0.0.1:8080}"
GLPI_API_TOKEN="${GLPI_API_TOKEN:?Configura GLPI_API_TOKEN en .env}"

log() { printf '[%s] [%s] %s\n' "$(date '+%F %T')" "$1" "$2"; }
die() { log ERROR "$1"; exit 1; }

command -v jq >/dev/null || die "Necesitas jq"

SESSION="$(curl -fsS -H "Authorization: Bearer $GLPI_API_TOKEN" \
  "$GLPI_URL/apirest.php/initSession" | jq -r '.session_token')"

cleanup() {
  curl -fsS -H "Authorization: Bearer $GLPI_API_TOKEN" -H "Session-Token: $SESSION" \
    "$GLPI_URL/apirest.php/killSession" >/dev/null 2>&1 || true
}
trap cleanup EXIT

call() {
  curl -fsS -H "Authorization: Bearer $GLPI_API_TOKEN" \
    -H "Session-Token: $SESSION" "$@"
}

case "${1:-list}" in
  list)
    call "$GLPI_URL/apirest.php/Ticket?range=0-50&sort=date;DESC" \
      | jq -r '.data[] | "#\(.id) [\(.status)] \(.name)"'
    ;;
  stats)
    call "$GLPI_URL/apirest.php/Ticket?range=0-1000" \
      | jq -r '.data | group_by(.status) | map({status:.[0].status, total:length})'
    ;;
  users)
    call "$GLPI_URL/apirest.php/User?range=0-100" \
      | jq -r '.data[] | "\(.id)  \(.name)"'
    ;;
  create)
    title="${2:?Indica el titulo del ticket}"
    content="${3:-Creado desde glpi-api.sh}"
    call -X POST -H 'Content-Type: application/json' \
      -d "$(jq -n --arg n "$title" --arg c "$content" '{input:{name:$n,content:$c,urgency:3}}')" \
      "$GLPI_URL/apirest.php/Ticket" | jq .
    ;;
  *)
    die "Uso: $0 <list|stats|users|create> [titulo] [contenido]"
    ;;
esac
