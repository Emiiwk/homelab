# 09 - Troubleshooting

Metodo: **observar -> reproducir -> aislar -> documentar**. Nada de reiniciar
sin saber por que.

## 1. Contenedor que no arranca

```bash
docker compose --env-file .env -f infra/docker-compose.yml ps -a
docker logs --tail 200 homelab-ad
docker inspect homelab-ad | jq '.[0].State'
```

| `State.Status` | Significado |
|---|---|
| `restarting` | El proceso principal muere; mirar logs |
| `exited` con code 0 | Entrypoint termino antes de tiempo |
| `created` | Falto `up` o hay error de dependencias |

## 2. DNS roto

Sintoma: `curl http://glpi` falla pero `curl http://10.10.0.20` funciona.

```bash
docker exec homelab-glpi getent hosts dc01.homelab.local
docker exec homelab-glpi cat /etc/resolv.conf
dig @10.10.0.10 glpi.homelab.local A
```

Solucion: asegurar `dns: 10.10.0.10` en el `docker-compose.yml` del servicio.

## 3. No conecta LDAP desde GLPI

```bash
# Desde el contenedor de GLPI
nc -zv 10.10.0.10 389
ldapsearch -x -H ldap://10.10.0.10 -b '' -s base namingcontexts
```

Si `nc` falla: revisar red `homelab_net` y que Samba este escuchando:

```bash
docker exec homelab-ad ss -lntp | grep -E ':389|:636'
```

## 4. Tailscale: nodo conectado pero sin rutas

```bash
tailscale status
tailscale debug netmap | jq '.Peer[] | select(.HostName=="homelab") | .PrimaryRoutes'
sudo sysctl net.ipv4.ip_forward
```

Si `ip_forward = 0`, volver a aplicar `sysctl` (ver doc 02).

## 5. MariaDB rechaza conexiones

```bash
docker exec homelab-glpi-db mariadb-admin ping
docker logs homelab-glpi-db | grep -i 'access denied'
```

Comprobar que `GLPI_DB_PASSWORD` en `.env` coincide con la BD. Si no, recrear:

```bash
docker compose --env-file .env -f infra/glpi/docker-compose.yml down -v
docker compose --env-file .env -f infra/glpi/docker-compose.yml up -d
```

!!! peligro "down -v borra datos"
    Solo hacerlo si no hay datos que conservar o si tienes backup verificado.

## 6. NFS: permission denied

```bash
docker logs homelab-images
sudo mount -t nfs -o vers=4,addr=10.10.0.30 10.10.0.30:/ /mnt/nfs-test
docker exec homelab-images exportfs -v
```

El repositorio sirve **solo NFSv4** (`fsid=0`); `showmount` no lista exportes.
Si el contenedor entra en `Restarting`, revisa el log: `rpc.statd` se desactivo
con `NFS_DISABLE_VERSION_3=1` por falta de RAM en el host.

## 7. Clonezilla no ve espacio

```bash
docker exec homelab-images df -h /srv/clonezilla/images
docker system df -v
```

Limpiar imagenes antiguas con cuidado:

```bash
./infra/clonezilla/scripts/list-images.sh
./infra/clonezilla/scripts/delete-image.sh ubuntu-lab-old
```

## 8. GLPI lento

```bash
docker stats --no-stream
docker exec homelab-glpi-db mariadb -e 'SHOW PROCESSLIST;'
docker exec homelab-glpi redis-cli info stats | head
```

Causas habituales: cache Redis caido, indice faltante en `glpi_tickets`, o
demasiados tickets de prueba (este lab solo tiene 12).

## 9. Reloj desincronizado (Kerberos)

```bash
timedatectl status
docker exec homelab-ad date
```

Sintoma: `kinit: Clock skew too great`. Solucion: `timedatectl set-ntp true`.

## 10. Plantilla para documentar un incidente

Copiar esto en un issue o en la doc:

```markdown
### Sintoma
¿Que se observo exactamente?

### Comandos ejecutados
```bash
...
```

### Salida relevante
```text
...
```

### Causa raiz
...

### Solucion aplicada
...

### Como evitar que vuelva a pasar
...
```

Esa plantilla es oro en una entrevista: demuestra metodo, no solo memorizacion.
