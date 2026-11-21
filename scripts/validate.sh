#!/usr/bin/env bash
# Validaciones locales antes de hacer commit / antes del CI.
set -Eeuo pipefail
source "$(dirname "$0")/lib/common.sh"

failures=0

report_fail() { warn "FALLO: $1"; failures=$((failures + 1)); }

info "1/5 Validando YAML ..."
if command -v yamllint >/dev/null; then
  yamllint -d relaxed "$ROOT_DIR/infra" "$ROOT_DIR/.github" "$ROOT_DIR/ansible" || report_fail "yamllint"
else
  python3 - <<'PY' || report_fail "yaml parse"
import pathlib, sys
try:
    import yaml
except ImportError:
    print("PyYAML no instalado; se omite validacion YAML")
    sys.exit(0)
bad = False
for p in pathlib.Path('.').rglob('*.y*ml'):
    try:
        list(yaml.safe_load_all(p.read_text()))
    except Exception as e:
        print(f"{p}: {e}")
        bad = True
sys.exit(1 if bad else 0)
PY
fi

info "2/5 Comprobando sintaxis de scripts ..."
while IFS= read -r script; do
  bash -n "$script" || report_fail "bash -n $script"
done < <(find "$ROOT_DIR" -type f -name '*.sh' -not -path '*/backups/*')

if command -v shellcheck >/dev/null; then
  mapfile -t sh_files < <(find "$ROOT_DIR" -type f -name '*.sh')
  shellcheck -x "${sh_files[@]}" || report_fail "shellcheck"
fi

info "3/5 Buscando secretos ..."
if git -C "$ROOT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
  if git -C "$ROOT_DIR" grep -nE 'tskey-auth-[A-Za-z0-9]{10,}' -- . ':!.env.example' >/dev/null 2>&1; then
    report_fail "posible clave Tailscale en el repositorio"
  fi
fi

info "4/5 Verificando .gitignore ..."
git -C "$ROOT_DIR" check-ignore -q .env || report_fail ".env no esta ignorado"

info "5/5 Comprobando docs referenciadas ..."
for file in "$ROOT_DIR/README.md" "$ROOT_DIR"/docs/*.md; do
  [[ -f "$file" ]] || continue
  dir="$(dirname "$file")"
  while IFS= read -r link; do
    target="$(printf '%s' "$link" | sed -E 's/.*\]\(([^)]+)\).*/\1/')"
    [[ "$target" =~ ^(http|mailto:) ]] && continue
    target="${target%%#*}"
    [[ -z "$target" ]] && continue
    [[ -e "$dir/$target" ]] || warn "Link roto en ${file#$ROOT_DIR/}: $link"
  done < <(grep -oE '\[[^]]+\]\([^)]+\)' "$file" 2>/dev/null || true)
done

echo
if (( failures == 0 )); then
  ok "VALIDACION OK"
else
  die "VALIDACION FALLIDA: $failures errores"
fi
