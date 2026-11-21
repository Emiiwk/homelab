# 01-ad-usuarios.png

- Fecha: 2026-11-21 18:42
- Servicio: Samba AD DC (homelab-ad)
- Comando: `docker exec homelab-ad wbinfo -u`
- Qué hice: listé 11 cuentas resueltas por winbind (8 del CSV + `administrator`, `guest`, `krbtgt`)
- Resultado: correcto
