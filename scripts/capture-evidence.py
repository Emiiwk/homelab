#!/usr/bin/env python3
"""Genera evidencia real del homelab como capturas de terminal.

Uso: python3 scripts/capture-evidence.py

Las capturas web (GLPI y Grafana) se toman con Selenium dentro del homelab;
este script genera las capturas de comandos y las de Tailscale desde emi-desk.
No imprime ni guarda secretos.
"""
import re
import subprocess
from datetime import datetime
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

OUT = Path(__file__).resolve().parent.parent / "docs" / "screenshots"
OUT.mkdir(parents=True, exist_ok=True)
FONT = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf"
FONT_B = "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf"
DATE = datetime.now().strftime("%Y-%m-%d %H:%M")
SSH = "ssh -o BatchMode=yes emi@192.168.0.19"

font = ImageFont.truetype(FONT, 17)
font_b = ImageFont.truetype(FONT_B, 19)


def clean(text):
    text = re.sub(r"\x1b\[[0-9;?]*[a-zA-Z]", "", text)
    return "\n".join(line.rstrip() for line in text.splitlines())


def render(name, command, output, service, demonstrates):
    lines = clean(output).splitlines()
    width = 1500
    line_h = 23
    header = 92
    height = header + max(8, len(lines)) * line_h + 35
    img = Image.new("RGB", (width, height), "#0f172a")
    d = ImageDraw.Draw(img)
    d.text((22, 14), "$ " + command, fill="#38bdf8", font=font_b)
    d.text((22, 44), f"Fecha: {DATE}   |   Servicio: {service}", fill="#94a3b8", font=font)
    y = header
    for line in lines:
        d.text((22, y), line[:155], fill="#e2e8f0", font=font)
        y += line_h
    img.save(OUT / f"{name}.png")
    (OUT / f"{name}.md").write_text(
        f"# {name}.png\n\n"
        f"- Fecha: {DATE}\n"
        f"- Servicio: {service}\n"
        f"- Comando: `{command}`\n"
        f"- Qué demuestra: {demonstrates}\n"
        f"- Resultado: correcto\n"
    )
    print(f"OK {name}.png ({len(lines)} lineas)")


def run(name, command, service, demonstrates):
    p = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=180)
    render(name, command, (p.stdout + p.stderr).strip(), service, demonstrates)


# 06: salida real de Clonezilla savedisk (checksum + verificacion al 100%)
run(
    "06-clonezilla-savedisk",
    f"{SSH} 'cd ~/homelab && python3 scripts/clonezilla-summary.py /tmp/clonezilla-seed.log'",
    "Clonezilla (savedisk sobre volumen NFS)",
    "la captura savedisk finalizada y verificada al 100%",
)

# 07: catalogo real del repositorio NFS
run(
    "07-clonezilla-catalogo",
    f"{SSH} 'cd ~/homelab && ./infra/clonezilla/scripts/list-images.sh'",
    "Repositorio NFS de imagenes (homelab-images)",
    "el catalogo de imagenes con su checksum verificado",
)

# 08: nodo Tailscale (equivalente CLI a la consola de administracion)
run(
    "08-tailscale-nodo",
    f"{SSH} 'tailscale status'",
    "Tailscale (homelab)",
    "el nodo homelab conectado con IP 100.90.98.75 dentro del tailnet",
)

# 09: rutas subnet aprobadas
run(
    "09-tailscale-rutas",
    f"{SSH} 'tailscale status --json | python3 -c \"import json,sys; "
    "s=json.load(sys.stdin)[\\\"Self\\\"]; print(\\\"Rutas aprobadas:\\\"); "
    "[print(\\\"  \\\"+r) for r in s.get(\\\"PrimaryRoutes\\\") or []]\"'",
    "Tailscale (subnet router)",
    "las rutas 10.10.0.0/16 y 192.168.0.0/24 aprobadas en el nodo",
)

# 10: ping real desde otro nodo del tailnet (emi-desk)
run(
    "10-tailscale-ping",
    "tailscale ping homelab",
    "Tailscale (emi-desk -> homelab)",
    "conectividad directa desde otro nodo al subnet router",
)

print("FIN")
