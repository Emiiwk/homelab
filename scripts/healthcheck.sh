#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/lib/common.sh"

load_env
failures=0

check_container() {
  local name="$1"
  if is_container_running "$name"; then
    ok "Contenedor $name arriba"
  else
    warn "Contenedor $name NO arriba"
    failures=$((failures + 1))
  fi
}

for c in homelab-ad homelab-glpi homelab-glpi-db homelab-glpi-cache homelab-images homelab-prometheus homelab-grafana homelab-cadvisor homelab-node-exporter; do
  check_container "$c"
done

info "Comprobando DNS de AD ..."
if getent hosts dc01.homelab.local >/dev/null 2>&1; then
  ok "dc01.homelab.local resuelve"
else
  warn "dc01.homelab.local no resuelve desde el anfitrion"
fi

info "Comprobando LDAP ..."
wait_for 127.0.0.1 389 10 || failures=$((failures + 1))

info "Comprobando GLPI ..."
code="$(curl -s -o /dev/null -w '%{http_code}' http://127.0.0.1:8080 || true)"
if [[ "$code" =~ ^2|^3 ]]; then
  ok "GLPI responde HTTP $code"
else
  warn "GLPI respondio HTTP '$code'"
  failures=$((failures + 1))
fi

info "Comprobando Tailscale (servicio en el anfitrion) ..."
if systemctl is-active --quiet tailscaled && tailscale status --self 2>/dev/null | grep -q '^100\.'; then
  ok "Tailscale conectado en el anfitrion"
else
  warn "Tailscale no parece conectado en el anfitrion"
  failures=$((failures + 1))
fi

echo
if (( failures == 0 )); then
  ok "HEALTHCHECK OK"
else
  die "HEALTHCHECK FALLIDO: $failures comprobaciones fallaron"
fi
