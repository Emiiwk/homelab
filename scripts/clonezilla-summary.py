#!/usr/bin/env python3
"""Resume una salida de Clonezilla quitando los codigos de terminal."""
import re
import sys
from pathlib import Path

data = Path(sys.argv[1] if len(sys.argv) > 1 else "/tmp/clonezilla-seed.log").read_text(errors="ignore")
data = re.sub(r"\x1b[\(\)\[\][0-9;?]*[a-zA-Z0-9]?", "", data)

for phrase in (
    "Data Block Process:",
    "100%",
    "Partclone successfully checked the image",
    "Checked successfully.",
    "Checksum guardado:",
    "creada correctamente",
):
    i = data.find(phrase)
    if i >= 0:
        print(data[i:].splitlines()[0].strip()[:130])
