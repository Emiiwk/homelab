# Clonezilla

Ver la documentacion completa en [`../../docs/05-clonezilla.md`](../../docs/05-clonezilla.md).

## Arranque rapido

```bash
cd ../..
docker compose --env-file .env -f infra/clonezilla/docker-compose.yml up -d
showmount -e 10.10.0.30
```

## Scripts

| Script | Funcion |
|---|---|
| `scripts/common.sh` | Funciones y ruta del repositorio |
| `scripts/create-image.sh` | Capturar imagen + metadata + checksum |
| `scripts/restore-image.sh` | Restaurar con doble confirmacion |
| `scripts/list-images.sh` | Catalogo de imagenes |
| `scripts/delete-image.sh` | Borrado seguro |

## Nota sobre IMAGE_ROOT

Los scripts asumen el volumen Docker en
`/var/lib/docker/volumes/homelab_images-data/_data`. Si usas otro driver o
montas el NFS directamente, define:

```bash
export IMAGE_ROOT=/srv/clonezilla/images
```
