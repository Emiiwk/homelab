#!/usr/bin/env bash
# Uso: create-image.sh <nombre_imagen> <disco_origen> ["notas"]
# Ejecutar desde un entorno con clonezilla disponible o contra el repo NFS.
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

name="${1:?Indica el nombre de la imagen}"
disk="${2:?Indica el disco origen (ej. /dev/sda)}"
notes="${3:-Imagen de laboratorio}"

[[ -b "$disk" ]] || die "$disk no es un dispositivo de bloque"
[[ "$name" =~ ^[a-zA-Z0-9._-]+$ ]] || die "Nombre de imagen no valido"

dest="$IMAGE_ROOT/$name"
[[ -e "$dest" ]] && die "La imagen '$name' ya existe. Borrala antes de recrearla."

df -h "$IMAGE_ROOT" | tail -1 | awk '{print "Espacio libre: "$4}'

# No se escribe metadata/checksum si no hubo una captura real.
command -v clonezilla >/dev/null 2>&1 \
  || die "Clonezilla no disponible; arranca Clonezilla Live o instala el paquete clonezilla"

log INFO "Capturando $disk -> $name ..."
mkdir -p "$dest"

# Clonezilla savedisk en modo no interactivo.
# -q2: modo principiante; -z1p: zstd paralelo; -p false: no apagar al terminar.
clonezilla -s -q2 -j2 -z1p -p false savedisk "$name" "$disk" \
  -scs "$dest" || die "Clonezilla devolvio error"

size="$(du -sb "$dest" | cut -f1)"
write_metadata "$name" "$disk" "$size" "$notes"

if compgen -G "$dest/*" >/dev/null; then
  (cd "$dest" && find . -type f ! -name 'sha256sums.txt' -print0 \
     | sort -z | xargs -0 sha256sum > sha256sums.txt)
  sha="$(sha256sum "$dest/sha256sums.txt" | cut -d' ' -f1)"
  jq --arg sha "$sha" '.sha256 = $sha' "$dest/metadata.json" > "$dest/metadata.json.tmp" \
    && mv "$dest/metadata.json.tmp" "$dest/metadata.json"
  ok "Checksum guardado: $sha"
fi

ok "Imagen '$name' creada correctamente ($(human_size "$dest"))"
