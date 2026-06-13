# Checklist manual UI Flutter — Fase 41

Checklist para validación visual y funcional del frontend antes de release institucional.
Ejecutar con backend activo (dev `:8000`, staging `:8080`, prod-local `:8090` o SSL `:8443`).

## Preparación

1. Configurar `API_BASE_URL` en Flutter según entorno.
2. Ejecutar `flutter analyze` y `flutter test` sin errores.
3. Tener credenciales de prueba:
   - Super admin: `admin@avov.edu.co` / `Admin123!`
   - Estudiante: `estudiante.test.fase11@instituto.edu.co` / `Estud1234!`

---

## A. Autenticación y navegación

| # | Acción | Resultado esperado | OK |
|---|--------|-------------------|-----|
| A1 | Abrir app sin sesión | Redirige a login | [ ] |
| A2 | Login credenciales inválidas | Mensaje claro en español, sin crash | [ ] |
| A3 | Login super admin | Dashboard super admin | [ ] |
| A4 | Login estudiante | Dashboard estudiante | [ ] |
| A5 | Cerrar sesión | Vuelve a login, rutas protegidas bloqueadas | [ ] |
| A6 | Cambiar contraseña (perfil) | Validación y éxito | [ ] |

---

## B. Responsive (móvil, tablet, web)

| # | Acción | Resultado esperado | OK |
|---|--------|-------------------|-----|
| B1 | Login en pantalla pequeña (360px) | Sin overflow, botón visible | [ ] |
| B2 | Dashboard en tablet | Grid legible, sin recortes | [ ] |
| B3 | Formularios largos con teclado | Campos visibles, scroll correcto | [ ] |
| B4 | Web desktop | Layout coherente, navegación usable | [ ] |

---

## C. Estudiante — test vocacional

| # | Acción | Resultado esperado | OK |
|---|--------|-------------------|-----|
| C1 | Iniciar test RIASEC | 60 preguntas, escala 1-5 | [ ] |
| C2 | Responder parcial y salir | Al volver, continúa sesión en progreso | [ ] |
| C3 | Finalizar test completo | Mensaje de éxito, resultados RIASEC | [ ] |
| C4 | Intentar editar test finalizado | Bloqueado o mensaje claro | [ ] |
| C5 | Ver recomendaciones | Lista de carreras + disclaimer ético | [ ] |
| C6 | Descargar PDF | PDF válido con datos del estudiante | [ ] |

---

## D. Orientador e institución

| # | Acción | Resultado esperado | OK |
|---|--------|-------------------|-----|
| D1 | Orientador ve estudiantes permitidos | Solo su alcance | [ ] |
| D2 | Agregar observación vocacional | Guardada y visible en resultados | [ ] |
| D3 | Admin institución — settings | Solo su institución | [ ] |
| D4 | Reportes/exportaciones institución | Descarga CSV/PDF según permisos | [ ] |

---

## E. Super admin

| # | Acción | Resultado esperado | OK |
|---|--------|-------------------|-----|
| E1 | CRUD instituciones | Crear/editar/listar sin error | [ ] |
| E2 | CRUD carreras y preguntas | Validación y persistencia | [ ] |
| E3 | Panel vector admin | Rebuild índice Qdrant exitoso | [ ] |
| E4 | Settings globales | Cambios reflejados en `/settings/public` | [ ] |
| E5 | Modo mantenimiento | Usuarios no admin ven pantalla mantenimiento | [ ] |

---

## F. Asistente IA

| # | Acción | Resultado esperado | OK |
|---|--------|-------------------|-----|
| F1 | Abrir chat asistente | Contexto vocacional visible | [ ] |
| F2 | Enviar pregunta | Respuesta orientativa + disclaimer ético | [ ] |
| F3 | Rate limit / error red | Mensaje claro, sin crash | [ ] |

---

## Registro de ejecución

| Campo | Valor |
|-------|-------|
| Fecha | |
| Entorno | dev / staging / prod-local / SSL local |
| API_BASE_URL | |
| Dispositivos probados | |
| Tester | |
| Incidencias | |

---

## Criterio de aprobación

- Mínimo **90%** de ítems marcados OK en secciones A, C y E.
- Cero bloqueadores en responsive (sección B).
- PDF y test vocacional completos sin errores (C5, C6).
