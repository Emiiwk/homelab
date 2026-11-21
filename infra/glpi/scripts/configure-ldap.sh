#!/usr/bin/env bash
# Configura de forma idempotente el dominio LDAP y la API REST de GLPI.
# Los secretos se leen de .env (ignorado por Git); nunca se imprimen.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$ROOT"

log() { printf '[%s] [%s] %s\n' "$(date '+%F %T')" "$1" "$2"; }
die() { log ERROR "$1"; exit 1; }

if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  set -a; source .env; set +a
fi

: "${GLPI_DB_ROOT_PASSWORD:?Configura GLPI_DB_ROOT_PASSWORD en .env}"
: "${AD_ADMIN_PASSWORD:?Configura AD_ADMIN_PASSWORD en .env}"
: "${GLPI_API_TOKEN:?Configura GLPI_API_TOKEN en .env}"

GLPI_USER="${GLPI_USER:-glpi}"
GLPI_PASSWORD="${GLPI_PASSWORD:-glpi}"
BASE="${GLPI_LOCAL_URL:-http://127.0.0.1:8080}"
DOMAIN="${AD_DOMAIN:-homelab.local}"
AD_HOST="${AD_HOST:-10.10.0.10}"
BASE_DN="${AD_BASE_DN:-DC=homelab,DC=local}"
ROOT_DN="${AD_ROOT_DN:-CN=Administrator,CN=Users,DC=homelab,DC=local}"
FILTER='(&(objectClass=user)(!(objectClass=computer)))'

db_query() {
  docker exec -e DBPWD="$GLPI_DB_ROOT_PASSWORD" -e QUERY="$1" homelab-glpi-db \
    sh -c 'printf "%s\n" "$QUERY" | mariadb -N -u root -p"$DBPWD" glpi'
}

log INFO "Habilitando API REST y login por credenciales ..."
db_query "$(cat <<'SQL'
UPDATE glpi_configs SET value = 1 WHERE context = 'core' AND name IN ('enable_api','enable_api_login_credentials');
INSERT INTO glpi_configs (context, name, value)
  SELECT 'core', 'enable_api', 1 WHERE NOT EXISTS
    (SELECT 1 FROM glpi_configs WHERE context = 'core' AND name = 'enable_api');
INSERT INTO glpi_configs (context, name, value)
  SELECT 'core', 'enable_api_login_credentials', 1 WHERE NOT EXISTS
    (SELECT 1 FROM glpi_configs WHERE context = 'core' AND name = 'enable_api_login_credentials');
SQL
)" >/dev/null

log INFO "Abriendo sesion en la API de GLPI ..."
SESSION="$(printf 'login=%s&password=%s' "$GLPI_USER" "$GLPI_PASSWORD" \
  | curl -fsS -H "App-Token: $GLPI_API_TOKEN" --data-binary @- \
      "$BASE/apirest.php/initSession" | jq -r '.session_token // empty')"
[[ -n "$SESSION" ]] || die "No se pudo iniciar sesion en la API"

ID="$(db_query "SELECT id FROM glpi_authldaps WHERE name = '$DOMAIN' LIMIT 1;" | head -1)"

PAYLOAD_FILE="$(mktemp)"
trap 'rm -f "$PAYLOAD_FILE"' EXIT
chmod 600 "$PAYLOAD_FILE"

if [[ -n "$ID" ]]; then
  log INFO "Actualizando dominio LDAP existente (id=$ID) ..."
  jq -n \
    --argjson id "$ID" \
    --arg name "$DOMAIN" --arg host "$AD_HOST" --arg basedn "$BASE_DN" \
    --arg rootdn "$ROOT_DN" --arg pwd "$AD_ADMIN_PASSWORD" \
    --arg filter "$FILTER" \
    '{input:{
      id:$id, name:$name, host:$host, basedn:$basedn, rootdn:$rootdn,
      rootdn_passwd:$pwd, port:389, login_field:"samaccountname",
      condition:$filter, realname_field:"sn", firstname_field:"givenName",
      email1_field:"mail", is_active:1, is_default:1
    }}' > "$PAYLOAD_FILE"
  METHOD=PUT
else
  log INFO "Creando dominio LDAP $DOMAIN ..."
  jq -n \
    --arg name "$DOMAIN" --arg host "$AD_HOST" --arg basedn "$BASE_DN" \
    --arg rootdn "$ROOT_DN" --arg pwd "$AD_ADMIN_PASSWORD" \
    --arg filter "$FILTER" \
    '{input:{
      name:$name, host:$host, basedn:$basedn, rootdn:$rootdn,
      rootdn_passwd:$pwd, port:389, login_field:"samaccountname",
      condition:$filter, realname_field:"sn", firstname_field:"givenName",
      email1_field:"mail", is_active:1, is_default:1
    }}' > "$PAYLOAD_FILE"
  METHOD=POST
fi

curl -fsS -X "$METHOD" \
  -H "App-Token: $GLPI_API_TOKEN" \
  -H "Session-Token: $SESSION" \
  -H 'Content-Type: application/json' \
  --data-binary @"$PAYLOAD_FILE" \
  "$BASE/apirest.php/AuthLDAP" \
  | jq -c 'if type == "array" then .[0] else . end | {id: (.id // .input.id // null)}' || true
rm -f "$PAYLOAD_FILE"

# GLPI no siempre aplica estos campos por API; se fijan en BD (sin secretos).
log INFO "Normalizando filtro y atributo de login ..."
db_query "$(cat <<'SQL'
UPDATE glpi_authldaps
   SET login_field = 'samaccountname',
       `condition` = '(&(objectClass=user)(!(objectClass=computer)))'
 WHERE name = 'homelab.local';
SQL
)" >/dev/null

docker exec homelab-glpi php bin/console cache:clear >/dev/null 2>&1 || true

log INFO "Estado final del dominio LDAP:"
db_query "SELECT CONCAT(name,' | ',host,' | ',basedn,' | ',login_field) FROM glpi_authldaps WHERE name = '$DOMAIN';"
log INFO "Usuarios LDAP importados:"
db_query "SELECT COUNT(*) FROM glpi_users WHERE authtype = 3;"
log INFO "Listo. Importa usuarios en GLPI > Administracion > Usuarios > Enlace LDAP."
