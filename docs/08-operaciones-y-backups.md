# 08 - Operaciones y backups

## Tareas diarias (5 min)

```bash
make status
make health
docker stats --no-stream
tail -n 50 <(docker compose --env-file .env -f infra/docker-compose.yml logs)
```

## Tareas semanales

- Revisar tickets abiertos en GLPI y cerrar los resueltos.
- `samba-tool dbcheck --cross-ncs` en el DC.
- Comprobar espacio: `df -h`, `docker system df`.
- Rotar o caducar claves Tailscale temporales.
- **Pendiente:** configurar restic para poder ejecutar `restic snapshots` y
  `restic check` (hoy no hay repositorio ni `RESTIC_PASSWORD_FILE`).

## Tareas mensuales

- Restaurar **una imagen de prueba** en una VM desechable y medir el RTO.
- Restaurar **un backup de GLPI** en otro nombre de BD y verificar tickets.
- Actualizar imágenes base (`docker compose pull`, `make up`).
- Revisar `SECURITY.md` y rotar secretos.

## Backup: diseño vs realidad

`scripts/backup.sh` ya hace el volcado de MariaDB y llama a restic, pero
**hoy no está operativo**: `restic` no está instalado en el homelab y no existe
`backups/restic` ni `~/.restic-pass`. No hay snapshots reales.

| Dato | Método previsto | Estado |
|---|---|---|
| BD de GLPI | `mariadb-dump` -> restic | Script listo, sin ejecutar |
| Configuración AD | `samba-tool domain backup online` | Probado manualmente, sin automatizar |
| `infra/`, `docs/` y `.env` | `restic backup` | Sin repositorio configurado |
| Imágenes Clonezilla | `rsync` a disco externo | No implementado |
| Repositorio git | `git clone --mirror` | GitHub sí; disco externo no |

Para ponerlo en marcha:

```bash
# En emi-desk o en el homelab, según donde guardes el repo cifrado
openssl rand -base64 32 > ~/.restic-pass && chmod 600 ~/.restic-pass
export RESTIC_REPOSITORY=/ruta/backups/restic
./scripts/backup.sh
```

No pego una salida de `restic snapshots` porque todavía no existe.

## Restaurar GLPI

```bash
# 1. Parar aplicación
docker compose --env-file .env -f infra/glpi/docker-compose.yml stop glpi

# 2. Restaurar dump
restic restore latest --target /restore --include 'glpi-*.sql'
docker exec -i homelab-glpi-db mariadb -uglpi -p"$GLPI_DB_PASSWORD" glpi < /restore/glpi-*.sql

# 3. Arrancar y verificar
docker compose --env-file .env -f infra/glpi/docker-compose.yml start glpi
curl -s -o /dev/null -w '%{http_code}\n' http://10.10.0.20
# 200
```

## Restaurar el dominio

```bash
docker exec homelab-ad samba-tool domain backup online \
  --targetdir=/var/lib/samba/backup
# Copiar el .tar.bz2 fuera del contenedor con docker cp
```

Para un DC único, la restauracion completa implica recrear el contenedor y
restaurar `/var/lib/samba`. Documentar el procedimiento paso a paso es parte del
aprendizaje.

## Estrategia 3-2-1 (objetivo, no implementada)

- **3** copias (produccion + local + remota).
- **2** medios distintos (SSD local + B2/S3).
- **1** copia fuera de casa (cifrada con restic).

## Registro de cambios

Cada modificacion de infraestructura se hace en una rama y se documenta con:

```text
Que cambie
Por que
Como se verifica
Como se revierte
```

Ese habito es exactamente lo que se espera en un entorno DevOps/DevSecOps.
