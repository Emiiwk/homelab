# 02 - Red y Tailscale

## Que es Tailscale aqui

Tailscale crea una red mesh cifrada (WireGuard) entre el equipo que llevas
encima y el homelab. El nodo del laboratorio se llama **`homelab`** y actua como
**subnet router**: anuncia las redes `10.10.0.0/16` (Docker) y `192.168.0.0/24`
(LAN) al resto de la tailnet.

El agente se instala **en el anfitrion** (`tailscaled.service`), no en un
contenedor, para poder reenviar trafico entre la tailnet, la red Docker y la LAN.

Ventajas frente a abrir puertos en el router:

- No hay puertos expuestos a Internet.
- No necesitas IP publica ni DDNS.
- MagicDNS: `homelab.tu-tailnet.ts.net` resuelve siempre.
- ACLs centralizadas por usuario/grupo.

## 1. Instalar el agente en el anfitrion

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo systemctl enable --now tailscaled
```

## 2. Iniciar sesion y anunciar las rutas

El login es interactivo (se abre un navegador). Ejecutarlo **en el homelab**:

```bash
sudo tailscale up \
  --hostname=homelab \
  --advertise-routes=10.10.0.0/16,192.168.0.0/24 \
  --accept-dns
```

No hace falta `TS_AUTHKEY` en `.env`: la sesion queda guardada en
`/var/lib/tailscale/tailscaled.state`. El valor `TS_AUTHKEY` de `.env.example`
es solo una referencia si se decide automatizar el alta con una clave.

Salida esperada:

```text
Success. Your machine is now connected to tailnet 'tu-tailnet.ts.net'.
```

Verificacion:

```bash
tailscale status
tailscale ip -4
# 100.x.y.z
```

## 3. Aprobar las rutas anunciadas

En <https://login.tailscale.com/admin/machines>:

1. Localizar el equipo `homelab`.
2. Pulsar los tres puntos > **Edit route settings**.
3. Marcar `10.10.0.0/16` y `192.168.0.0/24`.
4. Pulsar **Save**.

Verificacion desde otro equipo de la tailnet:

```bash
tailscale status | grep homelab
# 100.x.y.z  homelab  tu-tailnet.ts.net  linux  -  offline; active

ping 10.10.0.10
# 64 bytes from 10.10.0.10: icmp_seq=1 ttl=64 time=... ms
```

## 4. Habilitar IP forwarding en el anfitrion

Necesario para que el nodo reenvie paquetes entre la tailnet, la red Docker y
la LAN. Ya aplicado en `/etc/sysctl.d/99-tailscale.conf`:

```bash
printf 'net.ipv4.ip_forward = 1\nnet.ipv6.conf.all.forwarding = 1\n' \
  | sudo tee /etc/sysctl.d/99-tailscale.conf
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
| `group:soporte` | GLPI, Grafana, AD (LDAP/DNS) e imágenes (NFS) |
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
| El nodo aparece `offline` | `tailscaled` caido o sesion caducada | `sudo systemctl restart tailscaled && sudo tailscale up ...` |
| No llega ping a `10.10.0.10` | Rutas no aprobadas | Aprobarlas en admin console |
| Llega ping pero no DNS | Nameserver no configurado | Anadir `10.10.0.10` para `homelab.local` |
| `tailscale up` dice `could not authenticate` | Sesion caducada | Repetir el login interactivo |
