#!/usr/bin/env bash
# Arranca el nodo homelab y verifica su estado en la tailnet.
set -Eeuo pipefail

COMPOSE_FILE="$(dirname "$0")/../docker-compose.yml"
ENV_FILE="${ENV_FILE:-/home/emi/homelab/.env}"

log()  { printf '[%s] [%s] %s\n' "$(date '+%F %T')" "$1" "$2"; }
die()  { log ERROR "$1"; exit 1; }

[[ -f "$ENV_FILE" ]] || die "No se encontro $ENV_FILE"
# shellcheck disable=SC1090
source "$ENV_FILE"
: "${TS_AUTHKEY:?Configura TS_AUTHKEY en .env}"

log INFO "Asegurando ip_forward en el anfitrion ..."
if [[ "$(sysctl -n net.ipv4.ip_forward 2>/dev/null)" != "1" ]]; then
  warn_local() { printf '[%s] [WARN] %s\n' "$(date '+%F %T')" "$1"; }
  warn_local "net.ipv4.ip_forward esta a 0. Ejecuta: sudo sysctl -w net.ipv4.ip_forward=1"
fi

log INFO "Levantando nodo Tailscale ($TS_HOSTNAME) ..."
docker compose --env-file "$ENV_FILE" -f "$COMPOSE_FILE" up -d

for i in $(seq 1 30); do
  if docker exec homelab-tailscale tailscale status >/dev/null 2>&1; then
    ok_local() { printf '[%s] [OK] %s\n' "$(date '+%F %T')" "$1"; }
    ok_local "Tailscale respondiendo"
    break
  fi
  [[ "$i" -eq 30 ]] && die "Tailscale no respondio tras 30 intentos"
  sleep 2
done

echo
docker exec homelab-tailscale tailscale status || true
echo
log INFO "Rutas anunciadas: ${TS_ROUTES:-10.10.0.0/16,192.168.1.0/24}"
log INFO "SIGUIENTE PASO: en https://login.tailscale.com/admin/machines"
log INFO "  abre el nodo '$TS_HOSTNAME' > Edit route settings > marca las rutas > Save."
log INFO "  Las rutas NO funcionan hasta que se aprueban en la consola."
