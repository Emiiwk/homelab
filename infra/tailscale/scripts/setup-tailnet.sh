#!/usr/bin/env bash
# Verifica el nodo Tailscale del anfitrion y recuerda aprobar las rutas.
set -Eeuo pipefail

log() { printf '[%s] [%s] %s\n' "$(date '+%F %T')" "$1" "$2"; }
die() { log ERROR "$1"; exit 1; }

HOSTNAME_TS="${TS_HOSTNAME:-homelab}"
ROUTES="${TS_ROUTES:-10.10.0.0/16,192.168.0.0/24}"

systemctl is-active --quiet tailscaled || die "tailscaled.service no esta activo"

if [[ "$(sysctl -n net.ipv4.ip_forward 2>/dev/null)" != "1" ]]; then
  log WARN "net.ipv4.ip_forward esta a 0; revisa /etc/sysctl.d/99-tailscale.conf"
fi

log INFO "Estado del nodo $HOSTNAME_TS ..."
tailscale status --self || true

echo
log INFO "Rutas anunciadas: $ROUTES"
log INFO "Si no aparecen en 'PrimaryRoutes', apruebalas en:"
log INFO "  https://login.tailscale.com/admin/machines"
log INFO "  $HOSTNAME_TS > Edit route settings > marcar rutas > Save"
