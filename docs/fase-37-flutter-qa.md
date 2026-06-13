# FASE 37 COMPLETADA — QA Flutter automatizado

## 1. Resumen

Se automatizaron las pruebas de **navegación y pantallas críticas** del frontend Flutter que el smoke API no cubre: redirección por rol, `/unauthorized`, mantenimiento, login dinámico y validación integral con `flutter analyze` + `flutter test`.

La lógica de redirección se extrajo a `AuthRedirectLogic` (función pura testeable sin red ni secure storage).

## 2. Archivos creados

| Archivo | Descripción |
|---------|-------------|
| `frontend/lib/router/auth_redirect_logic.dart` | Lógica pura de redirección |
| `frontend/test/auth_redirect_logic_test.dart` | 13 tests de rutas y roles |
| `frontend/test/navigation_screens_test.dart` | Widget tests unauthorized + maintenance |
| `scripts/validate-flutter-qa.ps1` | Script validación analyze + test |
| `docs/fase-37-flutter-qa.md` | Este documento |
| `docs/fase-37-flutter-qa-report.txt` | Reporte generado al ejecutar |

## 3. Archivos modificados

| Archivo | Cambio |
|---------|--------|
| `frontend/lib/router/auth_guard.dart` | Delega en `AuthRedirectLogic` |
| `frontend/test/widget_test.dart` | Test `app_display_name` dinámico |
| `docs/plan-desarrollo.md` | Estado Fase 37 |
| `docs/checklist-qa.md` | Ítems Flutter marcados |
| `README.md` | Comando `validate-flutter-qa.ps1` |

## 4. Cobertura de tests nuevos

| Área | Casos |
|------|-------|
| Auth redirect | Sin sesión → login; rol cruzado → unauthorized; mantenimiento; super admin bypass |
| Pantallas | UnauthorizedScreen, MaintenanceScreen con nombre dinámico |
| Login | `app_display_name` desde settings públicas |

## 5. Comandos

```powershell
# Validación integral Flutter
.\scripts\validate-flutter-qa.ps1

# Manual
cd frontend
flutter analyze
flutter test
```

## 6. Próximo paso

- Prueba manual en navegador/dispositivo: flujo completo test 60 preguntas + PDF
- Despliegue en servidor real según [manual-produccion.md](manual-produccion.md)
