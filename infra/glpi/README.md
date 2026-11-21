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
| `scripts/configure-ldap.sh` | Configura API REST y dominio LDAP de forma idempotente |

## Configurar LDAP y API

Tras el primer arranque, con `.env` rellenado:

```bash
./infra/glpi/scripts/configure-ldap.sh
```

El script crea/actualiza el dominio `homelab.local`, habilita la API REST y
fija el filtro y el atributo de login. Despues importa usuarios desde
**Administracion > Usuarios > Enlace a directorio LDAP > Importar nuevos usuarios**.

## Cargar tickets

```bash
GLPI_URL=http://127.0.0.1:8080 GLPI_API_TOKEN=... ./infra/glpi/scripts/seed-tickets.sh
./infra/glpi/scripts/glpi-api.sh stats
```
