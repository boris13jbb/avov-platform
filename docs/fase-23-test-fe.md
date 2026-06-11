# FASE 23 — Test vocacional (Flutter)

## Objetivo

Pantallas del test RIASEC para estudiantes, integradas con `/api/v1/tests` (Fase 11).

## Rutas

| Pantalla | Ruta |
|----------|------|
| Instrucciones | `/student/test/instructions` |
| Sesión de test | `/student/test/session/:id` |
| Confirmar finalización | `/student/test/finish/:id` |

## Flujo

1. Panel estudiante → **Iniciar** o **Continuar test**
2. Instrucciones → `POST /tests/start`
3. Sesión → 60 preguntas, escala 1-5, guardado automático
4. Finalizar → `POST /tests/finish` → perfil RIASEC

## Archivos implementados

| Archivo | Responsabilidad |
|---------|-----------------|
| `core/models/test_session.dart` | Modelos sesión, preguntas, RIASEC |
| `features/vocational_test/data/...` | API REST |
| `features/vocational_test/presentation/screens/*` | Instrucciones, sesión, fin |
| `features/vocational_test/presentation/widgets/scale_answer_selector.dart` | Escala 1-5 |
| `student_dashboard_screen.dart` | Acciones start/continue |

## Validación manual

Login estudiante: `estudiante.test.fase11@instituto.edu.co` / `Estud1234!`

1. Mi panel → Iniciar o Continuar test
2. Responder preguntas (escala 1-5)
3. Confirmar finalización y ver perfil RIASEC

## Siguiente fase

**FASE 24 — Resultados, PDF y recomendaciones (Flutter)**
