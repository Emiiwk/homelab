# GLPI

Ver la documentacion completa en [`../../docs/04-glpi.md`](../../docs/04-glpi.md).

## Arranque rapido

```bash
cd ../..
docker compose --env-file .env -f infra/glpi/docker-compose.yml up -d
```

## Archivos

| Archivo | Funcion |
|---|---|
| `docker-compose.yml` | GLPI + MariaDB + Redis |
| `data/tickets.csv` | 12 incidencias de prueba |
| `scripts/seed-tickets.sh` | Carga idempotente via API REST |
| `scripts/glpi-api.sh` | Cliente para listar/crear tickets |

## Cargar tickets

```bash
GLPI_URL=http://127.0.0.1:8080 GLPI_API_TOKEN=... ./infra/glpi/scripts/seed-tickets.sh
./infra/glpi/scripts/glpi-api.sh stats
```
