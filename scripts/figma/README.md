# Scripts Figma — AVOV

Scripts para ejecutar con `use_figma` (plugin Figma MCP en Cursor).

## Archivo destino

- **File key:** `kZ0uYN2ZYLFcBjNBGhZEU3`
- **URL:** https://www.figma.com/design/kZ0uYN2ZYLFcBjNBGhZEU3

## complete-pantallas-avov.js

Crea en **una sola llamada MCP** las 3 pantallas en la página `📱 Pantallas`:

1. **Login** — basado en `login_screen.dart`
2. **Dashboard / Estudiante** — basado en `student_dashboard_screen.dart`
3. **Test Vocacional** — basado en `test_session_screen.dart`

### Cómo ejecutarlo en Cursor

Cuando tengas cuota MCP disponible (plan Dev/Full o tras reset mensual en Starter):

```
/figma-use

Ejecuta el contenido de scripts/figma/complete-pantallas-avov.js
en fileKey kZ0uYN2ZYLFcBjNBGhZEU3
```

### Límite del plan Starter

Si aparece:

> You've reached the Figma MCP tool call limit on the Starter plan

Opciones:

1. **Actualizar plan/asiento** en Figma (Dev o Full): https://www.figma.com/files/team/1447441689330181825/all-projects
2. **Esperar** al reset de cuota mensual (~6 llamadas de lectura/mes en Starter)
3. **Completar manualmente** en Figma usando el Design System ya creado (componentes en página `🎨 Design System`)

### Componentes requeridos (ya creados)

| Node | Componente |
|------|------------|
| `4:2` | Button / Primary |
| `4:4` | Input / Text (correo) |
| `4:8` | Input / Text (contraseña) |
| `4:12` | MetricCard |

Si los node IDs cambiaron, abre el archivo en Figma, selecciona cada componente y actualiza los IDs en el script.
