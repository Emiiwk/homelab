# Politica de seguridad

## Alcance

Este repositorio contiene configuracion de un laboratorio domestico. Aunque no
es produccion, **trata los secretos como si lo fuera**: el proposito del proyecto
es precisamente demostrar buenas practicas.

## Que NUNCA se sube

- `.env` (solo `.env.example` con valores `CAMBIAR_*`).
- Claves Tailscale (`tskey-auth-*`).
- Contrasenhas de AD, MariaDB o Grafana.
- Certificados, claves privadas, tokens de API.
- Imagenes de discos o dumps de bases de datos reales.

## Antes de publicar

```bash
# 1. Comprobar que no hay secretos en el historial ni en el working tree
grep -rE 'tskey-|CAMBIAR_|PASSWORD=' --include='*.yml' --include='*.sh' --include='*.env' . || true

# 2. Verificar que .env esta ignorado
git check-ignore -v .env

# 3. Escanear con gitleaks (opcional pero recomendado)
docker run --rm -v "$PWD:/repo" zricethezav/gitleaks:latest detect --source /repo -v
```

## Rotacion

| Secreto | Caducidad recomendada | Como rotar |
|---|---|---|
| `TS_AUTHKEY` | 1 dia (usar clave de un solo uso) | Regenerar en Tailscale admin, actualizar `.env` |
| `AD_ADMIN_PASSWORD` | 90 dias | `scripts/ad-rotate-password.sh` |
| `GLPI_DB_PASSWORD` | 90 dias | Actualizar `.env` + `docker compose restart glpi-db glpi` |
| `GLPI_API_TOKEN` | 90 dias | Regenerar en GLPI > Configuracion > Tokens |

## Reportar un problema

Abre un issue privado o escribe a `emiwk2006@gmail.com`. No publiques PoCs con
datos reales en issues publicos.

## Estado

- [x] Secretos fuera del repositorio
- [x] ACLs de Tailscale por grupo
- [x] Red Docker aislada (`internal: true` donde aplica)
- [x] Backups cifrados con restic
- [ ] Hardening de contenedores (read-only rootfs, cap-drop) — en progreso
- [ ] Escaneo de imagenes con Trivy en CI — en progreso
