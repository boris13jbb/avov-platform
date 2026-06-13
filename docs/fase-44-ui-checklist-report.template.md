# Reporte checklist UI — Despliegue institucional AVOV (Fase 44)

Completar tras ejecutar [fase-41-flutter-ui-manual.md](fase-41-flutter-ui-manual.md) contra la URL publica del frontend.

## Datos del despliegue

| Campo | Valor |
|-------|-------|
| Fecha | |
| Institucion | |
| Tester | |
| Frontend URL | https://app.tudominio.edu.co |
| API URL | https://api.tudominio.edu.co/api/v1 |
| Entorno | produccion institucional |
| Version / commit | |
| Dispositivos probados | Web desktop, movil, tablet |

## Credenciales de prueba usadas

| Rol | Email | Resultado login |
|-----|-------|-----------------|
| Super admin | admin@avov.edu.co | [ ] OK [ ] FALLO |
| Estudiante | estudiante.test.fase11@instituto.edu.co | [ ] OK [ ] FALLO |
| Orientador | | [ ] OK [ ] FALLO [ ] N/A |
| Admin institucion | | [ ] OK [ ] FALLO [ ] N/A |

---

## Resumen por seccion

| Seccion | Total items | OK | FALLO | % OK |
|---------|-------------|-----|-------|------|
| A. Autenticacion | 6 | | | |
| B. Responsive | 4 | | | |
| C. Estudiante test | 6 | | | |
| D. Orientador/institucion | 4 | | | |
| E. Super admin | 5 | | | |
| F. Asistente IA | 3 | | | |
| **TOTAL** | **28** | | | |

---

## Criterio de aprobacion release institucional

- [ ] Minimo **90%** OK en secciones A, C y E
- [ ] Cero bloqueadores en responsive (seccion B)
- [ ] PDF y test vocacional OK (C5, C6)
- [ ] Smoke automatizado OK: `smoke-public-release.ps1`
- [ ] Post-deploy OK: `post-deploy-prod.ps1`
- [ ] Backups cron instalados en VPS

## Incidencias

| ID | Seccion | Descripcion | Severidad | Estado |
|----|---------|-------------|-----------|--------|
| 1 | | | bloqueante / menor | abierta / cerrada |

## Decision final

- [ ] **APROBADO** para uso institucional
- [ ] **RECHAZADO** — requiere correcciones

Firma / responsable: _______________________
