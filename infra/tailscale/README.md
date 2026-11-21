# Tailscale · nodo `homelab`

Ver la documentacion completa en [`../../docs/02-red-y-tailscale.md`](../../docs/02-red-y-tailscale.md).

## Arranque rapido

```bash
cd ../..
./infra/tailscale/scripts/setup-tailnet.sh
```

## Archivos

| Archivo | Funcion |
|---|---|
| `docker-compose.yml` | Contenedor tailscale con `network_mode: host` |
| `scripts/setup-tailnet.sh` | Arranque, verificacion y recordatorio de rutas |
| `config/acl.hujson` | Politica de acceso por grupos |

## Recordatorio

Las rutas `10.10.0.0/16` y `192.168.1.0/24` **deben aprobarse** en
<https://login.tailscale.com/admin/machines>. El contenedor solo las anuncia.
