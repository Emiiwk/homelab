#!/usr/bin/env bash
# Prepara el repositorio y lo publica en GitHub.
# Requiere: gh auth login (o GH_TOKEN) y permisos de creacion de repos.
set -Eeuo pipefail
source "$(dirname "$0")/lib/common.sh"

REPO_NAME="${REPO_NAME:-homelab}"
REPO_OWNER="${REPO_OWNER:-emiwk2006}"
VISIBILITY="${VISIBILITY:-public}"

info "1/5 Validando contenido ..."
"$ROOT_DIR/scripts/validate.sh"

info "2/5 Comprobando autenticacion de gh ..."
if ! gh auth status >/dev/null 2>&1; then
  die "GitHub CLI no autenticado. Ejecuta: gh auth login   (o exporta GH_TOKEN)"
fi
ok "gh autenticado como $(gh api user --jq .login)"

info "3/5 Inicializando git si hace falta ..."
if [[ ! -d "$ROOT_DIR/.git" ]]; then
  git -C "$ROOT_DIR" init -b main
  ok "Repo git inicializado en main"
else
  ok "Repo git ya existente"
fi

info "4/5 Comprobando secretos antes de anadir ..."
git -C "$ROOT_DIR" add -A
if git -C "$ROOT_DIR" diff --cached --name-only | grep -qx '.env'; then
  die ".env esta en el indice. Ejecuta: git reset .env"
fi

if git -C "$ROOT_DIR" diff --cached --quiet; then
  ok "No hay cambios nuevos que commitear"
else
  git -C "$ROOT_DIR" commit -m "docs: homelab completo - AD, GLPI, Clonezilla y Tailscale"
fi

info "5/5 Creando repo remoto y publicando ..."
if gh repo view "$REPO_OWNER/$REPO_NAME" >/dev/null 2>&1; then
  warn "El repo ya existe; se configura como remoto"
else
  gh repo create "$REPO_OWNER/$REPO_NAME" \
    --"$VISIBILITY" --source="$ROOT_DIR" --remote=origin \
    --description "Homelab: Active Directory, GLPI, Clonezilla y Tailscale - portfolio de infraestructura"
fi

git -C "$ROOT_DIR" remote add origin "https://github.com/$REPO_OWNER/$REPO_NAME.git" 2>/dev/null || true
git -C "$ROOT_DIR" branch -M main
git -C "$ROOT_DIR" push -u origin main

ok "Publicado en https://github.com/$REPO_OWNER/$REPO_NAME"
info "Activa GitHub Pages en Settings > Pages > Source: GitHub Actions"
