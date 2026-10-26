# Auditoría integral AVOV — Etapa D (UI/UX, primer corte)

**Rama:** `feature/audit-integral-uiux`  
**Alcance:** sistema visual compartido + aplicación a paneles y pantallas clave (sin reescritura total).

## Sistema visual

| Pieza | Ubicación |
|---|---|
| Espaciado | `core/theme/app_spacing.dart` |
| Tema ampliado | `core/theme/app_theme.dart` (botones, chips, diálogos, inputs, cards) |
| Estados | `shared/widgets/app_state_view.dart` (`AppStateView`, `AppPageHeader`, `AppMetricCard`) |
| Colores | `AppColors` existentes (identidad AVOV conservada) |

## Pantallas actualizadas en este corte

- Login (jerarquía de marca y espaciado)
- Dashboards: SUPER_ADMIN, INSTITUTION_ADMIN, COUNSELOR, STUDENT (errores vía `AppStateView`)
- Listado de instituciones (vacío/error + espaciado)

## Pendiente UI (siguientes cortes)

- Migrar el resto de `_Notice` / `_ListNotice` privados a `AppStateView`
- Unificar densidad de listados users/students/careers/questions/audit
- Revisión de contraste/accesibilidad en dispositivo real
- Etapa E: suite completa de pruebas

## Validación

```powershell
cd frontend
flutter analyze
flutter test test/shared/app_state_view_test.dart test/admin_dashboard_test.dart test/counselor_panel_test.dart test/login_flow_test.dart
```
