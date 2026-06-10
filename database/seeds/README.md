# Seeds de base de datos — AVOV

Carpeta reservada para scripts de datos iniciales. Se poblará en fases posteriores:

| Fase | Seed | Contenido |
|------|------|-----------|
| 4 | `riasec_categories.sql` | 6 categorías RIASEC (R, I, A, S, E, C) |
| 10 | `questions.sql` | 60 preguntas (10 por categoría) |
| 9 | `careers.sql` | Carreras de ejemplo clasificadas por perfil RIASEC |
| 5 | `super_admin.sql` | Usuario SuperAdmin inicial (solo desarrollo) |

Los seeds se ejecutarán mediante scripts Alembic o comandos documentados en `docs/instalacion-local.md`.
