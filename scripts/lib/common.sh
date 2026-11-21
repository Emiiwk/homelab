#!/usr/bin/env bash
# Librerias compartidas por los scripts del homelab.
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENV_FILE="${ENV_FILE:-$ROOT_DIR/.env}"
COMPOSE_FILE="${COMPOSE_FILE:-$ROOT_DIR/infra/docker-compose.yml}"

log()  { printf '[%s] [%s] %s\n' "$(date '+%F %T')" "$1" "$2"; }
info() { log INFO "$1"; }
ok()   { log OK "$1"; }
warn() { log WARN "$1"; }
die()  { log ERROR "$1"; exit 1; }

require_env() {
  local var="$1"
  [[ -n "${!var:-}" ]] || die "Falta la variable $var en $ENV_FILE"
}

load_env() {
  [[ -f "$ENV_FILE" ]] || die "No se encontro $ENV_FILE. Copia .env.example a .env"
  # shellcheck source=/dev/null
  set -a
  source "$ENV_FILE"
  set +a
}

compose() {
  docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" "$@"
}

wait_for() {
  local host="$1" port="$2" timeout="${3:-60}" i=1
  while (( i <= timeout )); do
    if (echo > "/dev/tcp/$host/$port") >/dev/null 2>&1; then
      ok "$host:$port disponible"
      return 0
    fi
    (( i % 10 == 0 )) && info "Esperando $host:$port ... ($i/$timeout)"
    sleep 1
    ((i++))
  done
  die "Timeout esperando $host:$port"
}

is_container_running() {
  [[ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null || echo false)" == "true" ]]
}
