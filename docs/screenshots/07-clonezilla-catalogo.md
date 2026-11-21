# 07-clonezilla-catalogo.png

- Fecha: 2026-11-21T21:10:30+01:00
- Servicio: Repositorio NFS de imágenes (homelab-images)
- Comando: `ssh -o BatchMode=yes emi@192.168.0.19 'date -Iseconds; cd ~/homelab && ./infra/clonezilla/scripts/list-images.sh'`
- Qué hice: listé el catálogo con la imagen PoC `labo-disk-01` (1,2 MB)
- Resultado: correcto; no es una imagen de 40 GB
