# 01 - Arquitectura y decisiones de diseno

## Objetivo

Un unico equipo fisico (o VM) capaz de ejecutar, de forma simultanea y aislada:

1. Un **controlador de dominio** con identidad centralizada.
2. Un **servicio de helpdesk** con datos de prueba realistas.
3. Un **repositorio de imagenes** para despliegue de equipos.
4. Una **red privada** accesible desde fuera de casa sin abrir puertos.
5. **Observabilidad y backups** para operar con seguridad.

## Decisiones

| Decision | Alternativa descartada | Razon |
|---|---|---|
| Samba AD DC en Docker | Windows Server eval en VM | Menos RAM, arranca rapido, `samba-tool` es/scriptable y es identico en concepto a AD |
| GLPI oficial + MariaDB | OTRS / Zammad | GLPI es estandar en administracion de sistemas y soporte en Espana |
| Clonezilla Live + repo NFS | Fog / MDT | Clonezilla es ligero, gratuito y obliga a entender el proceso de imagen de verdad |
| Tailscale subnet router | WireGuard + port forwarding | Sin puertos abiertos, NAT traversal, MagicDNS y ACLs centralizadas |
| Docker Compose | Kubernetes | Para homelab, k8s anade complejidad sin valor de aprendizaje en esta fase |
| Ansible para configuracion | Scripts sueltos | Idempotencia y lenguaje declarativo, que es lo que se usa en DevOps |

!!! nota "Filosofia"
    Cada servicio se puede romper y reconstruir en minutos desde este repo. Eso es
    exactamente lo que se espera de infraestructura como codigo.

## Mapa de red

| Segmento | Rango | Uso |
|---|---|---|
| LAN fisica | `192.168.1.0/24` | Equipos del laboratorio, acceso desde casa |
| Docker `homelab_net` | `10.10.0.0/16` | Red interna de contenedores |
| Tailnet | `100.x.y.z/8` | Acceso remoto, nodo `homelab` |

IPs estaticas dentro de `homelab_net`:

| IP | Servicio | Puerto(s) |
|---|---|---|
| `10.10.0.2` | tailscale | 41641/udp |
| `10.10.0.10` | dc01 (Samba AD) | 53, 88, 389, 445, 636 |
| `10.10.0.20` | glpi | 80/8080 |
| `10.10.0.21` | glpi-db (MariaDB) | 3306 (solo interna) |
| `10.10.0.22` | glpi-cache (Redis) | 6379 (solo interna) |
| `10.10.0.30` | images (NFS) | 2049, 111 |
| `10.10.0.40` | prometheus | 9090 |
| `10.10.0.41` | grafana | 3000 |
| `10.10.0.42` | cadvisor | 8080 |
| `10.10.0.43` | node-exporter | 9100 |

## Arranque de dependencias

```text
              tailscale (homelab)
                     |
        +------------+-------------+
        |                          |
   dc01 (AD/DNS)              glpi ------> glpi-db
        |                      |
        |                  glpi-cache
        |
   images (NFS)  <---- Clonezilla Live
        |
   prometheus --> grafana
```

`dc01` actua como DNS autoritativo de `homelab.local`. Los demas contenedores
 usan `dns: 10.10.0.10` para resolver nombres internos.

## Requisitos estimados

- CPU: 4 nucleos
- RAM: 8 GB (12 GB recomendado si levantas Windows para las imagenes)
- Disco: 80 GB libres (40 GB para imagenes)
- SO anfitrion: Linux con Docker Engine 24+ y Compose v2
- Cuenta Tailscale gratuita

## Estado actual

- [x] Diseno y red definidos
- [x] Stacks de Docker Compose
- [x] Scripts de aprovisionamiento
- [x] Documentacion
- [ ] Capturas de evidencia (ver `docs/screenshots/`)
- [ ] Ejecucion en el equipo fisico
