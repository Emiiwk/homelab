#!/usr/bin/env bash
# Aprovisiona el dominio, las OUs, los grupos y los permisos de compartidos.
# Idempotente: se puede ejecutar las veces que haga falta.
set -Eeuo pipefail

REALM="${REALM:-HOMELAB.LOCAL}"
DOMAIN="${DOMAIN:-homelab.local}"
NETBIOS="${NETBIOS_NAME:-HOMELAB}"
ADMIN_PASS="${AD_ADMIN_PASSWORD:?}"
SEED_ONLY="${1:-}"

BASE_DN="DC=homelab,DC=local"   # derivado de homelab.local

log()  { printf '[%s] [%s] %s\n' "$(date '+%F %T')" "$1" "$2"; }
ok()   { log OK "$1"; }
warn() { log WARN "$1"; }
die()  { log ERROR "$1"; exit 1; }

ou_exists() {
  samba-tool ou list 2>/dev/null | grep -qi "^${1}$"
}

group_exists() {
  samba-tool group list 2>/dev/null | grep -qi "^${1,,}$"
}

create_ou() {
  local dn="$1" name="$2"
  if samba-tool ou list 2>/dev/null | grep -qi "^${name}$"; then
    warn "OU ya existe: $name"
  else
    samba-tool ou create "$dn" --description="OU $name creada por provision-ad.sh" >/dev/null \
      && ok "OU creada: $dn"
  fi
}

# ------------------------------------------------------------------
# 1. Dominio
# ------------------------------------------------------------------
if [[ "$SEED_ONLY" != "--seed-only" ]]; then
  if [[ -f /var/lib/samba/private/sam.ldb ]]; then
    warn "El dominio ya existe. Omitiendo samba-tool domain provision."
  else
    log INFO "Ejecutando samba-tool domain provision ..."
    # El smb.conf por defecto de Debian tiene server role = standalone server,
    # incompatible con --server-role=dc. samba-tool genera uno correcto.
    if [[ -f /etc/samba/smb.conf ]]; then
      mv /etc/samba/smb.conf /etc/samba/smb.conf.original
      warn "smb.conf de Debian apartado; samba-tool generara el del DC"
    fi
    samba-tool domain provision \
      --server-role=dc \
      --realm="$REALM" \
      --domain="$NETBIOS" \
      --adminpass="$ADMIN_PASS" \
      --dns-backend=SAMBA_INTERNAL \
      --function-level=2008_R2 \
      --use-rfc2307 \
      >/var/log/samba/provision.log 2>&1 \
      || die "Fallo al aprovisionar. Revisa /var/log/samba/provision.log"
    ok "Dominio $REALM aprovisionado"
  fi
fi

# Añadir los compartidos de laboratorio a smb.conf (solo si no estan ya)
if ! grep -q '^\[soporte\]' /etc/samba/smb.conf 2>/dev/null; then
  log INFO "Añadiendo compartidos de laboratorio a smb.conf ..."
  cat /opt/ad/config/shares.conf >> /etc/samba/smb.conf
  ok "Compartidos añadidos"
fi

# ------------------------------------------------------------------
# 2. Estructura de OUs
# ------------------------------------------------------------------
log INFO "Creando estructura de OUs ..."
create_ou "OU=Homelab,$BASE_DN"        "Homelab"
create_ou "OU=Usuarios,OU=Homelab,$BASE_DN"   "Usuarios"
create_ou "OU=TI,OU=Usuarios,OU=Homelab,$BASE_DN" "TI"
create_ou "OU=Operaciones,OU=Usuarios,OU=Homelab,$BASE_DN" "Operaciones"
create_ou "OU=Invitados,OU=Usuarios,OU=Homelab,$BASE_DN" "Invitados"
create_ou "OU=Equipos,OU=Homelab,$BASE_DN" "Equipos"
create_ou "OU=Servidores,OU=Equipos,OU=Homelab,$BASE_DN" "Servidores"
create_ou "OU=Clientes,OU=Equipos,OU=Homelab,$BASE_DN" "Clientes"
create_ou "OU=Grupos,OU=Homelab,$BASE_DN" "Grupos"

# ------------------------------------------------------------------
# 3. Grupos
# ------------------------------------------------------------------
log INFO "Creando grupos ..."
while IFS=',' read -r name description; do
  [[ -z "$name" || "$name" == \#* ]] && continue
  if group_exists "$name"; then
    warn "Grupo ya existe: $name"
  else
    samba-tool group add "$name" --description="$description" >/dev/null \
      && ok "Grupo creado: $name"
  fi
done < /opt/ad/config/groups.csv

# ------------------------------------------------------------------
# 4. Permisos sobre compartidos (SID -> ACL)
# ------------------------------------------------------------------
log INFO "Aplicando permisos sobre /srv/shares ..."
mkdir -p /srv/shares/{soporte,usuarios,invitados}

apply_acl() {
  local group="$1" path="$2" perms="$3"
  local sid
  sid="$(wbinfo --name-to-sid "HOMELAB\\$group" 2>/dev/null | awk '{print $1}')" || true
  if [[ -z "$sid" ]]; then
    warn "No se pudo resolver SID de $group (winbind aun no arranco). Se aplicara en el siguiente arranque."
    return 0
  fi
  setfacl -m "default:group:$sid:$perms" "$path" 2>/dev/null || true
  setfacl -m "group:$sid:$perms" "$path" 2>/dev/null || true
  ok "ACL aplicada: $group -> $path ($perms)"
}

apply_acl "Soporte"    /srv/shares/soporte    rwx
apply_acl "Usuarios"   /srv/shares/usuarios   rwx
apply_acl "Invitados"  /srv/shares/invitados  r-x

log INFO "Provision completado. OUs: 9, grupos: $(samba-tool group list | wc -l)"
