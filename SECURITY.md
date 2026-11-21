# Politica de seguridad

## Alcance

Este repositorio contiene configuración de un laboratorio domestico. Aunque no
es produccion, **trata los secretos como si lo fuera**: el proposito del proyecto
es precisamente demostrar buenas practicas.

## Que NUNCA se sube

- `.env` (solo `.env.example` con valores `CAMBIAR_*`).
- Claves Tailscale (`tskey-auth-*`).
- Contraseñas de AD, MariaDB o Grafana (se entregan por `AD_PASS_*` en `.env`).
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
| `AD_ADMIN_PASSWORD` | 90 dias | `infra/active-directory/scripts/reset-password.sh administrador` |
| `AD_PASS_*` | 90 dias | `infra/active-directory/scripts/reset-password.sh <usuario>` |
| `GLPI_DB_PASSWORD` | 90 dias | Actualizar `.env` + `docker compose restart glpi-db glpi` |
| `GLPI_API_TOKEN` | 90 dias | Regenerar en GLPI > Configuracion > Tokens |

## Reportar un problema

Abre un issue privado en <https://github.com/Emiiwk/homelab/issues>. No publiques
PoCs con datos reales en issues públicos.

## Estado

- [x] Secretos fuera del repositorio (rotados y purgados del historial)
- [x] ACLs de Tailscale por grupo
- [ ] Red Docker aislada: hoy `internal: false`; hay puertos solo en localhost
- [ ] Backups cifrados con restic: pendiente de implementar
- [ ] Hardening de contenedores (`read_only`, `cap_drop`): pendiente
- [ ] Escaneo de imágenes con Trivy en CI: pendiente (`validate` solo hace ShellCheck, yamllint y `compose config`)
