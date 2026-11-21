# Indice de documentación

| # | Documento | Contenido |
|---|---|---|
| 00 | [README](../README.md) | Vision general y arranque rápido |
| 01 | [Arquitectura](01-arquitectura.md) | Diseno, red, decisiones y por que |
| 02 | [Red y Tailscale](02-red-y-tailscale.md) | Tailnet, subnet router, DNS, ACLs |
| 03 | [Active Directory](03-active-directory.md) | Dominio, OUs, usuarios, grupos, permisos |
| 04 | [GLPI](04-glpi.md) | Instalacion, tickets de prueba, API |
| 05 | [Clonezilla](05-clonezilla.md) | Repositorio NFS, captura y restauracion |
| 06 | [Automatizacion](06-automatizacion.md) | Make, Bash, Ansible, GitHub Actions |
| 07 | [Seguridad / DevSecOps](07-seguridad-devsecops.md) | Secretos, hardening, backups |
| 08 | [Operaciones](08-operaciones-y-backups.md) | Día a día, backups, restauracion |
| 09 | [Troubleshooting](09-troubleshooting.md) | Fallos reales y soluciones |
| 10 | [Capturas](screenshots/README.md) | Transcripción de comandos ejecutados |

## Diagramas

- [Arquitectura general](diagramas/homelab.svg)
- [Flujo de red](diagramas/red.svg)

## Convenciones

- Los comandos se ejecutan desde la raiz del repositorio salvo indicacion contraria.
- `$VAR` son variables de `.env`.
- `> salida esperada` muestra lo que deberias ver.
- Los bloques `!!!` son decisiones de diseno o advertencias.
