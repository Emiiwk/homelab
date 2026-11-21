#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/lib/common.sh"

load_env
info "Levantando homelab ..."
compose up -d --remove-orphans
ok "Servicios levantados. Ejecuta 'make status' para verificar."
