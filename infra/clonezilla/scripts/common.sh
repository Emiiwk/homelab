#!/usr/bin/env bash
# Funciones compartidas por los scripts de imagenes.
set -Eeuo pipefail

IMAGE_ROOT="${IMAGE_ROOT:-/var/lib/docker/volumes/homelab_images-data/_data}"
# Si el volumen se monta en otro sitio, se puede override con IMAGE_ROOT.

log()  { printf '[%s] [%s] %s\n' "$(date '+%F %T')" "$1" "$2"; }
ok()   { log OK "$1"; }
warn() { log WARN "$1"; }
die()  { log ERROR "$1"; exit 1; }

require_image() {
  local name="$1"
  [[ -d "$IMAGE_ROOT/$name" ]] || die "No existe la imagen '$name' en $IMAGE_ROOT"
}

human_size() {
  du -sh "$1" 2>/dev/null | cut -f1
}

write_metadata() {
  local name="$1" disk="$2" size="$3" notes="${4:-}"
  local dir="$IMAGE_ROOT/$name"
  mkdir -p "$dir"
  cat > "$dir/metadata.json" <<EOF
{
  "name": "$name",
  "created": "$(date -Iseconds)",
  "source_disk": "$disk",
  "size_bytes": $size,
  "compression": "zstd -p",
  "notes": "$notes"
}
EOF
  cat > "$dir/info.txt" <<EOF
Imagen:     $name
Creada:     $(date '+%F %T %z')
Disco:      $disk
Tamano:     $size bytes
Notas:      $notes
EOF
}
