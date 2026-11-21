# 02 - Red y Tailscale

## Que es Tailscale aqui

Tailscale crea una red mesh cifrada (WireGuard) entre el equipo que llevas
encima y el homelab. El nodo del laboratorio se llama **`homelab`** y actua como
**subnet router**: anuncia las redes `10.10.0.0/16` (Docker) y `192.168.1.0/24`
(LAN) al resto de la tailnet.

Ventajas frente a abrir puertos en el router:

- No hay puertos expuestos a Internet.
- No necesitas IP publica ni DDNS.
- MagicDNS: `homelab.tu-tailnet.ts.net` resuelve siempre.
- ACLs centralizadas por usuario/grupo.

## 1. Crear la clave de autenticacion

1. Entrar en <https://login.tailscale.com/admin/settings/keys>.
2. Generar clave con:
   - **Reusable:** no (usar una sola vez).
   - **Ephemeral:** no (queremos que el nodo persista).
   - **Expiration:** 1 dia.
   - **Advertise routes:** las que sean, o se pasan por variable.
3. Copiar el valor en `.env`:

```bash
TS_AUTHKEY=tskey-auth-<TU_CLAVE_AQUI>
TS_HOSTNAME=homelab
TS_ROUTES=10.10.0.0/16,192.168.1.0/24
TAILNET=tu-tailnet.ts.net
```

!!! peligro "Secreto"
    Esa clave da acceso a tu tailnet. No la pegues en un issue, un commit ni una captura.

## 2. Levantar el nodo

```bash
docker compose --env-file .env -f infra/tailscale/docker-compose.yml up -d
docker compose --env-file .env -f infra/tailscale/docker-compose.yml logs -f tailscale
```

Salida esperada:

```text
homelab  | 2026/11/21 10:00:00 auth loop: done; state=Authenticated
homelab  | 2026/11/21 10:00:01 Health check: healthy
```

## 3. Aprobar las rutas anunciadas

En <https://login.tailscale.com/admin/machines>:

1. Localizar el equipo `homelab`.
2. Pulsar los tres puntos > **Edit route settings**.
3. Marcar `10.10.0.0/16` y `192.168.1.0/24`.
4. Pulsar **Save**.

Verificacion desde otro equipo de la tailnet:

```bash
tailscale status | grep homelab
# 100.x.y.z  homelab  tu-tailnet.ts.net  linux  -  offline; active

ping 10.10.0.10
# 64 bytes from 10.10.0.10: icmp_seq=1 ttl=64 time=... ms
```

## 4. Habilitar IP forwarding en el anfitrion

Necesario para que el contenedor reenvie paquetes entre la tailnet y la LAN:

```bash
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl -w net.ipv6.conf.all.forwarding=1

echo 'net.ipv4.ip_forward = 1' | sudo tee /etc/sysctl.d/99-homelab.conf
echo 'net.ipv6.conf.all.forwarding = 1' | sudo tee -a /etc/sysctl.d/99-homelab.conf
sudo sysctl --system
```

## 5. DNS

Con MagicDNS activado, añade un **nameserver** en Tailscale admin para
`homelab.local` apuntando a `10.10.0.10` (el DC). Asi `dc01.homelab.local`
resuelve desde cualquier equipo de la tailnet.

Alternativa sin depender del DNS de Tailscale: usar el archivo `hosts` local
o `tailscale up --accept-dns=true`.

## 6. ACLs

Las reglas estan en [`../infra/tailscale/config/acl.hujson`](../infra/tailscale/config/acl.hujson).
El modelo es:

| Grupo | Acceso |
|---|---|
| `group:admins` | Todo (`*:*`) |
| `group:soporte` | GLPI, Grafana, AD (LDAP/DNS) e imagenes (NFS) |
| `group:usuarios` | Solo GLPI |
| `tag:homelab` | Salida a Internet via nodo, sin acceso a la LAN fisica |

Pegar el contenido en <https://login.tailscale.com/admin/acls/file> y pulsar
**Save**. Tailscale valida la sintaxis HuJSON antes de aplicar.

## 7. Comprobaciones

```bash
# Desde cualquier nodo de la tailnet
tailscale ping homelab
tailscale status --json | jq '.Peer[] | select(.HostName=="homelab") | {HostName, Online, OS}'

# Comprobar que el router anuncia rutas
tailscale debug netmap | jq '.Peer[] | select(.HostName=="homelab") | .PrimaryRoutes'
```

## Fallos tipicos

| Sintoma | Causa | Solucion |
|---|---|---|
| El nodo aparece `offline` | El contenedor no arranco | `docker logs homelab-tailscale` |
| No llega ping a `10.10.0.10` | Rutas no aprobadas | Aprobarlas en admin console |
| Llega ping pero no DNS | Nameserver no configurado | Anadir `10.10.0.10` para `homelab.local` |
| `tailscale up` dice `could not authenticate` | Clave caducada | Generar otra y actualizar `.env` |
