#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/lib/common.sh"

info "Parando homelab ..."
compose stop
ok "Servicios parados (los datos se conservan)."
