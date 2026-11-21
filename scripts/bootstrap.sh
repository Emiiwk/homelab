#!/usr/bin/env bash
# Preparacion inicial del anfitrion para el homelab.
set -Eeuo pipefail
source "$(dirname "$0")/lib/common.sh"

info "Comprobando requisitos ..."
for cmd in docker git curl jq; do
  command -v "$cmd" >/dev/null || die "Falta el comando $cmd"
done

docker compose version >/dev/null 2>&1 || die "Necesitas Docker Compose v2"
info "Docker y Compose OK"

if [[ ! -f "$ENV_FILE" ]]; then
  cp "$ROOT_DIR/.env.example" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  warn "Creado $ENV_FILE -> EDITALO antes de arrancar los servicios"
else
  ok ".env ya existe"
fi

info "Creando directorios ..."
mkdir -p "$ROOT_DIR"/{backups,docs/screenshots,infra/clonezilla/images}
touch "$ROOT_DIR/infra/clonezilla/images/.gitkeep"

info "Ajustando parametros del kernel para subnet router ..."
if [[ "$(sysctl -n net.ipv4.ip_forward 2>/dev/null)" != "1" ]]; then
  warn "net.ipv4.ip_forward = 0. Se intentara aplicar (puede pedir sudo)"
  sudo sysctl -w net.ipv4.ip_forward=1 || warn "Aplicarlo manualmente antes de Tailscale"
fi
if ! grep -q '^net.ipv4.ip_forward = 1' /etc/sysctl.d/99-homelab.conf 2>/dev/null; then
  printf 'net.ipv4.ip_forward = 1\nnet.ipv6.conf.all.forwarding = 1\n' \
    | sudo tee /etc/sysctl.d/99-homelab.conf >/dev/null || true
fi

info "Validando compose ..."
compose config --quiet && ok " compose.yml validado"

ok "Bootstrap completado. Siguiente paso: make up"
