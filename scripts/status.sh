#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/lib/common.sh"

printf '\n=== homelab :: estado ===\n'
compose ps
printf '\n=== volumenes ===\n'
docker volume ls --filter name=homelab --format 'table {{.Name}}\t{{.Driver}}'
printf '\n=== tailscale ===\n'
if is_container_running homelab-tailscale; then
  docker exec homelab-tailscale tailscale status 2>/dev/null || warn "No se pudo leer tailscale status"
else
  warn "Contenedor homelab-tailscale no esta arriba"
fi
