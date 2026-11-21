#!/usr/bin/env bash
# Uso: restore-image.sh <nombre_imagen> <disco_destino>
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

name="${1:?Indica la imagen a restaurar}"
disk="${2:?Indica el disco destino}"

require_image "$name"
[[ -b "$disk" ]] || die "$disk no es un dispositivo de bloque"

cat <<EOF
Vas a RESTAURAR '$name' en $disk

  Imagen    : $(jq -r '.created' "$IMAGE_ROOT/$name/metadata.json" 2>/dev/null || echo 'sin fecha')
  Tamano    : $(human_size "$IMAGE_ROOT/$name")
  Destino   : $(lsblk -dno SIZE,MODEL "$disk" 2>/dev/null | tr '\n' ' ')

ATENCION: todos los datos actuales de $disk SE PERDERAN.
EOF

read -r -p 'Escribe YES para continuar: ' confirm
[[ "$confirm" == "YES" ]] || die "Operacion cancelada"

log INFO "Restaurando $name -> $disk ..."
if command -v clonezilla >/dev/null 2>&1; then
  clonezilla -s -q2 -j2 -p false restoredisk "$name" "$disk" \
    || die "Fallo la restauracion"
else
  warn "Arranca Clonezilla Live y elige device-image > restoredisk > $name > $disk"
fi

ok "Restauracion de '$name' finalizada"
log INFO "Verifica el arranque del equipo y registra el RTO (tiempo total)."
