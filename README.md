# homelab

[![CI](https://github.com/emiwk2006/homelab/actions/workflows/validate.yml/badge.svg)](https://github.com/emiwk2006/homelab/actions/workflows/validate.yml)
[![Docs](https://github.com/emiwk2006/homelab/actions/workflows/docs.yml/badge.svg)](https://github.com/emiwk2006/homelab/actions/workflows/docs.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Stack](https://img.shields.io/badge/stack-Docker%20%7C%20Samba%20AD%20%7C%20GLPI%20%7C%20Clonezilla%20%7C%20Tailscale-2f80ed)](docs/01-arquitectura.md)

> Laboratorio doméstico de infraestructura real: identidad, soporte, imágenes de equipo, red privada y observabilidad. Documentado para convertir «no tengo experiencia» en «mira lo que sé hacer».

**Nombre del nodo Tailscale:** `homelab`  
**Dominio del laboratorio:** `homelab.local`  
**Red interna Docker:** `10.10.0.0/16`

---

## Que hay aqui

Este repositorio no es un apunte de teoria. Es la **configuracion ejecutable** de un entorno que simula, a pequena escala, lo que hace un departamento de IT:

| Capacidad | Tecnologia | Que demuestra |
|---|---|---|
| Identidad y permisos | Samba AD DC (`dc01.homelab.local`) | Usuarios, grupos, OUs, GPO-equivalentes, Kerberos, DNS |
| Gestion de incidencias | GLPI + MariaDB + Redis | Tickets reales de prueba, categorias, SLA, flujo de trabajo |
| Imagenes de equipo | Clonezilla + repositorio NFS | Captura, restauracion y catalogo de imagenes |
| Red privada | Tailscale (nodo `homelab`) | Subnet router, MagicDNS, ACLs, acceso remoto seguro |
| Automatizacion | Bash + Make + Ansible | Despliegue repetible y reproducible |
| Seguridad | DevSecOps | Secretos fuera del repo, ACLs, hardening, backups, auditoria |
| Observabilidad | Prometheus + Grafana | Metricas, healthchecks, dashboards |

Cada servicio se puede levantar por separado o como un unico stack.

---

## Diagrama rapido

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

## Inicio rapido

```bash
# 1. Clonar
git clone https://github.com/emiwk2006/homelab.git
cd homelab

# 2. Copiar plantilla de secretos y rellenarla
cp .env.example .env
nano .env                       # TS_AUTHKEY, contrasenhas, etc.

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
| NFS imagenes | `10.10.0.30:/srv/clonezilla/images` |

> Los secretos **nunca** se suben. `.env` esta en `.gitignore`. Ver [SECURITY.md](SECURITY.md).

---

## Indice de documentacion

1. [Arquitectura y decisiones de diseno](docs/01-arquitectura.md)
2. [Red, Tailscale y DNS](docs/02-red-y-tailscale.md)
3. [Active Directory: usuarios y permisos](docs/03-active-directory.md)
4. [GLPI: tickets de prueba](docs/04-glpi.md)
5. [Clonezilla: imagenes de equipo](docs/05-clonezilla.md)
6. [Automatizacion](docs/06-automatizacion.md)
7. [Seguridad / DevSecOps](docs/07-seguridad-devsecops.md)
8. [Operaciones y backups](docs/08-operaciones-y-backups.md)
9. [Troubleshooting](docs/09-troubleshooting.md)
10. [Como explicar esto en una entrevista](docs/10-entrevista.md)
11. [Checklist de capturas](docs/screenshots/README.md)

---

## Evidencias (capturas)

Las capturas reales se guardan en [`docs/screenshots/`](docs/screenshots/). El
[checklist](docs/screenshots/README.md) indica exactamente que capturar en cada
servicio para que la evidencia sea verificable: comando ejecutado + resultado
visible + fecha.

| Evidencia | Estado |
|---|---|
| `wbinfo -u` mostrando los usuarios del dominio | Pendiente de captura |
| GLPI con los 12 tickets sembrados | Pendiente de captura |
| Clonezilla guardando una imagen | Pendiente de captura |
| Tailscale admin console con el nodo `homelab` | Pendiente de captura |
| Grafana con el dashboard del homelab | Pendiente de captura |

---

## Que se hacer (mapa de competencias)

Perfiles a los que apunta este laboratorio:

- **Soporte tecnico:** GLPI, tickets, diagnostico, documentacion de incidencias, imagenes de equipo.
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
├── docs/                      <- documentacion y capturas
├── infra/
│   ├── active-directory/      <- Dockerfile, provision, usuarios, grupos
│   ├── glpi/                  <- stack, semilla de tickets, cliente API
│   ├── clonezilla/            <- repo NFS, scripts de imagen
│   ├── tailscale/             <- subnet router, ACLs
│   └── monitoring/            <- Prometheus + Grafana
├── scripts/                   <- bootstrap, start, stop, status, backup
└── ansible/                   <- playbooks de configuracion
```

---

## Licencia

[MIT](LICENSE). Hecho con fines de aprendizaje. Cambia las contrasenhas de ejemplo antes de exponer cualquier servicio.
