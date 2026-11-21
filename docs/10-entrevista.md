# 10 - Como explicar este proyecto en una entrevista

## El problema que responde

> «No tengo experiencia profesional»

Respuesta corta:

> «No tengo experiencia en produccion, pero si he construido y operado un
> laboratorio completo: dominio con usuarios y permisos, helpdesk con tickets,
> imagenes de equipos, red privada con Tailscale, backups cifrados y
> automatizacion con IaC. Todo documentado y reproducible desde GitHub.»

## Elevator pitch (30 s)

> «Mi homelab es un entorno de infraestructura autocontenido. Monte un
> controlador de dominio Samba AD con OUs, grupos y permisos; un GLPI con doce
> incidencias realistas integradas con LDAP; un repositorio NFS para imagenes
> Clonezilla; y un nodo Tailscale llamado `homelab` que sirve de router de
> subnet sin abrir puertos. Todo orquestado con Docker Compose, Ansible y
> GitHub Actions, con secretos fuera del repo y backups cifrados con restic.
> El objetivo era poder demostrar competencias reales de soporte, sistemas y
> redes mientras camino a DevSecOps.»

## Por especialidad

### Soporte tecnico

Preguntas que puedes responder con evidencia:

- «¿Has gestionado incidencias?» -> 12 tickets con prioridad, SLA y flujo.
- «¿Como documentas?» -> `docs/04-glpi.md` + capturas + historial de comentarios.
- «¿Como despliegas un equipo?» -> imagenes Clonezilla catalogadas y RTO medido.
- «¿Como explicas un fallo a un usuario?» -> plantilla de incidente en doc 09.

### Administracion de sistemas

- Dominio, realm, DNS, Kerberos, LDAP, Samba.
- Usuarios, grupos, OUs, SIDs y permisos filesystem (`setfacl`).
- Servicios: NFS, MariaDB, Redis, Docker.
- Backups y restauracion verificada.

### Redes

- Subnets, gateways, IP forwarding, subnet router.
- MagicDNS y DNS split-horizon.
- ACLs y segmentacion por rol.
- WireGuard (Tailscale) frente a VPN tradicional.

### DevOps / DevSecOps

- IaC con Compose + Ansible idempotente.
- CI con validacion, lint y deteccion de secretos.
- Secretos, menor privilegio, cap_drop, hardening.
- Observabilidad con Prometheus/Grafana.
- Backups cifrados y threat model basico.

## Preguntas que te van a hacer (y respuesta corta)

**¿Por que Samba AD y no Windows Server?**
> Para aprender los protocolos subyacentes (LDAP, Kerberos, DNS) sin el peso de
> una VM Windows. `samba-tool` hace de interfaz y es auditable en un Dockerfile.

**¿Por que Tailscale y no WireGuard directo?**
> Tailscale resuelve NAT traversal, MagicDNS y ACLs sin abrir puertos. Debajo
> sigue siendo WireGuard, asi que el concepto esta ahi.

**¿Como sabes que un cambio no rompe algo?**
> `make test` valida localmente, el CI valida en cada push, y las playbooks son
> idempotentes. Ademas tengo backups verificados con `restic check`.

**¿Que fue lo mas dificil?**
> Entender que el DNS del contenedor tenia que apuntar al DC para que GLPI
> encontrara el dominio. Lo documente en el apartado de troubleshooting.

**¿Que harias diferente con mas tiempo?**
> Sustituir Compose por Podman/k8s, anadir GPO reales con Samba, integrar GLPI
> con SSO via SAML y meter Trivy + Cosign en el pipeline.

## Como mostrarlo

1. Dejar el repo publico y el README como portada.
2. Pinchar los badges de CI (que esten en verde).
3. Mostrar 4-5 capturas reales, no 30.
4. Llevar un `make help` y un `docker ps` abiertos en la entrevista.
5. Contar **un fallo real y su solucion**, no solo el exito.

## Plantilla de una respuesta STAR

```text
Situacion: Necesitaba que el helpdesk autenticara contra el dominio.
Tarea: Integrar GLPI con Active Directory sin exponer LDAP.
Accion: Configure un DN de servicio con permisos de solo lectura, apunte el
        DNS del contenedor al DC y probe con ldapsearch antes de tocar GLPI.
Resultado: Los 8 usuarios del dominio aparecen en GLPI y el enlace LDAP esta
           documentado con captura en docs/screenshots/.
```

## Enlaces para la web profesional

- Portada del proyecto: `https://github.com/Emiiwk/homelab`
- Documentacion: `https://Emiiwk.github.io/homelab/`
- Temas a destacar en la web: `Linux`, `Docker`, `Active Directory`, `GLPI`,
  `Tailscale`, `Bash`, `Ansible`, `DevSecOps`.
