#!/usr/bin/env bash
# Carga los tickets de prueba en GLPI usando su API REST.
# Idempotente: solo crea los tickets cuyo titulo no existe todavia.
set -Eeuo pipefail

GLPI_URL="${GLPI_URL:-http://127.0.0.1:8080}"
GLPI_API_TOKEN="${GLPI_API_TOKEN:?Configura GLPI_API_TOKEN en .env}"
CSV="${1:-/home/emi/homelab/infra/glpi/data/tickets.csv}"

log()  { printf '[%s] [%s] %s\n' "$(date '+%F %T')" "$1" "$2"; }
ok()   { log OK "$1"; }
warn() { log WARN "$1"; }
die()  { log ERROR "$1"; exit 1; }

command -v jq >/dev/null || die "Necesitas jq"
[[ -f "$CSV" ]] || die "No se encontro $CSV"

SESSION="$(curl -fsS -H "Authorization: Bearer $GLPI_API_TOKEN" \
  "$GLPI_URL/apirest.php/initSession" | jq -r '.session_token // empty')"
[[ -n "$SESSION" ]] || die "No se pudo iniciar sesion en la API de GLPI"
ok "Sesion API iniciada"

cleanup() {
  curl -fsS -H "Authorization: Bearer $GLPI_API_TOKEN" \
       -H "Session-Token: $SESSION" \
       "$GLPI_URL/apirest.php/killSession" >/dev/null 2>&1 || true
}
trap cleanup EXIT

api_get() {
  curl -fsS -H "Authorization: Bearer $GLPI_API_TOKEN" \
       -H "Session-Token: $SESSION" "$1"
}

api_post() {
  curl -fsS -X POST -H "Authorization: Bearer $GLPI_API_TOKEN" \
       -H "Session-Token: $SESSION" -H 'Content-Type: application/json' \
       -d "$2" "$1"
}

# Busca el id de un item por nombre (usuarios, categorias, etc.)
find_id() {
  local endpoint="$1" name="$2"
  api_get "$GLPI_URL/apirest.php/$endpoint?search-text=$(printf '%s' "$name" | jq -sRr @uri)&range=0-1" \
    | jq -r '.data[0].id // empty'
}

declare -A URGENCIA=( [1]=5 [2]=4 [3]=3 [4]=2 [5]=1 )
declare -A ESTADO=( [Nuevo]=1 [Asignado]=2 ["En curso"]=3 [Pendiente]=4 [Resuelto]=5 [Cerrado]=6 )

created=0
existing=0
failed=0

while IFS=',' read -r id titulo categoria prioridad estado tecnico origen sla descripcion seguimiento; do
  [[ -z "${id:-}" || "$id" == id || "$id" == \#* ]] && continue

  # Comprobar existencia por titulo (clave natural)
  found="$(api_get "$GLPI_URL/apirest.php/Ticket?search-text=$(printf '%s' "$titulo" | jq -sRr @uri)&range=0-1" \
           | jq -r '.data[0].id // empty')"
  if [[ -n "$found" ]]; then
    warn "$id ya existe (ticket #$found)"
    existing=$((existing + 1))
    continue
  fi

  cat_id="$(find_id ITILCategory "$categoria")"
  tech_id="$(find_id User "$tecnico")"
  urgency="${URGENCIA[$prioridad]:-3}"
  status="${ESTADO[$estado]:-1}"

  payload="$(jq -n \
    --arg name "$titulo" \
    --arg content "$descripcion" \
    --argjson urgency "$urgency" \
    --argjson status "$status" \
    --arg origin "$origen" \
    --arg sla "$sla" \
    --arg cat "${cat_id:-}" \
    --arg tech "${tech_id:-}" \
    '{input: {
        name: $name,
        content: ($content + " | Origen: " + $origin + " | SLA: " + $sla + "h"),
        urgency: $urgency,
        priority: $urgency,
        status: $status,
        itilcategories_id: (if $cat == "" then null else ($cat|tonumber) end),
        users_id_assign: (if $tech == "" then null else ($tech|tonumber) end)
     }}')"

  response="$(api_post "$GLPI_URL/apirest.php/Ticket" "$payload")"
  new_id="$(echo "$response" | jq -r '.id // empty')"

  if [[ -n "$new_id" ]]; then
    api_post "$GLPI_URL/apirest.php/Ticket/$new_id/TicketFollowup" \
      "$(jq -n --arg c "$seguimiento" '{input:{content:$c, is_private:false}}')" >/dev/null || true
    ok "$id creado como ticket #$new_id ($titulo)"
    created=$((created + 1))
  else
    warn "$id no se pudo crear: $response"
    failed=$((failed + 1))
  fi
done < "$CSV"

log INFO "Resumen: creados=$created, existentes=$existing, fallidos=$failed"
