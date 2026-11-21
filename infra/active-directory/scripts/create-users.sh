#!/usr/bin/env bash
# Crea usuarios y grupos del dominio a partir de config/users.csv.
# Idempotente: si el usuario ya existe, solo actualiza grupo y password.
set -Eeuo pipefail

ADMIN_PASS="${AD_ADMIN_PASSWORD:?}"
CSV="${1:-/opt/ad/config/users.csv}"

log()  { printf '[%s] [%s] %s\n' "$(date '+%F %T')" "$1" "$2"; }
ok()   { log OK "$1"; }
warn() { log WARN "$1"; }
die()  { log ERROR "$1"; exit 1; }

[[ -f "$CSV" ]] || die "No se encontro $CSV"

created=0
updated=0
skipped=0

while IFS=',' read -r usuario nombre apellido password grupo ou; do
  # Saltar cabecera, comentarios y lineas vacias
  [[ -z "${usuario:-}" || "$usuario" == usuario || "$usuario" == \#* ]] && continue
  usuario="$(echo "$usuario" | xargs)"

  if [[ "$password" == "USE_ENV" ]]; then
    env_key="AD_PASS_$(printf '%s' "$usuario" | tr '[:lower:]' '[:upper:]')"
    password="${!env_key:-}"
    if [[ -z "$password" ]]; then
      if [[ "$usuario" == "administrador" ]]; then
        password="$ADMIN_PASS"
      else
        die "Falta $env_key en .env para crear/actualizar $usuario"
      fi
    fi
  fi

  if samba-tool user list 2>/dev/null | grep -qi "^${usuario}$"; then
    warn "Usuario ya existe: $usuario (actualizando pertenencia)"
    skipped=$((skipped + 1))
    # La password se rota fuera del repo; si cambia, se aplica aqui.
    if [[ -n "${password:-}" ]]; then
      samba-tool user setpassword "$usuario" --newpassword="$password" >/dev/null 2>&1 \
        && ok "Password sincronizada: $usuario" \
        || warn "No se pudo sincronizar la password de $usuario"
    fi
  else
    samba-tool user create "$usuario" "$password" \
      --given-name="$nombre" --surname="$apellido" \
      --description="Usuario de laboratorio creado por create-users.sh" \
      >/dev/null 2>&1 || die "No se pudo crear $usuario"
    samba-tool user setexpiry "$usuario" --noexpiry >/dev/null 2>&1 || true
    ok "Usuario creado: $usuario"
    created=$((created + 1))
  fi

  # Pertenencia a grupo (Domain Admins se llama 'domain admins' en samba-tool)
  if [[ -n "${grupo:-}" ]]; then
    if samba-tool group listmembers "$grupo" 2>/dev/null | grep -qi "^${usuario}$"; then
      warn "$usuario ya pertenece a $grupo"
    else
      samba-tool group addmembers "$grupo" "$usuario" >/dev/null 2>&1 \
        && ok "$usuario -> $grupo" \
        || warn "No se pudo anadir $usuario a $grupo"
    fi
  fi

  # Mover a la OU indicada (si aplica y la OU existe)
  if [[ -n "${ou:-}" ]]; then
    dn="$(samba-tool user show "$usuario" 2>/dev/null | grep -m1 '^dn:' | cut -d' ' -f2- || true)"
    if [[ -n "$dn" && "$dn" != *"OU=$ou"* ]]; then
      samba-tool user move "$usuario" "OU=$ou,OU=Usuarios,OU=Homelab,DC=homelab,DC=local" >/dev/null 2>&1 \
        && ok "$usuario movido a OU=$ou" \
        || warn "No se pudo mover $usuario a $ou"
    fi
  fi
done < "$CSV"

log INFO "Resumen: creados=$created, existentes=$skipped, actualizados=$updated"
wbinfo -u
