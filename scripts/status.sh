#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/lib/common.sh"

printf '\n=== homelab :: estado ===\n'
compose ps
printf '\n=== volumenes ===\n'
docker volume ls --filter name=homelab --format 'table {{.Name}}\t{{.Driver}}'
printf '\n=== tailscale (anfitrion) ===\n'
if systemctl is-active --quiet tailscaled; then
  tailscale status --self 2>/dev/null || warn "No se pudo leer tailscale status"
else
  warn "tailscaled.service no esta activo"
fi
