# 05 - Clonezilla: imagenes de equipo

## Que se monta

Un **repositorio NFS** donde Clonezilla Live guarda y restaura imagenes de
maquinas del laboratorio. El arranque se hace con una ISO/USB de Clonezilla
(por eso es una imagen «de verdad», no un contenedor simulado).

| Elemento | Valor |
|---|---|
| Servidor NFS | `10.10.0.30` |
| Exportacion | `/srv/clonezilla/images` |
| Cliente | `10.10.0.0/16`, `192.168.0.0/24` |
| Protocolo | NFSv4.2 (`NFS_DISABLE_VERSION_3=1`, `fsid=0`) |
| Imagen real | `labo-disk-01` (savedisk verificado) |

## 1. Levantar el repositorio

```bash
docker compose --env-file .env -f infra/clonezilla/docker-compose.yml up -d
docker compose --env-file .env -f infra/clonezilla/docker-compose.yml logs -f images
```

Comprobar el montaje NFSv4 desde el anfitrion:

```bash
sudo mkdir -p /mnt/nfs-test
sudo mount -t nfs -o vers=4,addr=10.10.0.30 10.10.0.30:/ /mnt/nfs-test
ls /mnt/nfs-test
# disco-labo.raw  labo-disk-01
sudo umount /mnt/nfs-test
```

NFSv3 esta desactivado porque `rpc.statd` fallaba en este host con poca RAM.
Clonezilla debe montar con `nfsvers=4` (opcion `device-image` > `nfs_server`).

## 2. Preparar un USB de Clonezilla Live

```bash
# Descargar ISO estable desde https://clonezilla.org/downloads.php
wget -O /tmp/clonezilla-live.iso \
  https://downloads.sourceforge.net/clonezilla/clonezilla-live-3.1.2-22-amd64.iso

# Grabar en USB (SUSTITUYE /dev/sdX POR TU DISPOSITIVO)
sudo dd if=/tmp/clonezilla-live.iso of=/dev/sdX bs=4M status=progress conv=fsync
```

!!! peligro "Cuidado con dd"
    Comprueba el dispositivo con `lsblk` antes de ejecutar. `dd` sobre el disco
    equivocado destruye datos.

Arrancar el equipo a imaginar con el USB. En el menu de Clonezilla:

1. `Clonezilla live (To RAM. Boot media can be removed later)`.
2. Teclado -> `Don't change keymap` (o Español).
3. `Start Clonezilla`.
4. `device-device` o `device-image` -> elegir **`device-image`**.
5. **`ssh_server` / `nfs_server`** -> Introducir `10.10.0.30`.
6. Directorio remoto: `/srv/clonezilla/images`.
7. Elegir `savedisk` (capturar) o `restoredisk` (restaurar).

## 3. Capturar una imagen

Desde Clonezilla (o desde el anfitrion con el helper):

```bash
./infra/clonezilla/scripts/create-image.sh win10-base /dev/sda
```

Que hace el script:

1. Verifica que el destino existe y hay espacio (`df -h`).
2. Crea `images/win10-base/`.
3. Ejecuta `clonezilla -s -q2 -j2 -z1p -p true savedisk ...`.
4. Guarda un `metadata.json` con fecha, disco, tamano y hash.
5. Escribe `images/win10-base/info.txt` legible por humanos.

Ejemplo de `metadata.json`:

```json
{
  "name": "win10-base",
  "created": "2026-11-21T10:32:11+01:00",
  "source_disk": "/dev/sda",
  "size_bytes": 42949672960,
  "compression": "zstd -p",
  "sha256": "9f2c...c41a",
  "notes": "Base limpia, actualizada, sin datos de usuario"
}
```

### Imagen real generada en el laboratorio

El repositorio contiene `labo-disk-01`, una imagen real `savedisk` de un disco
loopback de 64 MiB con una partición ext4. Se capturó con `ocs-sr` (Clonezilla
5.9.9) sobre el volumen NFS `homelab-images`, y el propio Clonezilla la marcó
como restaurable tras verificarla al 100%.

```text
[2026-11-21 20:11:45] [OK] Checksum guardado: 35a11f5d742c317e5c82a9e94318a01cda6cb398d5ca87ed6f133462fb750360
[2026-11-21 20:11:45] [OK] Imagen 'labo-disk-01' creada correctamente (1,2M)
```

Evidencia: `docs/screenshots/06-clonezilla-savedisk.png` y
`docs/screenshots/07-clonezilla-catalogo.png`.

## 4. Restaurar una imagen

```bash
./infra/clonezilla/scripts/restore-image.sh win10-base /dev/sda
```

Siempre con doble confirmacion. El script muestra primero la imagen seleccionada
y el disco destino, y exige escribir `YES`.

```text
Vas a RESTAURAR 'win10-base' en /dev/sda
  Tamano imagen : 40 GB
  Disco destino : 500 GB (sda)
  Los datos actuales de /dev/sda SE PERDERAN

Escribe YES para continuar:
```

## 5. Listar y verificar imagenes

```bash
./infra/clonezilla/scripts/list-images.sh
# IMAGEN            FECHA        TAMANO   ESTADO
# labo-disk-01       2026-11-21   1,2M     OK (verificado)
```

Verificacion de integridad:

```bash
sha256sum -c infra/clonezilla/images/labo-disk-01/sha256sums.txt
```

## 6. Que demuestra

- Entender **captura vs clonado**, `dd` vs imagenes con compression.
- Saber trabajar con **NFS**, permisos y espacio compartido.
- Saber **restaurar un equipo** con un objetivo de tiempo (RTO) medido.
- Documentar un **catalogo de imagenes** con metadata y verificacion.

## Fallos tipicos

| Sintoma | Causa | Solucion |
|---|---|---|
| Clonezilla no ve el NFS | Firewall o ruta no permitida | `exportfs -v` en el servidor, revisar `nfs.conf` |
| `Permission denied` al montar | `no_root_squash` ausente | Anadirlo solo a la IP del cliente |
| La imagen no arranca | Falto `grub` o UEFI/Legacy distinto | Capturar con el mismo modo de arranque |
| Restauracion muy lenta | Disco de red o compresion alta | Usar `-z1p` (paralelo) y gigabit |
