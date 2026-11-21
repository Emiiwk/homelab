# Checklist de capturas

Este directorio guarda la **evidencia real** del laboratorio. Una captura sin
contexto no demuestra nada: acompanala siempre del comando y de la fecha.

## Convencion de nombres

```text
NN-servicio-que-se-ve.png
```

Ejemplos: `01-ad-usuarios.png`, `04-glpi-tickets.png`.

## Formato de cada archivo

Cada imagen se acompana de un `.md` con el mismo nombre:

```markdown
# 01-ad-usuarios.png

- Fecha: 2026-11-21
- Servicio: Samba AD DC (homelab-ad)
- Comando: `docker exec homelab-ad wbinfo -u`
- Que demuestra: los 8 usuarios del dominio resueltos por winbind.
- Resultado: correcto
```

## Capturas completadas

| # | Archivo | Que capturar | Comando / pantalla |
|---|---|---|---|
| 01 | `01-ad-usuarios.png` | Listado de usuarios del dominio | `docker exec homelab-ad wbinfo -u` |
| 02 | `02-ad-grupos.png` | Grupos y pertenencia | `samba-tool group listmembers Soporte` |
| 03 | `03-ad-domain-info.png` | Info del dominio | `samba-tool domain info 127.0.0.1` |
| 04 | `04-glpi-tickets.png` | Los 12 tickets en la lista | GLPI > Asistencia > Tickets |
| 05 | `05-glpi-ldap.png` | Usuarios LDAP importados | GLPI > Administracion > Usuarios |
| 06 | `06-clonezilla-savedisk.png` | Clonezilla guardando imagen | `savedisk` verificado al 100% |
| 07 | `07-clonezilla-catalogo.png` | Catalogo de imagenes | `./infra/clonezilla/scripts/list-images.sh` |
| 08 | `08-tailscale-nodo.png` | Nodo `homelab` conectado | `tailscale status` (equivalente CLI a admin console) |
| 09 | `09-tailscale-rutas.png` | Rutas aprobadas | `tailscale status --json` (PrimaryRoutes) |
| 10 | `10-tailscale-ping.png` | Ping desde otro nodo | `tailscale ping homelab` desde `emi-desk` |
| 11 | `11-grafana-dashboard.png` | Dashboard del homelab | Grafana > Homelab Overview |
| 12 | `12-docker-ps.png` | Todos los contenedores arriba | `make status` |

## Como tomarlas sin filtrar secretos

- Herramienta recomendada: `gnome-screenshot`, `scrot`, `spectacle` o Flameshot.
- Oculta la barra de direcciones si contiene tokens.
- En Tailscale admin, difumina la IP `100.x.y.z` si lo prefieres (no es secreta,
  pero es buena costumbre).
- **Nunca** captures el `.env` ni la clave de Tailscale.

## Progreso

- [x] 01 AD usuarios
- [x] 02 AD grupos
- [x] 03 AD dominio
- [x] 04 GLPI tickets
- [x] 05 GLPI LDAP
- [x] 06 Clonezilla captura
- [x] 07 Clonezilla catalogo
- [x] 08 Tailscale nodo
- [x] 09 Tailscale rutas
- [x] 10 Tailscale ping
- [x] 11 Grafana
- [x] 12 Docker ps

## Regenerar las capturas de terminal

```bash
python3 scripts/capture-evidence.py
```

Las capturas web (04, 05 y 11) se generan con Selenium dentro del homelab
contra `127.0.0.1`; las de Tailscale (10) se generan desde `emi-desk`.
