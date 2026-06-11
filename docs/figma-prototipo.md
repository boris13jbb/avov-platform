# Prototipo Figma — AVOV

## Archivo de diseño

| Campo | Valor |
|-------|-------|
| Nombre | AVOV - Prototipo UI |
| URL | https://www.figma.com/design/kZ0uYN2ZYLFcBjNBGhZEU3 |
| File key | `kZ0uYN2ZYLFcBjNBGhZEU3` |
| Cuenta | boris13jb@gmail.com |
| Plan | Starter (Juan Burbano's team) |

## Estructura del archivo

### Página: 🎨 Design System

- **Tokens / Colores** — paleta AVOV alineada con `app_colors.dart`
- **Variables**
  - `AVOV Colors`: primary, secondary, accent, background, surface, error, success, text-primary, text-secondary
  - `AVOV Spacing`: space-4, space-8, space-16, space-24, space-32
- **Componentes**
  - `Button / Primary` — node `4:2`
  - `Input / Text` (correo) — node `4:4`
  - `Input / Text` (contraseña) — node `4:8`
  - `MetricCard` — node `4:12`

### Página: 📱 Pantallas

Pantallas listas para generar con un solo script MCP:

| Pantalla | Fuente Flutter | Estado |
|----------|----------------|--------|
| Login | `login_screen.dart` | ⏸ Script listo — cuota MCP agotada |
| Dashboard / Estudiante | `student_dashboard_screen.dart` | ⏸ Script listo — cuota MCP agotada |
| Test Vocacional | `test_session_screen.dart` | ⏸ Script listo — cuota MCP agotada |

**Script:** `scripts/figma/complete-pantallas-avov.js` (1 llamada `use_figma` para las 3 pantallas)

## Code Connect (mapeos locales)

Archivos `.figma.ts` en el frontend para vincular componentes Figma ↔ widgets Flutter:

| Archivo | Widget Flutter | Node Figma |
|---------|----------------|------------|
| `metric_card.figma.ts` | MetricCard | 4:12 |
| `error_banner.figma.ts` | ErrorBanner | 4:4 |
| `chat_bubble.figma.ts` | ChatBubble | 4:2 |
| `login_screen.figma.ts` | LoginScreen | (pantalla) |

Configuración: `frontend/figma.config.json`

## Comandos útiles en Cursor

```
/add-plugin figma
/figma-generate-design
/figma-code-connect
/figma-use
```

## Límite del plan Starter

El plan Starter limita las llamadas MCP (~6 lecturas/mes; escritura también tiene cuota). Error actual:

```
You've reached the Figma MCP tool call limit on the Starter plan
```

**Opciones para completar las pantallas:**

| Opción | Acción |
|--------|--------|
| A — Actualizar Figma | Asiento Dev/Full en https://www.figma.com/files/team/1447441689330181825/all-projects |
| B — Esperar reset | Cuota mensual; luego en Cursor: ejecutar `scripts/figma/complete-pantallas-avov.js` |
| C — Manual en Figma | Duplicar componentes de `🎨 Design System` en frames 390×844 en `📱 Pantallas` |

## Próximos pasos

1. Ejecutar `scripts/figma/complete-pantallas-avov.js` vía `/figma-use` cuando haya cuota MCP.
2. Publicar componentes del Design System como team library para Code Connect oficial.
3. Actualizar `node-id` en archivos `*.figma.ts` con los IDs devueltos por el script.
