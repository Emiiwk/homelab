# Tailscale · nodo `homelab`

Ver la documentacion completa en [`../../docs/02-red-y-tailscale.md`](../../docs/02-red-y-tailscale.md).

El nodo **se ejecuta en el anfitrion** (`tailscaled.service`), no en Docker.

## Arranque rapido

```bash
cd ../..
sudo tailscale up \
  --hostname=homelab \
  --advertise-routes=10.10.0.0/16,192.168.0.0/24 \
  --accept-dns
./infra/tailscale/scripts/setup-tailnet.sh
```

## Archivos

| Archivo | Funcion |
|---|---|
| `scripts/setup-tailnet.sh` | Verificacion del nodo y recordatorio de rutas |
| `config/acl.hujson` | Politica de acceso por grupos |
| `docker-compose.yml` | Alternativa en contenedor (no usada en este despliegue) |

## Recordatorio

Las rutas `10.10.0.0/16` y `192.168.0.0/24` **deben aprobarse** en
<https://login.tailscale.com/admin/machines>. El agente solo las anuncia.
