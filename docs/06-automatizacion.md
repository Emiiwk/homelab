# 06 - Automatizacion

Tres capas, de mas simple a mas completa:

```text
Make  -> atajos legibles para el dia a dia
Bash  -> logica de aprovisionamiento y verificacion
Ansible -> configuración declarativa y repetible
CI    -> validacion automatica en GitHub
```

## 1. Make

Desde la raiz:

```bash
make help          # ver todos los objetivos
make init          # preparar .env y volumenes
make up            # levantar todo
make status        # estado de contenedores
make health        # healthchecks
make seed          # cargar usuarios AD y tickets
make backup        # backup cifrado
make down          # parar todo
```

El `Makefile` usa siempre `docker compose --env-file .env -f infra/docker-compose.yml`,
asi que no hay variables sueltas por consola.

## 2. Scripts Bash

| Script | Funcion |
|---|---|
| `scripts/bootstrap.sh` | Preparacion inicial del anfitrion (sysctl, directorios, Docker) |
| `scripts/start.sh` / `stop.sh` | Arranque/parada ordenada |
| `scripts/status.sh` | Resumen legible de servicios |
| `scripts/healthcheck.sh` | Comprueba puertos, DNS y contenedores |
| `scripts/backup.sh` | Backup cifrado con restic |
| `scripts/validate.sh` | Validaciones antes de commit |
| `scripts/lib/common.sh` | Funciones compartidas (log, die, require, wait_for) |

Convenciones:

- `set -Eeuo pipefail` en todos.
- Funciones `log INFO/WARN/ERROR` con fecha.
- `wait_for host port timeout` antes de depender de un servicio.
- Salidas con código de error claro.

Ejemplo real de `wait_for`:

```bash
wait_for 10.10.0.10 389 60
# [INFO] Esperando 10.10.0.10:389 ... (1/60)
# [OK] 10.10.0.10:389 disponible
```

## 3. Ansible

Inventario en `ansible/inventory.ini`, variables en `ansible/group_vars/all.yml`.

```bash
cd ansible
ansible-galaxy collection install ansible.posix community.general
ansible-playbook -i inventory.ini playbooks/site.yml --ask-vault-pass
```

Playbooks:

| Playbook | Objetivo |
|---|---|
| `site.yml` | Orquesta todos |
| `ad.yml` | Instala tools, configura DNS, aprovisiona usuarios |
| `glpi.yml` | Despliega stack y semilla tickets |

Todas las tareas son **idempotentes**: ejecutar dos veces no cambia nada. Eso se
comprueba con `--check` y comparando el `changed=` de la segúnda ejecucion:

```bash
ansible-playbook -i inventory.ini playbooks/site.yml --check
# changed=0  -> correcto
```

!!! nota "Cifrado"
    Las variables sensibles van en `group_vars/vault.yml` cifrado con
    `ansible-vault`. Nunca en texto plano.

## 4. GitHub Actions

| Workflow | Archivo | Funcion |
|---|---|---|
| CI | `.github/workflows/validate.yml` | `shellcheck`, `yamllint`, markdown links, deteccion de secretos |
| Docs | `.github/workflows/docs.yml` | Publica la documentación en GitHub Pages |

Cada push a `main` ejecuta la validacion. Un PR con un `tskey-` en el diff
falla automaticamente.

## 5. Flujo de trabajo recomendado

```text
1. Cambio en config
2. make test       (validacion local)
3. git commit
4. push -> CI
5. make up         (despliegue en el homelab)
6. make health
7. Actualizar capturas y docs
```

## 6. Que demuestra

- **IaC**: todo el entorno se reconstruye desde cero con comandos.
- **Idempotencia**: repetible sin efectos secundarios.
- **CI**: calidad y seguridad automatizadas, no solo «funciona en mi casa».
- **Documentacion como código**: se valida en el pipeline.
