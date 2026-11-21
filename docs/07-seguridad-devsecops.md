# 07 - Seguridad / DevSecOps

## Principios aplicados

1. **Secretos fuera del codigo.** Solo `.env.example` con marcadores.
2. **Menor privilegio.** Grupos AD y ACLs de Tailscale limitados por rol.
3. **Superficie minima.** MariaDB y Redis sin puertos publicados.
4. **Cifrado en transporte.** WireGuard (Tailscale); LDAP simple confinado a la red Docker.
5. **Cifrado en reposo.** Backups con restic (AES-256).
6. **Trazabilidad.** Logs centralizados y cada cambio versionado en Git.

## 1. Gestion de secretos

```bash
cp .env.example .env
chmod 600 .env
git check-ignore -v .env
# .gitignore:9:.env
```

Regla de oro: si un valor aparece en un `git log`, se considera **comprometido**
y hay que rotarlo, aunque se haya borrado despues.

Buscar secretos accidentalmente añadidos:

```bash
git log -p | grep -iE 'tskey-|password *= *[^C]'
gitleaks detect --source . -v
```

Rotacion realizada el 2026-11-21: la contraseña SSH/Sudo que aparecio en la
conversacion se cambio por una aleatoria de 24 caracteres. La nueva esta fuera
del repositorio, en `~/.homelab_ssh_password` (modo `0600`) de `emi-desk`.
El acceso al homelab sigue siendo por clave SSH; la contraseña solo se usa para
`sudo` en el propio homelab.

## 2. Hardening de contenedores

En `infra/docker-compose.yml`:

```yaml
services:
  glpi-db:
    read_only: true
    tmpfs:
      - /tmp
    cap_drop:
      - ALL
    cap_add:
      - CHOWN
      - SETUID
      - SETGID
    security_opt:
      - no-new-privileges:true
```

Redes:

- `homelab_net` es `internal: false` (necesita salida), pero **sin `ports:`**
  hacia el anfitrion en BD/cache/NFS.
- Solo el reverse proxy/Tailscale tiene Salida controlada.

## 3. Firewall del anfitrion (UFW)

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 41641/udp comment 'Tailscale'
sudo ufw allow from 192.168.0.0/24 to any port 2049 comment 'NFS LAN'
sudo ufw enable
sudo ufw status verbose
```

No se abre 80/443: todo el acceso remoto entra por Tailscale.

## 4. ACLs de Tailscale

Ver [`tailscale/config/acl.hujson`](../infra/tailscale/config/acl.hujson).
Politica por defecto **deny**, con excepciones explicitas por grupo.

## 5. Escaneo de imagenes en CI

Añadir al workflow de validacion:

```yaml
- name: Escanear imagenes con Trivy
  run: |
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
      aquasecurity/trivy:latest image glpi/glpi:10.0.x --exit-code 1 --severity HIGH,CRITICAL
```

## 6. Backups cifrados

```bash
# Inicializar repositorio (una vez)
export RESTIC_REPOSITORY=/home/emi/backups/restic
export RESTIC_PASSWORD_FILE=/home/emi/.restic-pass
restic init

# Backup
./scripts/backup.sh

# Verificar
restic check
restic snapshots
```

El repositorio puede apuntar a un bucket S3-compatible (Backblaze B2, MinIO)
con `restic -r s3:...` para cumplir **3-2-1**.

## 7. Matriz de amenazas (mini threat model)

| Amenaza | Control |
|---|---|
| Robo de credenciales AD | Password fuerte, rotacion, sin login interactivo en servicios |
| Exposicion de GLPI a Internet | Solo Tailscale, sin port forwarding |
| Fuga de secretos en Git | `.gitignore` + gitleaks en CI |
| Ransomware en un cliente | Imagenes limpias + backups inmutables |
| Escalada entre contenedores | cap_drop, no-new-privileges, redes separadas |
| Modificacion no autorizada | Commits firmados (recomendado) + logs |

## 8. Que demuestra a un entrevistador

- «¿Como gestionas secretos?» -> `.env`, rotacion, gitleaks.
- «¿Como limitas el acceso?» -> ACLs de Tailscale + grupos AD + UFW.
- «¿ Como sabes que no te has cargado algo?» -> backups cifrados + `restic check` + CI.
- «¿Como evitas que vuelva a pasar?» -> documentacion y playbooks idempotentes.
