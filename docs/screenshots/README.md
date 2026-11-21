# Transcripción de comandos ejecutados

Este directorio guarda la evidencia del laboratorio: **reconstrucciones
tipográficas de salidas reales**, no capturas de pantalla hechas a mano. Cada
PNG procede de un comando ejecutado de verdad (`subprocess.run`) o de texto
extraído de una pantalla. Cada imagen lleva un `.md` con fecha del sistema
(`date -Iseconds`), servicio, comando y resultado.

## Convención de nombres

```text
NN-servicio-que-se-ve.png
```

Ejemplos: `01-ad-usuarios.png`, `04-glpi-tickets.png`.

## Formato de cada archivo

```markdown
# 01-ad-usuarios.png

- Fecha: 2026-11-21T20:41:03+01:00
- Servicio: Samba AD DC (homelab-ad)
- Comando: `docker exec homelab-ad wbinfo -u`
- Qué hice: listé las cuentas resueltas por winbind (11: 8 del CSV + 3 internas)
- Resultado: correcto
```

## Inventario real

| # | Archivo | Qué se ve | Estado real |
|---|---|---|---|
| 01 | `01-ad-usuarios.png` | `wbinfo -u`: 11 cuentas (8 del CSV + `administrator`, `guest`, `krbtgt`) | Ejecutado |
| 02 | `02-ad-grupos.png` | Miembros de `Soporte` | Ejecutado |
| 03 | `03-ad-domain-info.png` | `samba-tool domain info` | Ejecutado |
| 04 | `04-glpi-tickets.png` | 8 tickets visibles en el filtro actual (12 en CSV/API) | Ejecutado, filtro parcial |
| 05 | `05-glpi-ldap.png` | Usuarios importados por LDAP | Ejecutado |
| 06 | `06-clonezilla-savedisk.png` | `savedisk` sobre disco loopback de 64 MiB | **PoC, no equipo real** |
| 07 | `07-clonezilla-catalogo.png` | Catálogo con `labo-disk-01` (1,2 MB) | **PoC, no imagen de 40 GB** |
| 08 | `08-tailscale-nodo.png` | `tailscale status` del nodo `homelab` | Ejecutado |
| 09 | `09-tailscale-rutas.png` | `PrimaryRoutes` aprobadas | Ejecutado |
| 10 | `10-tailscale-ping.png` | `tailscale ping homelab` desde `emi-desk` | Ejecutado |
| 11 | `11-grafana-dashboard.png` | Títulos de paneles; sin valores legibles | Ejecutado con datos parciales |
| 12 | `12-docker-ps.png` | Contenedores arriba | Ejecutado |

## Progreso

- [x] 01 AD usuarios
- [x] 02 AD grupos
- [x] 03 AD dominio
- [x] 04 GLPI tickets (8 visibles / 12 totales)
- [x] 05 GLPI LDAP
- [x] 06 Clonezilla PoC (loopback de 64 MiB)
- [x] 07 Clonezilla catálogo
- [x] 08 Tailscale nodo
- [x] 09 Tailscale rutas
- [x] 10 Tailscale ping
- [x] 11 Grafana (solo títulos)
- [x] 12 Docker ps

## Regenerar 06-10

```bash
HOMELAB_SSH_HOST=emi@192.168.0.19 python3 scripts/capture-evidence.py
```

El generador incluye `date -Iseconds` **dentro del comando**, para que la fecha
sea la del sistema que ejecuta la orden y no la del proceso que dibuja el PNG.
La IP del host y la ruta SSH se pueden cambiar con `HOMELAB_SSH_HOST`.
No imprime ni guarda `.env`, tokens ni contraseñas.

Las imágenes 01-05, 11 y 12 se generaron una vez a partir de salidas reales;
no hay un script Selenium en este repositorio. La frase anterior que lo
afirmaba era incorrecta y se ha retirado.

## Sin filtrar secretos

- **Nunca** incluyas el `.env`, claves `tskey-*` ni tokens en una transcripción.
- Si una salida contiene secretos, sanéala antes de renderizar.
- Las capturas 04, 05 y 11 son texto extraído de pantallas locales en
  `127.0.0.1`, sin barra de direcciones ni credenciales.
