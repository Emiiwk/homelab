# homelab

[![CI](https://github.com/Emiiwk/homelab/actions/workflows/validate.yml/badge.svg)](https://github.com/Emiiwk/homelab/actions/workflows/validate.yml)
[![Docs](https://github.com/Emiiwk/homelab/actions/workflows/docs.yml/badge.svg)](https://github.com/Emiiwk/homelab/actions/workflows/docs.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Stack](https://img.shields.io/badge/stack-Docker%20%7C%20Samba%20AD%20%7C%20GLPI%20%7C%20Clonezilla%20%7C%20Tailscale-2f80ed)](docs/01-arquitectura.md)

> Laboratorio doméstico de infraestructura real: identidad, soporte, imágenes de equipo, red privada y observabilidad.

**Nombre del nodo Tailscale:** `homelab`  
**Dominio del laboratorio:** `homelab.local`  
**Red interna Docker:** `10.10.0.0/16`

---

## Qué hay aquí

Este repositorio es la **configuración ejecutable** de un entorno que simula, a pequena escala, lo que hace un departamento de IT:

| Capacidad | Tecnologia | Que demuestra |
|---|---|---|
| Identidad y permisos | Samba AD DC (`dc01.homelab.local`) | Usuarios, grupos, OUs, GPO-equivalentes, Kerberos, DNS |
| Gestion de incidencias | GLPI + MariaDB + Redis | Tickets reales de prueba, categorias, SLA, flujo de trabajo |
| Imagenes de equipo | Clonezilla + repositorio NFS | Captura, restauracion y catalogo de imágenes |
| Red privada | Tailscale (nodo `homelab`) | Subnet router, MagicDNS, ACLs, acceso remoto seguro |
| Automatizacion | Bash + Make + Ansible | Despliegue repetible y reproducible |
| Seguridad | DevSecOps | Secretos fuera del repo, ACLs, hardening, backups, auditoria |
| Observabilidad | Prometheus + Grafana | Metricas, healthchecks, dashboards |

Cada servicio se puede levantar por separado o como un único stack.

---

## Diagrama rápido

```text
                    Internet
                        |
                 [ Tailscale ]
              tailnet  node=homelab
                        |
        ┌───────────────┴────────────────┐
        │  Docker network 10.10.0.0/16    │
        │                                 │
        │  10.10.0.10  dc01   (Samba AD)  │
        │  10.10.0.20  glpi               │
        │  10.10.0.21  glpi-db (MariaDB)  │
        │  10.10.0.22  glpi-cache (Redis) │
        │  10.10.0.30  images  (NFS)      │
        │  10.10.0.40  prometheus         │
        │  10.10.0.41  grafana            │
        └─────────────────────────────────┘
```

Diagrama completo: [`docs/diagramas/homelab.svg`](docs/diagramas/homelab.svg)

---

## Inicio rápido

```bash
# 1. Clonar
git clone https://github.com/Emiiwk/homelab.git
cd homelab

# 2. Copiar plantilla de secretos y rellenarla
cp .env.example .env
nano .env                       # TS_AUTHKEY, contraseñas, etc.

# 3. Arrancar todo
make init
make up

# 4. Comprobar estado
make status
make health
```

Accesos una vez levantado (sustituye `TU-TAILNET` por tu tailnet real):

| Servicio | URL |
|---|---|
| GLPI | `http://glpi.homelab.TU-TAILNET.ts.net` |
| Grafana | `http://grafana.homelab.TU-TAILNET.ts.net` |
| Prometheus | `http://10.10.0.40:9090` |
| AD (LDAP/LDAPS) | `dc01.homelab.local:389 / :636` |
| NFS imágenes | `10.10.0.30:/srv/clonezilla/images` |

> Los secretos **nunca** se suben. `.env` esta en `.gitignore`. Ver [SECURITY.md](SECURITY.md).

---

## Indice de documentación

1. [Arquitectura y decisiones de diseno](docs/01-arquitectura.md)
2. [Red, Tailscale y DNS](docs/02-red-y-tailscale.md)
3. [Active Directory: usuarios y permisos](docs/03-active-directory.md)
4. [GLPI: tickets de prueba](docs/04-glpi.md)
5. [Clonezilla: imágenes de equipo](docs/05-clonezilla.md)
6. [Automatizacion](docs/06-automatizacion.md)
7. [Seguridad / DevSecOps](docs/07-seguridad-devsecops.md)
8. [Operaciones y backups](docs/08-operaciones-y-backups.md)
9. [Troubleshooting](docs/09-troubleshooting.md)
10. [Checklist de capturas](docs/screenshots/README.md)

---

## Evidencia (transcripción de comandos ejecutados)

Las 12 imágenes están en [`docs/screenshots/`](docs/screenshots/). Cada PNG es
una **transcripción renderizada de una salida real** (comando ejecutado por
`subprocess.run` o texto extraído de una pantalla local), acompañada de un
`.md` con fecha del sistema, servicio y resultado. No son capturas de terminal
hechas a mano y no existe un generador Selenium en el repo.

| # | Archivo | Qué se ve | Estado real |
|---|---|---|---|
| 01 | [`01-ad-usuarios.png`](docs/screenshots/01-ad-usuarios.png) | `wbinfo -u`: 11 cuentas (8 del CSV + `administrator`, `guest`, `krbtgt`) | Ejecutado |
| 02 | [`02-ad-grupos.png`](docs/screenshots/02-ad-grupos.png) | Miembros de `Soporte` | Ejecutado |
| 03 | [`03-ad-domain-info.png`](docs/screenshots/03-ad-domain-info.png) | `samba-tool domain info` | Ejecutado |
| 04 | [`04-glpi-tickets.png`](docs/screenshots/04-glpi-tickets.png) | GLPI: 8 tickets visibles en el filtro actual (12 en el CSV/API) | Ejecutado, filtro parcial |
| 05 | [`05-glpi-ldap.png`](docs/screenshots/05-glpi-ldap.png) | GLPI: usuarios importados por LDAP | Ejecutado |
| 06 | [`06-clonezilla-savedisk.png`](docs/screenshots/06-clonezilla-savedisk.png) | `savedisk` sobre disco loopback de 64 MiB | **PoC, no equipo real** |
| 07 | [`07-clonezilla-catalogo.png`](docs/screenshots/07-clonezilla-catalogo.png) | Catálogo con `labo-disk-01` (1,2 MB) | **PoC, no imagen de 40 GB** |
| 08 | [`08-tailscale-nodo.png`](docs/screenshots/08-tailscale-nodo.png) | `tailscale status` del nodo `homelab` | Ejecutado |
| 09 | [`09-tailscale-rutas.png`](docs/screenshots/09-tailscale-rutas.png) | `PrimaryRoutes` aprobadas | Ejecutado |
| 10 | [`10-tailscale-ping.png`](docs/screenshots/10-tailscale-ping.png) | `tailscale ping homelab` desde `emi-desk` | Ejecutado |
| 11 | [`11-grafana-dashboard.png`](docs/screenshots/11-grafana-dashboard.png) | Títulos de paneles del dashboard | Ejecutado; sin valores legibles |
| 12 | [`12-docker-ps.png`](docs/screenshots/12-docker-ps.png) | Contenedores arriba | Ejecutado |

[Ver checklist completo](docs/screenshots/README.md).

---

## Saber hacer (mapa de competencias)

Perfiles a los que apunta este laboratorio:

- **Soporte tecnico:** GLPI, tickets, diagnostico, documentación de incidencias, imágenes de equipo.
- **Administracion de sistemas:** Samba AD, usuarios/grupos/permisos, DNS, NFS, backups, shell.
- **Redes:** subnets, router de Tailscale, ACLs, resolucion de nombres, conectividad.
- **DevOps / DevSecOps (objetivo):** Docker Compose, Ansible, GitHub Actions, secretos, hardening, observabilidad, IaC.

Cada apartado de `docs/` incluye los **comandos reales**, la **salida esperada** y una
seccion de **«que fallo y como lo arregle»**, que es lo que realmente se pregunta en una entrevista.

---

## Estructura

```text
homelab/
├── README.md                  <- este archivo
├── Makefile                   <- atajos: make up / status / health / backup
├── .env.example               <- plantilla de secretos
├── docs/                      <- documentación y capturas
├── infra/
│   ├── active-directory/      <- Dockerfile, provision, usuarios, grupos
│   ├── glpi/                  <- stack, semilla de tickets, cliente API
│   ├── clonezilla/            <- repo NFS, scripts de imagen
│   ├── tailscale/             <- subnet router, ACLs
│   └── monitoring/            <- Prometheus + Grafana
├── scripts/                   <- bootstrap, start, stop, status, backup
└── ansible/                   <- playbooks de configuración
```

---

## Licencia

[MIT](LICENSE). Hecho con fines de aprendizaje. Cambia las contraseñas de ejemplo antes de exponer cualquier servicio.
