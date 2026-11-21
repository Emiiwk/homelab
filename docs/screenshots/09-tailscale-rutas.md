# 09-tailscale-rutas.png

- Fecha: 2026-11-21T21:10:30+01:00
- Servicio: Tailscale (subnet router)
- Comando: `ssh -o BatchMode=yes emi@192.168.0.19 'date -Iseconds; tailscale status --json | python3 -c "import json,sys; s=json.load(sys.stdin)[\"Self\"]; print(\"Rutas aprobadas:\"); [print(\"  \"+r) for r in s.get(\"PrimaryRoutes\") or []]"'`
- Qué hice: verifiqué las rutas 10.10.0.0/16 y 192.168.0.0/24 aprobadas
- Resultado: correcto
