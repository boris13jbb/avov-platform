# Auditoría integral AVOV — Etapa C (integridad funcional, primer corte)

**Worktree:** `C:\Users\BRS\Documents\AVOV-audit-uiux`  
**Rama:** `feature/audit-integral-uiux`  
**Tras commit Etapa B:** `27372c3`

## Cambios

1. **Panel COUNSELOR:** se eliminó el mensaje falso de «herramientas no disponibles». Ahora describe el flujo real: ficha del estudiante → historial PDF / resultado / recomendaciones / observaciones. Aclara que el test RIASEC lo hace el estudiante.
2. **Código muerto:** eliminado `PendingPanelScreen` (sin ruta ni referencias).
3. **Ruta huérfana:** eliminado `RouteNames.profile` (`/profile`, no registrada en el router).

## Pendiente (siguientes cortes C / D)

- UI cambio de contraseña y forgot/reset (PRs #12 / #14; requieren autorización de porte).
- Unificación visual global (Etapa D).
- Suite completa `flutter test` + `pytest` (Etapa E).

## Pruebas

Ejecutar tras el cambio:

```powershell
cd frontend
flutter analyze
flutter test test/counselor_panel_test.dart
```
