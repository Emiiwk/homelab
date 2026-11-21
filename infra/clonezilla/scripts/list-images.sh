#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

printf '%-24s %-12s %-8s %s\n' 'IMAGEN' 'FECHA' 'TAMANO' 'ESTADO'
printf '%-24s %-12s %-8s %s\n' '------------------------' '------------' '--------' '--------'

shopt -s nullglob
for dir in "$IMAGE_ROOT"/*/; do
  name="$(basename "$dir")"
  [[ "$name" == .* ]] && continue
  if [[ -f "$dir/metadata.json" ]]; then
    fecha="$(jq -r '.created // "desconocida"' "$dir/metadata.json" | cut -c1-10)"
    checksum="$(jq -r '.sha256 // empty' "$dir/metadata.json")"
    estado="OK"
    [[ -n "$checksum" ]] && estado="OK (verificado)"
  else
    fecha="sin metadata"
    estado="SIN VERIFICAR"
  fi
  tamano="$(human_size "$dir")"
  printf '%-24s %-12s %-8s %s\n' "$name" "$fecha" "$tamano" "$estado"
done
