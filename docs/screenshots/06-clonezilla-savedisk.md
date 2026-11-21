# 06-clonezilla-savedisk.png

- Fecha: 2026-11-21T21:10:29+01:00
- Servicio: Clonezilla (PoC sobre volumen NFS)
- Comando: `ssh -o BatchMode=yes emi@192.168.0.19 'date -Iseconds; cd ~/homelab && python3 scripts/clonezilla-summary.py /tmp/clonezilla-seed.log'`
- Qué hice: generé un savedisk real de un disco loopback de 64 MiB y verifiqué su checksum
- Resultado: correcto como PoC; restauración en equipo real pendiente
