# 02-ad-grupos.png

- Fecha: 2026-11-21 18:42
- Servicio: Samba AD DC (homelab-ad)
- Comando: `docker exec homelab-ad samba-tool group list | grep -E '^(Soporte|TI-Admin|Usuarios|Invitados)$'; echo '--- miembros de Soporte ---'; docker exec homelab-ad samba-tool group listmembers Soporte`
- Qué demuestra: los grupos de laboratorio y la pertenencia de soporte2 al grupo Soporte
- Resultado: correcto
