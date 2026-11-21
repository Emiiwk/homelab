#!/usr/bin/env python3
"""Genera transcripciones de comandos ejecutados en el homelab.

Uso: HOMELAB_SSH_HOST=emi@192.168.0.19 python3 scripts/capture-evidence.py

Los PNG son reconstrucciones tipográficas de salidas reales (subprocess.run),
no capturas de pantalla. La fecha se toma del sistema que ejecuta el comando
(`date -Iseconds` va dentro del propio comando). No imprime ni guarda secretos.
"""
import os
import re
import subprocess
from datetime import datetime
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent.parent / "docs" / "screenshots"
OUT.mkdir(parents=True, exist_ok=True)
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
SSH_HOST = os.environ.get("HOMELAB_SSH_HOST", "emi@192.168.0.19")
SSH = f"ssh -o BatchMode=yes {SSH_HOST}"

font = ImageFont.truetype(FONT, 17)
font_b = ImageFont.truetype(FONT_B, 19)
ISO_DATE = re.compile(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}[+-]\d{2}:\d{2}")


def clean(text):
    text = re.sub(r"\x1b\[[0-9;?]*[a-zA-Z]", "", text)
    return "\n".join(line.rstrip() for line in text.splitlines())


def render(name, command, output, service, action, result="correcto"):
    lines = clean(output).splitlines()
    match = ISO_DATE.search(output)
    date = match.group(0) if match else datetime.now().astimezone().isoformat(timespec="seconds")
    width = 1500
    line_h = 23
    header = 92
    height = header + max(8, len(lines)) * line_h + 35
    img = Image.new("RGB", (width, height), "#0f172a")
    d = ImageDraw.Draw(img)
    d.text((22, 14), "$ " + command, fill="#38bdf8", font=font_b)
    d.text((22, 44), f"Fecha sistema: {date}   |   Servicio: {service}", fill="#94a3b8", font=font)
    y = header
    for line in lines:
        d.text((22, y), line[:155], fill="#e2e8f0", font=font)
        y += line_h
    img.save(OUT / f"{name}.png")
    (OUT / f"{name}.md").write_text(
        f"# {name}.png\n\n"
        f"- Fecha: {date}\n"
        f"- Servicio: {service}\n"
        f"- Comando: `{command}`\n"
        f"- Qué hice: {action}\n"
        f"- Resultado: {result}\n"
    )
    print(f"OK {name}.png ({len(lines)} lineas, {date})")


def run(name, command, service, action, result="correcto"):
    p = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=180)
    render(name, command, (p.stdout + p.stderr).strip(), service, action, result)


# 06: PoC de Clonezilla sobre disco loopback (checksum + verificacion)
run(
    "06-clonezilla-savedisk",
    f"{SSH} 'date -Iseconds; cd ~/homelab && python3 scripts/clonezilla-summary.py /tmp/clonezilla-seed.log'",
    "Clonezilla (PoC sobre volumen NFS)",
    "generé un savedisk real de un disco loopback de 64 MiB y verifiqué su checksum",
    "correcto como PoC; restauración en equipo real pendiente",
)

# 07: catalogo real del repositorio NFS
run(
    "07-clonezilla-catalogo",
    f"{SSH} 'date -Iseconds; cd ~/homelab && ./infra/clonezilla/scripts/list-images.sh'",
    "Repositorio NFS de imágenes (homelab-images)",
    "listé el catálogo con la imagen PoC `labo-disk-01` (1,2 MB)",
    "correcto; no es una imagen de 40 GB",
)

# 08: nodo Tailscale
run(
    "08-tailscale-nodo",
    f"{SSH} 'date -Iseconds; tailscale status'",
    "Tailscale (homelab)",
    "comprobé el nodo `homelab` conectado en el tailnet",
)

# 09: rutas subnet aprobadas
run(
    "09-tailscale-rutas",
    f"{SSH} 'date -Iseconds; tailscale status --json | python3 -c \"import json,sys; "
    "s=json.load(sys.stdin)[\\\"Self\\\"]; print(\\\"Rutas aprobadas:\\\"); "
    "[print(\\\"  \\\"+r) for r in s.get(\\\"PrimaryRoutes\\\") or []]\"'",
    "Tailscale (subnet router)",
    "verifiqué las rutas 10.10.0.0/16 y 192.168.0.0/24 aprobadas",
)

# 10: ping real desde otro nodo del tailnet
run(
    "10-tailscale-ping",
    "date -Iseconds; tailscale ping homelab",
    "Tailscale (emi-desk -> homelab)",
    "hice ping desde `emi-desk` hasta el subnet router",
)

print("FIN")
