# Active Directory (Samba AD DC)

Ver la documentacion completa en [`../../docs/03-active-directory.md`](../../docs/03-active-directory.md).

## Arranque rapido

```bash
cd ../..
cp .env.example .env          # rellenar AD_ADMIN_PASSWORD
docker compose -f infra/active-directory/docker-compose.yml --env-file .env up -d --build
docker logs -f homelab-ad
```

## Archivos

| Archivo | Funcion |
|---|---|
| `Dockerfile` | Imagen Debian + Samba AD + herramientas |
| `scripts/entrypoint.sh` | Aprovisiona si hace falta y arranca Samba |
| `scripts/provision-ad.sh` | Dominio, OUs, grupos y ACLs |
| `scripts/create-users.sh` | Usuarios desde `users.csv` |
| `scripts/reset-password.sh` | Reset + desbloqueo + auditoria |
| `config/users.csv` | 8 usuarios de laboratorio |
| `config/groups.csv` | 5 grupos |
| `config/shares.conf` | Compartidos SMB |
| `config/smb.conf` | Referencia del resultado final |

## Verificacion

```bash
docker exec homelab-ad wbinfo -u
docker exec homelab-ad wbinfo -g
docker exec homelab-ad samba-tool domain info 127.0.0.1
docker exec homelab-ad samba-tool dbcheck --cross-ncs
```
