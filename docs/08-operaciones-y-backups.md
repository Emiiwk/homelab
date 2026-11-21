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
- `restic snapshots` y `restic check`.
- `samba-tool dbcheck --cross-ncs` en el DC.
- Comprobar espacio: `df -h`, `docker system df`.
- Rotar o caducar claves Tailscale temporales.

## Tareas mensuales

- Restaurar **una imagen de prueba** en una VM desechable y medir el RTO.
- Restaurar **un backup de GLPI** en otro nombre de BD y verificar tickets.
- Actualizar imagenes base (`docker compose pull`, `make up`).
- Revisar `SECURITY.md` y rotar secretos.

## Backup: que se guarda

| Dato | Metodo | Destino |
|---|---|---|
| Volumenes Docker | `restic backup` sobre `/var/lib/docker/volumes` | `backups/restic` |
| BD de GLPI | `mariadb-dump` -> restic | `backups/restic` |
| Configuracion AD | `samba-tool domain backup online` | `backups/restic` |
| Imagenes Clonezilla | `rsync` incremental | Disco externo / B2 |
| Repositorio git | `git clone --mirror` | GitHub + disco externo |

## Ejecutar un backup

```bash
./scripts/backup.sh
# [INFO] Parando GLPI para backup consistente ...
# [INFO] Volcando MariaDB ...
# [INFO] Backing up 3.4 GiB ...
# [OK] Snapshot 8f3a1c2b guardado
# [OK] restic check: no errors
```

## Restaurar GLPI

```bash
# 1. Parar aplicacion
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

Para un DC unico, la restauracion completa implica recrear el contenedor y
restaurar `/var/lib/samba`. Documentar el procedimiento paso a paso es parte del
aprendizaje.

## Estrategia 3-2-1

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
