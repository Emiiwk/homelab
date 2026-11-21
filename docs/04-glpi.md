# 04 - GLPI: tickets de prueba

## Que se monta

GLPI 10.x con tres contenedores:

| Contenedor | Imagen | Funcion |
|---|---|---|
| `glpi` | `glpi/glpi:10.0.x` | Aplicacion web |
| `glpi-db` | `mariadb:10.11` | Base de datos |
| `glpi-cache` | `redis:7-alpine` | Cache y sesiones |

Red interna `10.10.0.0/16`. MariaDB y Redis **no exponen puertos al exterior**.

## 1. Arranque

```bash
docker compose --env-file .env -f infra/glpi/docker-compose.yml up -d
docker compose --env-file .env -f infra/glpi/docker-compose.yml logs -f glpi
```

Espera a que aparezca:

```text
glpi  | Apache/2.4.x (Debian) configured -- resuming normal operations
```

Abrir `http://10.10.0.20` (o la URL de Tailscale). Asistente inicial:

1. Seleccionar idioma **Español**.
2. Usuario `glpi`, password `glpi` (cambiar en el primer login).
3. Nombre de la BD: `glpi`, usuario `glpi`, password = `GLPI_DB_PASSWORD`.
4. Host: `glpi-db`.
5. Instalar / Actualizar.
6. Eliminar el archivo `install` cuando lo pida (el entrypoint ya lo hace).

## 2. Integrar con Active Directory (opcional pero recomendado)

En GLPI: **Configuracion > Dominios > LDAP**:

| Campo | Valor |
|---|---|
| Host | `10.10.0.10` |
| Base DN | `DC=homelab,DC=local` |
| DN de conexión | `CN=Administrator,CN=Users,DC=homelab,DC=local` |
| Password | `AD_ADMIN_PASSWORD` |
| Filtro usuarios | `(&(objectClass=user)(!(objectClass=computer)))` |
| Atributo login | `samaccountname` (en minusculas: PHP LDAP devuelve los nombres de atributo en minusculas) |

Pulsar **Probar conexión**. Devuelve 11 cuentas: las 8 del CSV más las
internas `administrator`, `guest` y `krbtgt`.

Toda esta configuración queda versionada en
[`../infra/glpi/scripts/configure-ldap.sh`](../infra/glpi/scripts/configure-ldap.sh)
y se aplica con:

```bash
./infra/glpi/scripts/configure-ldap.sh
```

Notas del laboratorio:

- El DC permite bind LDAP simple (`ldap server require strong auth = no`) para
  evitar LDAPS en un entorno sin CA interna.
- La importacion se hace en **Administracion > Usuarios > Enlace a directorio
  LDAP > Importar nuevos usuarios**. Los usuarios importados quedan con
  `authtype = 3` (LDAP) y `auths_id = 1`.

## 3. Cargar tickets de prueba

El archivo [`data/tickets.csv`](../infra/glpi/data/tickets.csv) contiene **12
incidencias realistas** con:

- Titulo y descripcion
- Categoria (Hardware, Red, Software, Seguridad, Solicitud)
- Prioridad (1-5) y urgencia
- Estado (Nuevo, Asignado, En curso, Resuelto, Cerrado)
- Tecnico asignado
- Origen (Correo, Telefono, Portal, Presencial)
- Objetivo de SLA **como texto dentro de `content`**: GLPI 10 no expone un
  campo `sla_horas` por API; no es un SLA calculable.

Ejemplo:

```csv
id,titulo,categoria,prioridad,estado,tecnico,origen,sla_horas,descripcion,seguimiento
T-001,PC no enciende tras la actualizacion,Hardware,2,Asignado,soporte1,Telefono,8,"Sin POST tras parches","Comprobada fuente; se probara RAM"
T-004,Usuario sin acceso al compartido soporte,Permisos,3,En curso,soporte2,Portal,24,"ACCESS_DENIED al montar","Resuelto el SID y aplicado setfacl"
T-009,Sospecha de phishing en correo corporativo,Seguridad,1,Nuevo,soporte1,Correo,2,"Enlace acortado recibido","Analizando cabeceras del correo"
```

Prioridad: `1=Crítica, 2=Alta, 3=Media, 4=Baja, 5=Muy baja` (se mapea a `urgency` de GLPI invirtiendo el valor).

Cargarlos con:

```bash
# Via API REST (recomendado)
./infra/glpi/scripts/seed-tickets.sh

# Comprobar el total real por API (el wrapper hace initSession por nosotros)
GLPI_URL=http://127.0.0.1:8080 ./infra/glpi/scripts/glpi-api.sh stats \
  | jq '[.[].total] | add'
# > 12
```

La captura `04-glpi-tickets.png` muestra solo **8 filas** porque el filtro de
la vista está limitado; el total de 12 se verifica con la API, no con esa
imagen.

El script es idempotente: consulta los tickets existentes y solo crea los que
faltan, usando `titulo` como clave natural.

## 4. Flujo de trabajo que simula

```text
Nuevo -> Asignado -> En curso -> Resuelto -> Cerrado
                        |
                    Pendiente (espera de usuario)
```

Cada ticket incluye **comentarios de seguimiento** para que el historial parezca
real: diagnostico, cambio aplicado y verificacion con el usuario.

## 5. API útil

```bash
GLPI_URL=http://127.0.0.1:8080
API="App-Token: $GLPI_API_TOKEN"

# initSession necesita App-Token + login/password (solo App-Token da sesión nula)
SESSION=$(curl -fsS -H "$API" -d "login=$GLPI_USER&password=$GLPI_PASSWORD" \
  "$GLPI_URL/apirest.php/initSession" | jq -r '.session_token')

# Según la versión, la respuesta viene como array o dentro de .data
curl -fsS -H "$API" -H "Session-Token: $SESSION" \
  "$GLPI_URL/apirest.php/Ticket?range=0-50" \
  | jq -r '(if type == "array" then . else .data end)[] | {id, name, status}'

curl -fsS -X POST -H "$API" -H "Session-Token: $SESSION" \
  -H 'Content-Type: application/json' \
  -d '{"input":{"name":"Fallo de prueba","content":"Creado desde API","urgency":3}}' \
  "$GLPI_URL/apirest.php/Ticket"

curl -fsS -H "$API" -H "Session-Token: $SESSION" \
  "$GLPI_URL/apirest.php/killSession" >/dev/null
```

El wrapper [`scripts/glpi-api.sh`](../infra/glpi/scripts/glpi-api.sh) hace todo esto
sin escribir curl a mano.

## 6. Que demuestra

- Instalacion y administración de un sistema ITSM real.
- **Modelado de incidencias**: prioridad, urgencia, impacto, SLA.
- Uso de **API REST** con tokens y sesiones.
- Integracion **LDAP con Active Directory**.
- Datos de prueba con sentido, no «ticket 1, ticket 2».

## Fallos tipicos

| Sintoma | Causa | Solucion |
|---|---|---|
| Pantalla de instalación no desaparece | Falta borrar `install/install.php` | `docker exec glpi rm -f /var/www/glpi/install/install.php` |
| `Access denied for user 'glpi'` | Password distinto en `.env` y BD | Recrear volumen o `ALTER USER` en MariaDB |
| API devuelve `ERROR_SESSION_TOKEN` | Token caducado | Llamar de nuevo a `initSession` |
| No conecta con LDAP | DNS o firewall | `docker exec glpi getent hosts 10.10.0.10` |
