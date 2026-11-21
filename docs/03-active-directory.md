# 03 - Active Directory: usuarios y permisos

## Que se monta

Un **Samba AD DC** con las funciones de un controlador de dominio Windows:

- Dominio: `homelab.local` (REALM `HOMELAB.LOCAL`)
- NetBIOS: `HOMELAB`
- Hostname: `dc01.homelab.local`
- IP: `10.10.0.10`
- DNS integrado, Kerberos, LDAP/LDAPS, SMB para sysvol

Se construye una imagen propia (ver `infra/active-directory/Dockerfile`) en lugar
de usar una imagen de terceros para **ver exactamente que paquetes y que comandos**
se ejecutan. Eso es lo que se quiere demostrar.

## Estructura organizativa

```text
homelab.local
└── Homelab
    ├── Usuarios
    │   ├── TI
    │   ├── Operaciones
    │   └── Invitados
    ├── Equipos
    │   ├── Servidores
    │   └── Clientes
    └── Grupos
```

## Grupos y permisos

| Grupo | Miembros | Permisos |
|---|---|---|
| `Domain Admins` | `administrador` | Control total del dominio |
| `TI-Admin` | `soporte1`, `svc_glpi` | Gestion de equipos y tickets, lectura de usuarios |
| `Soporte` | `soporte1`, `soporte2` | Lectura de usuarios, reset de password de `Operaciones` |
| `Usuarios` | `usuario1`, `usuario2` | Acceso a recursos compartidos de su OU |
| `Invitados` | `invitado` | Solo GLPI, sin acceso a compartidos |

Los permisos sobre recursos se aplican con `setfacl` sobre el volumen NFS/SMB,
usando SIDs resueltos con `wbinfo --name-to-sid`. Asi se ve el flujo completo:
**usuario -> grupo -> SID -> permiso filesystem**.

## 1. Aprovisionar el dominio

```bash
cp .env.example .env
# Rellenar AD_ADMIN_PASSWORD
make init
docker compose --env-file .env -f infra/docker-compose.yml up -d --build ad
docker compose --env-file .env -f infra/docker-compose.yml logs -f ad
```

El `entrypoint` ejecuta una sola vez:

```bash
samba-tool domain provision \
  --server-role=dc \
  --realm="$REALM" \
  --domain=HOMELAB \
  --adminpass="$AD_ADMIN_PASSWORD" \
  --dns-backend=SAMBA_INTERNAL \
  --function-level=2008_R2
```

Si ya existe `/var/lib/samba` con el dominio, se omite (idempotente).

## 2. Crear OUs, grupos y usuarios

Los datos estan en `config/groups.csv` y `config/users.csv`. El script es
idempotente: comprueba antes de crear.

```bash
docker exec -it homelab-ad bash /opt/ad/scripts/provision-ad.sh
docker exec -it homelab-ad bash /opt/ad/scripts/create-users.sh
```

Salida esperada (abreviada):

```text
[OK] OU creada: OU=Usuarios,OU=Homelab,DC=homelab,DC=local
[OK] Grupo creado: Soporte
[OK] Usuario creado: soporte1
[OK] Usuario aniadido a Soporte
[OK] Permisos aplicados en /srv/shares/soporte
Resumen: 8 usuarios, 5 grupos, 6 OUs
```

## 3. Verificar desde el anfitrion

```bash
docker exec homelab-ad wbinfo -u
# HOMELAB\administrador
# HOMELAB\soporte1
# HOMELAB\soporte2
# HOMELAB\usuario1
# HOMELAB\usuario2
# HOMELAB\invitado
# HOMELAB\svc_glpi
# HOMELAB\svc_backup

docker exec homelab-ad wbinfo -g
# HOMELAB\domain admins
# HOMELAB\ti-admin
# HOMELAB\soporte
# HOMELAB\usuarios
# HOMELAB\invitados

docker exec homelab-ad samba-tool domain info 127.0.0.1
docker exec homelab-ad samba-tool drs showrepl
docker exec homelab-ad samba-tool dbcheck --cross-ncs
```

Kerberos:

```bash
docker exec homelab-ad kinit administrador@HOMELAB.LOCAL
docker exec homelab-ad klist
```

LDAP con `ldapsearch` (instalar `ldap-utils` en el anfitrion):

```bash
ldapsearch -x -H ldap://10.10.0.10:389 \
  -D 'CN=administrador,CN=Users,DC=homelab,DC=local' \
  -w "$AD_ADMIN_PASSWORD" \
  -b 'DC=homelab,DC=local' '(objectClass=user)' cn sAMAccountName
```

## 4. Cambiar la password de un usuario

```bash
docker exec -it homelab-ad samba-tool user setpassword usuario1
```

o, de forma no interactiva:

```bash
docker exec homelab-ad samba-tool user setpassword usuario1 \
  --newpassword='NuevaPasswordSegura123!'
```

## 5. Desbloquear una cuenta

```bash
docker exec homelab-ad samba-tool user unlock soporte1
```

## 6. Que demuestra esto

- Entender el modelo de **dominio, realm, NetBIOS y DNS**.
- Saber crear **OUs y grupos** y aplicar el principio de **menor privilegio**.
- Verificar con **wbinfo / samba-tool / ldapsearch / Kerberos**.
- Tener un **identity provider** real para integrar GLPI (LDAP) mas adelante.

## Fallos tipicos

| Sintoma | Causa | Solucion |
|---|---|---|
| `provision failed: DNS domain must not be single label` | Falta el punto en `homelab.local` | Usar `--realm=HOMELAB.LOCAL` |
| `wbinfo -u` devuelve vacio | winbind no arranco | `docker logs homelab-ad`, revisar `/etc/samba/smb.conf` |
| No resuelve `dc01.homelab.local` | DNS del cliente apunta otro sitio | Anadir nameserver en Tailscale o `/etc/resolv.conf` |
| `kinit: Clock skew too great` | Reloj desincronizado | `timedatectl set-ntp true` en anfitrion y contenedor |
