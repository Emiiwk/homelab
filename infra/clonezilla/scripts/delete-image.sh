#!/usr/bin/env bash
# Uso: delete-image.sh <nombre_imagen>
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

name="${1:?Indica la imagen a borrar}"
require_image "$name"

echo "Vas a BORRAR la imagen '$name' ($(human_size "$IMAGE_ROOT/$name"))"
read -r -p 'Escribe DELETE para confirmar: ' confirm
[[ "$confirm" == "DELETE" ]] || die "Operacion cancelada"

rm -rf -- "$IMAGE_ROOT/$name"
ok "Imagen '$name' eliminada"
