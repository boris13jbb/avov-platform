# Expediente Técnico Profesional para el Desarrollo de un Asistente Virtual Multiplataforma con IA para Orientación Vocacional

**Producto:** OrientaVoc AI 360  
**Versión:** 1.2  
**Fecha:** 09 de junio de 2026 - Actualización v1.2 MySQL + Qdrant  
**Enfoque:** Aplicación multiplataforma para orientación vocacional con IA, RIASEC, reportes PDF, panel institucional y despliegue a producción.

> Documento técnico basado en el trabajo de grado proporcionado sobre un asistente virtual con IA para orientación vocacional en estudiantes de bachillerato. El expediente amplía el prototipo hacia un producto multiplataforma y productivo.

## Stack tecnológico recomendado

- **Frontend multiplataforma:** Flutter + Dart, Riverpod, GoRouter, Dio, Freezed, Flutter Secure Storage, SQLite/Drift para modo offline
- **Backend API:** FastAPI + Python, Pydantic, SQLAlchemy 2, Alembic, arquitectura modular limpia
- **Base de datos transaccional:** MySQL 8.4 LTS para usuarios, instituciones, sesiones, respuestas, reportes y auditoría operativa
- **Base de datos vectorial:** Qdrant como base vectorial especializada para embeddings, búsqueda semántica, filtros por metadatos, RAG vocacional y catálogo enriquecido
- **IA/LLM:** Adaptador de proveedores: DeepSeek API como proveedor inicial, con fallback OpenAI-compatible y Ollama local para pruebas
- **Mensajería y tareas:** Redis + Celery/RQ para generación de PDF, análisis IA, correos y tareas programadas
- **Almacenamiento:** S3 compatible: AWS S3, Cloudflare R2 o MinIO para reportes, evidencias y anexos
- **Seguridad:** JWT/OAuth2, Argon2id, MFA opcional, auditoría, cifrado en tránsito, políticas OWASP ASVS
- **DevOps:** Docker, docker-compose, GitHub Actions, Nginx, TLS Let’s Encrypt, staging y producción
- **Observabilidad:** OpenTelemetry, Prometheus, Grafana, Loki, Sentry, auditoría de eventos


## Actualización técnica v1.2: reemplazo de PostgreSQL/pgvector por Qdrant

Sí es posible usar MySQL/phpMyAdmin como base principal y reemplazar PostgreSQL/pgvector por Qdrant. La arquitectura recomendada queda separada por responsabilidades: MySQL será la base de datos principal transaccional del aplicativo, phpMyAdmin servirá para administrar MySQL durante desarrollo y soporte, y Qdrant será el motor vectorial especializado para embeddings, búsqueda semántica, RAG vocacional y recomendaciones inteligentes.

### Decisión final aprobada

- Mantener Flutter para Android, iOS, Web y escritorio.
- Mantener FastAPI por su compatibilidad natural con Python, IA, validaciones Pydantic y documentación OpenAPI.
- Usar MySQL 8.4 LTS para usuarios, instituciones, sesiones, respuestas, consentimiento, reportes, auditoría y configuración.
- Usar Qdrant para documentos vocacionales, embeddings de carreras, búsqueda semántica, filtros por metadatos y recuperación aumentada por generación.
- Usar Redis para caché, colas, rate limit, sesiones temporales y control de tareas asíncronas.
- Usar Docker y docker-compose para desarrollo local, staging y producción.
- Usar DeepSeek API mediante un adaptador de proveedor LLM para evitar dependencia rígida de un solo modelo.

### Regla arquitectónica obligatoria

MySQL será la fuente de verdad transaccional. Qdrant será una base derivada para búsqueda semántica y RAG. Si existe conflicto, gana MySQL. Los vectores de Qdrant se podrán reconstruir desde MySQL mediante tareas de sincronización.

---



## Índice maestro por fases

- **FASE 0: Gobierno documental, visión y control del expediente** — fichas 1 a 10
- **FASE 1: Descubrimiento, investigación y análisis del problema** — fichas 11 a 25
- **FASE 2: Alcance funcional, roles, módulos y requisitos** — fichas 26 a 45
- **FASE 3: Experiencia de usuario, accesibilidad e interfaz multiplataforma** — fichas 46 a 60
- **FASE 4: Arquitectura de software y selección del stack tecnológico** — fichas 61 a 80
- **FASE 5: Modelo de datos, base de datos y catálogo vocacional** — fichas 81 a 105
- **FASE 6: Backend, API, servicios y lógica de negocio** — fichas 106 a 130
- **FASE 7: Motor RIASEC, IA, prompts y recomendador vocacional** — fichas 131 a 155
- **FASE 8: Frontend Flutter multiplataforma** — fichas 156 a 180
- **FASE 9: Reportes PDF, analítica, paneles y trazabilidad** — fichas 181 a 195
- **FASE 10: Seguridad, privacidad, ética y cumplimiento** — fichas 196 a 215
- **FASE 11: Pruebas QA, validación psicológica y evaluación estadística** — fichas 216 a 235
- **FASE 12: DevOps, infraestructura, CI/CD y publicación** — fichas 236 a 255
- **FASE 13: Producción, soporte, monitoreo y mejora continua** — fichas 256 a 270
- **ANEXOS: Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor** — fichas 271 a 310

---


<!-- pagebreak -->

## Página técnica 001: FASE 0.01 - Propósito del expediente

**Fase:** Gobierno documental, visión y control del expediente  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Propósito del expediente" dentro de gobierno documental, visión y control del expediente, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase organiza el expediente como documento vivo: define visión, límites, reglas, entregables y gobierno para evitar improvisación durante el desarrollo.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Propósito del expediente": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Propósito del expediente" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Propósito del expediente".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 002: FASE 0.02 - Contexto académico y social

**Fase:** Gobierno documental, visión y control del expediente  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Contexto académico y social" dentro de gobierno documental, visión y control del expediente, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase organiza el expediente como documento vivo: define visión, límites, reglas, entregables y gobierno para evitar improvisación durante el desarrollo.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Contexto académico y social": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Contexto académico y social" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Contexto académico y social".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 003: FASE 0.03 - Producto objetivo

**Fase:** Gobierno documental, visión y control del expediente  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Producto objetivo" dentro de gobierno documental, visión y control del expediente, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase organiza el expediente como documento vivo: define visión, límites, reglas, entregables y gobierno para evitar improvisación durante el desarrollo.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Producto objetivo": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Producto objetivo" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Producto objetivo".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 004: FASE 0.04 - Principios de diseño

**Fase:** Gobierno documental, visión y control del expediente  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Principios de diseño" dentro de gobierno documental, visión y control del expediente, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase organiza el expediente como documento vivo: define visión, límites, reglas, entregables y gobierno para evitar improvisación durante el desarrollo.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Principios de diseño": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Principios de diseño" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Principios de diseño".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 005: FASE 0.05 - Glosario inicial

**Fase:** Gobierno documental, visión y control del expediente  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Glosario inicial" dentro de gobierno documental, visión y control del expediente, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase organiza el expediente como documento vivo: define visión, límites, reglas, entregables y gobierno para evitar improvisación durante el desarrollo.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Glosario inicial": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Glosario inicial" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Glosario inicial".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 006: FASE 0.06 - Mapa de interesados

**Fase:** Gobierno documental, visión y control del expediente  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Mapa de interesados" dentro de gobierno documental, visión y control del expediente, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase organiza el expediente como documento vivo: define visión, límites, reglas, entregables y gobierno para evitar improvisación durante el desarrollo.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Mapa de interesados": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Mapa de interesados" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Mapa de interesados".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 007: FASE 0.07 - Criterios de éxito

**Fase:** Gobierno documental, visión y control del expediente  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Criterios de éxito" dentro de gobierno documental, visión y control del expediente, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase organiza el expediente como documento vivo: define visión, límites, reglas, entregables y gobierno para evitar improvisación durante el desarrollo.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Criterios de éxito": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Criterios de éxito" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Criterios de éxito".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 008: FASE 0.08 - Riesgos globales

**Fase:** Gobierno documental, visión y control del expediente  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Riesgos globales" dentro de gobierno documental, visión y control del expediente, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase organiza el expediente como documento vivo: define visión, límites, reglas, entregables y gobierno para evitar improvisación durante el desarrollo.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Riesgos globales": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Riesgos globales" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Riesgos globales".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 009: FASE 0.09 - Entregables del proyecto

**Fase:** Gobierno documental, visión y control del expediente  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Entregables del proyecto" dentro de gobierno documental, visión y control del expediente, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase organiza el expediente como documento vivo: define visión, límites, reglas, entregables y gobierno para evitar improvisación durante el desarrollo.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Entregables del proyecto": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Entregables del proyecto" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Entregables del proyecto".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 010: FASE 0.10 - Plan maestro de 300 páginas

**Fase:** Gobierno documental, visión y control del expediente  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Plan maestro de 300 páginas" dentro de gobierno documental, visión y control del expediente, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase organiza el expediente como documento vivo: define visión, límites, reglas, entregables y gobierno para evitar improvisación durante el desarrollo.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Plan maestro de 300 páginas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Plan maestro de 300 páginas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Plan maestro de 300 páginas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 011: FASE 1.01 - Problema de orientación vocacional

**Fase:** Descubrimiento, investigación y análisis del problema  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Problema de orientación vocacional" dentro de descubrimiento, investigación y análisis del problema, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase comprende el problema educativo, la realidad institucional, los usuarios y las necesidades que justifican el asistente virtual.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Problema de orientación vocacional": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Problema de orientación vocacional" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Problema de orientación vocacional".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 012: FASE 1.02 - Estudiantes beneficiarios

**Fase:** Descubrimiento, investigación y análisis del problema  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Estudiantes beneficiarios" dentro de descubrimiento, investigación y análisis del problema, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase comprende el problema educativo, la realidad institucional, los usuarios y las necesidades que justifican el asistente virtual.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Estudiantes beneficiarios": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Estudiantes beneficiarios" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Estudiantes beneficiarios".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 013: FASE 1.03 - Contexto Ecuador y bachillerato

**Fase:** Descubrimiento, investigación y análisis del problema  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Contexto Ecuador y bachillerato" dentro de descubrimiento, investigación y análisis del problema, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase comprende el problema educativo, la realidad institucional, los usuarios y las necesidades que justifican el asistente virtual.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Contexto Ecuador y bachillerato": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Contexto Ecuador y bachillerato" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Contexto Ecuador y bachillerato".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 014: FASE 1.04 - Necesidad de personalización

**Fase:** Descubrimiento, investigación y análisis del problema  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Necesidad de personalización" dentro de descubrimiento, investigación y análisis del problema, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase comprende el problema educativo, la realidad institucional, los usuarios y las necesidades que justifican el asistente virtual.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Necesidad de personalización": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Necesidad de personalización" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Necesidad de personalización".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 015: FASE 1.05 - Benchmark de soluciones

**Fase:** Descubrimiento, investigación y análisis del problema  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Benchmark de soluciones" dentro de descubrimiento, investigación y análisis del problema, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase comprende el problema educativo, la realidad institucional, los usuarios y las necesidades que justifican el asistente virtual.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Benchmark de soluciones": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Benchmark de soluciones" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Benchmark de soluciones".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 016: FASE 1.06 - Encuesta diagnóstica

**Fase:** Descubrimiento, investigación y análisis del problema  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Encuesta diagnóstica" dentro de descubrimiento, investigación y análisis del problema, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase comprende el problema educativo, la realidad institucional, los usuarios y las necesidades que justifican el asistente virtual.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Encuesta diagnóstica": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Encuesta diagnóstica" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Encuesta diagnóstica".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 017: FASE 1.07 - Análisis de causas y efectos

**Fase:** Descubrimiento, investigación y análisis del problema  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Análisis de causas y efectos" dentro de descubrimiento, investigación y análisis del problema, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase comprende el problema educativo, la realidad institucional, los usuarios y las necesidades que justifican el asistente virtual.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Análisis de causas y efectos": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Análisis de causas y efectos" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Análisis de causas y efectos".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 018: FASE 1.08 - Hipótesis de solución

**Fase:** Descubrimiento, investigación y análisis del problema  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Hipótesis de solución" dentro de descubrimiento, investigación y análisis del problema, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase comprende el problema educativo, la realidad institucional, los usuarios y las necesidades que justifican el asistente virtual.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Hipótesis de solución": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Hipótesis de solución" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Hipótesis de solución".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 019: FASE 1.09 - Objetivo general

**Fase:** Descubrimiento, investigación y análisis del problema  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Objetivo general" dentro de descubrimiento, investigación y análisis del problema, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase comprende el problema educativo, la realidad institucional, los usuarios y las necesidades que justifican el asistente virtual.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Objetivo general": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Objetivo general" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Objetivo general".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 020: FASE 1.10 - Objetivos específicos

**Fase:** Descubrimiento, investigación y análisis del problema  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Objetivos específicos" dentro de descubrimiento, investigación y análisis del problema, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase comprende el problema educativo, la realidad institucional, los usuarios y las necesidades que justifican el asistente virtual.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Objetivos específicos": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Objetivos específicos" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Objetivos específicos".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 021: FASE 1.11 - Alcance y delimitación

**Fase:** Descubrimiento, investigación y análisis del problema  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Alcance y delimitación" dentro de descubrimiento, investigación y análisis del problema, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase comprende el problema educativo, la realidad institucional, los usuarios y las necesidades que justifican el asistente virtual.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Alcance y delimitación": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Alcance y delimitación" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Alcance y delimitación".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 022: FASE 1.12 - Supuestos y restricciones

**Fase:** Descubrimiento, investigación y análisis del problema  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Supuestos y restricciones" dentro de descubrimiento, investigación y análisis del problema, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase comprende el problema educativo, la realidad institucional, los usuarios y las necesidades que justifican el asistente virtual.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Supuestos y restricciones": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Supuestos y restricciones" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Supuestos y restricciones".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 023: FASE 1.13 - Viabilidad técnica

**Fase:** Descubrimiento, investigación y análisis del problema  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Viabilidad técnica" dentro de descubrimiento, investigación y análisis del problema, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase comprende el problema educativo, la realidad institucional, los usuarios y las necesidades que justifican el asistente virtual.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Viabilidad técnica": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Viabilidad técnica" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Viabilidad técnica".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 024: FASE 1.14 - Viabilidad económica

**Fase:** Descubrimiento, investigación y análisis del problema  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Viabilidad económica" dentro de descubrimiento, investigación y análisis del problema, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase comprende el problema educativo, la realidad institucional, los usuarios y las necesidades que justifican el asistente virtual.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Viabilidad económica": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Viabilidad económica" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Viabilidad económica".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 025: FASE 1.15 - Acta de inicio

**Fase:** Descubrimiento, investigación y análisis del problema  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Acta de inicio" dentro de descubrimiento, investigación y análisis del problema, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase comprende el problema educativo, la realidad institucional, los usuarios y las necesidades que justifican el asistente virtual.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Acta de inicio": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Acta de inicio" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Acta de inicio".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 026: FASE 2.01 - Módulo de test vocacional

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Módulo de test vocacional" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Módulo de test vocacional": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Módulo de test vocacional" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Módulo de test vocacional".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 027: FASE 2.02 - Módulo de perfil RIASEC

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Módulo de perfil RIASEC" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Módulo de perfil RIASEC": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Módulo de perfil RIASEC" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Módulo de perfil RIASEC".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 028: FASE 2.03 - Módulo de IA generativa

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Módulo de IA generativa" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Módulo de IA generativa": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Módulo de IA generativa" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Módulo de IA generativa".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 029: FASE 2.04 - Módulo de informes PDF

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Módulo de informes PDF" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Módulo de informes PDF": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Módulo de informes PDF" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Módulo de informes PDF".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 030: FASE 2.05 - Módulo de sesiones

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Módulo de sesiones" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Módulo de sesiones": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Módulo de sesiones" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Módulo de sesiones".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 031: FASE 2.06 - Módulo de usuarios y roles

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Módulo de usuarios y roles" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Módulo de usuarios y roles": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Módulo de usuarios y roles" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Módulo de usuarios y roles".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 032: FASE 2.07 - Módulo de instituciones

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Módulo de instituciones" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Módulo de instituciones": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Módulo de instituciones" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Módulo de instituciones".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 033: FASE 2.08 - Módulo de catálogo de carreras

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Módulo de catálogo de carreras" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Módulo de catálogo de carreras": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Módulo de catálogo de carreras" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Módulo de catálogo de carreras".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 034: FASE 2.09 - Módulo DECE/Psicólogo

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Módulo DECE/Psicólogo" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Módulo DECE/Psicólogo": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Módulo DECE/Psicólogo" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Módulo DECE/Psicólogo".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 035: FASE 2.10 - Módulo de analítica

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Módulo de analítica" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Módulo de analítica": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Módulo de analítica" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Módulo de analítica".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 036: FASE 2.11 - Módulo de auditoría

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Módulo de auditoría" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Módulo de auditoría": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Módulo de auditoría" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Módulo de auditoría".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 037: FASE 2.12 - Módulo de notificaciones

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Módulo de notificaciones" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Módulo de notificaciones": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Módulo de notificaciones" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Módulo de notificaciones".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 038: FASE 2.13 - Requisitos funcionales estudiante

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Requisitos funcionales estudiante" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Requisitos funcionales estudiante": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Requisitos funcionales estudiante" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Requisitos funcionales estudiante".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 039: FASE 2.14 - Requisitos funcionales psicólogo

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Requisitos funcionales psicólogo" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Requisitos funcionales psicólogo": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Requisitos funcionales psicólogo" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Requisitos funcionales psicólogo".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 040: FASE 2.15 - Requisitos funcionales administrador

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Requisitos funcionales administrador" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Requisitos funcionales administrador": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Requisitos funcionales administrador" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Requisitos funcionales administrador".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 041: FASE 2.16 - Requisitos no funcionales

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Requisitos no funcionales" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Requisitos no funcionales": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Requisitos no funcionales" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Requisitos no funcionales".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 042: FASE 2.17 - Reglas de negocio

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Reglas de negocio" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Reglas de negocio": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Reglas de negocio" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Reglas de negocio".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 043: FASE 2.18 - Historias de usuario

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Historias de usuario" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Historias de usuario": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Historias de usuario" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Historias de usuario".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 044: FASE 2.19 - Criterios de aceptación

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Criterios de aceptación" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Criterios de aceptación": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Criterios de aceptación" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Criterios de aceptación".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 045: FASE 2.20 - Matriz de trazabilidad

**Fase:** Alcance funcional, roles, módulos y requisitos  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Matriz de trazabilidad" dentro de alcance funcional, roles, módulos y requisitos, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte el problema en funcionalidades verificables, roles, permisos, módulos y requisitos medibles.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Matriz de trazabilidad": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Matriz de trazabilidad" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Matriz de trazabilidad".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 046: FASE 3.01 - Arquitectura UX

**Fase:** Experiencia de usuario, accesibilidad e interfaz multiplataforma  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Arquitectura UX" dentro de experiencia de usuario, accesibilidad e interfaz multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la experiencia visual y de interacción para que el sistema pueda usarse en celular, tablet, web y escritorio.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Arquitectura UX": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Arquitectura UX" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Arquitectura UX".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 047: FASE 3.02 - Mapa de navegación

**Fase:** Experiencia de usuario, accesibilidad e interfaz multiplataforma  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Mapa de navegación" dentro de experiencia de usuario, accesibilidad e interfaz multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la experiencia visual y de interacción para que el sistema pueda usarse en celular, tablet, web y escritorio.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Mapa de navegación": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Mapa de navegación" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Mapa de navegación".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 048: FASE 3.03 - Onboarding del estudiante

**Fase:** Experiencia de usuario, accesibilidad e interfaz multiplataforma  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Onboarding del estudiante" dentro de experiencia de usuario, accesibilidad e interfaz multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la experiencia visual y de interacción para que el sistema pueda usarse en celular, tablet, web y escritorio.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Onboarding del estudiante": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Onboarding del estudiante" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Onboarding del estudiante".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 049: FASE 3.04 - Pantalla de consentimiento

**Fase:** Experiencia de usuario, accesibilidad e interfaz multiplataforma  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Pantalla de consentimiento" dentro de experiencia de usuario, accesibilidad e interfaz multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la experiencia visual y de interacción para que el sistema pueda usarse en celular, tablet, web y escritorio.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pantalla de consentimiento": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pantalla de consentimiento" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pantalla de consentimiento".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 050: FASE 3.05 - Pantalla del test

**Fase:** Experiencia de usuario, accesibilidad e interfaz multiplataforma  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Pantalla del test" dentro de experiencia de usuario, accesibilidad e interfaz multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la experiencia visual y de interacción para que el sistema pueda usarse en celular, tablet, web y escritorio.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pantalla del test": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pantalla del test" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pantalla del test".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 051: FASE 3.06 - Pantalla de progreso

**Fase:** Experiencia de usuario, accesibilidad e interfaz multiplataforma  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Pantalla de progreso" dentro de experiencia de usuario, accesibilidad e interfaz multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la experiencia visual y de interacción para que el sistema pueda usarse en celular, tablet, web y escritorio.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pantalla de progreso": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pantalla de progreso" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pantalla de progreso".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 052: FASE 3.07 - Pantalla de resultados

**Fase:** Experiencia de usuario, accesibilidad e interfaz multiplataforma  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Pantalla de resultados" dentro de experiencia de usuario, accesibilidad e interfaz multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la experiencia visual y de interacción para que el sistema pueda usarse en celular, tablet, web y escritorio.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pantalla de resultados": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pantalla de resultados" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pantalla de resultados".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 053: FASE 3.08 - Pantalla de informe PDF

**Fase:** Experiencia de usuario, accesibilidad e interfaz multiplataforma  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Pantalla de informe PDF" dentro de experiencia de usuario, accesibilidad e interfaz multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la experiencia visual y de interacción para que el sistema pueda usarse en celular, tablet, web y escritorio.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pantalla de informe PDF": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pantalla de informe PDF" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pantalla de informe PDF".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 054: FASE 3.09 - Panel del psicólogo

**Fase:** Experiencia de usuario, accesibilidad e interfaz multiplataforma  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Panel del psicólogo" dentro de experiencia de usuario, accesibilidad e interfaz multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la experiencia visual y de interacción para que el sistema pueda usarse en celular, tablet, web y escritorio.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Panel del psicólogo": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Panel del psicólogo" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Panel del psicólogo".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 055: FASE 3.10 - Panel del administrador

**Fase:** Experiencia de usuario, accesibilidad e interfaz multiplataforma  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Panel del administrador" dentro de experiencia de usuario, accesibilidad e interfaz multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la experiencia visual y de interacción para que el sistema pueda usarse en celular, tablet, web y escritorio.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Panel del administrador": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Panel del administrador" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Panel del administrador".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 056: FASE 3.11 - Diseño responsive

**Fase:** Experiencia de usuario, accesibilidad e interfaz multiplataforma  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Diseño responsive" dentro de experiencia de usuario, accesibilidad e interfaz multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la experiencia visual y de interacción para que el sistema pueda usarse en celular, tablet, web y escritorio.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Diseño responsive": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Diseño responsive" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Diseño responsive".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 057: FASE 3.12 - Accesibilidad WCAG

**Fase:** Experiencia de usuario, accesibilidad e interfaz multiplataforma  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Accesibilidad WCAG" dentro de experiencia de usuario, accesibilidad e interfaz multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la experiencia visual y de interacción para que el sistema pueda usarse en celular, tablet, web y escritorio.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Accesibilidad WCAG": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Accesibilidad WCAG" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Accesibilidad WCAG".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 058: FASE 3.13 - Microcopys

**Fase:** Experiencia de usuario, accesibilidad e interfaz multiplataforma  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Microcopys" dentro de experiencia de usuario, accesibilidad e interfaz multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la experiencia visual y de interacción para que el sistema pueda usarse en celular, tablet, web y escritorio.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Microcopys": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Microcopys" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Microcopys".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 059: FASE 3.14 - Prototipo en Figma

**Fase:** Experiencia de usuario, accesibilidad e interfaz multiplataforma  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Prototipo en Figma" dentro de experiencia de usuario, accesibilidad e interfaz multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la experiencia visual y de interacción para que el sistema pueda usarse en celular, tablet, web y escritorio.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Prototipo en Figma": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Prototipo en Figma" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Prototipo en Figma".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 060: FASE 3.15 - Validación UX

**Fase:** Experiencia de usuario, accesibilidad e interfaz multiplataforma  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Validación UX" dentro de experiencia de usuario, accesibilidad e interfaz multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la experiencia visual y de interacción para que el sistema pueda usarse en celular, tablet, web y escritorio.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Validación UX": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Validación UX" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Validación UX".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 061: FASE 4.01 - Decisión de Flutter

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Estudiante

### Objetivo
Seleccionar Flutter como tecnología principal del cliente multiplataforma para construir Android, iOS, Web, Windows, macOS y Linux desde una sola base de código.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Decisión de Flutter": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Decisión de Flutter" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Decisión de Flutter".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
Stack recomendado:
- Cliente: Flutter + Dart + Riverpod + GoRouter + Dio
- API: FastAPI + Pydantic + SQLAlchemy + Alembic
- Datos: MySQL 8.4 LTS + Qdrant + Redis
- IA: DeepSeek API con adaptador OpenAI-compatible y fallback Ollama
- Infra: Docker + Nginx + TLS + GitHub Actions + monitoreo
```


<!-- pagebreak -->

## Página técnica 062: FASE 4.02 - Decisión de FastAPI

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Representante/Familia

### Objetivo
Seleccionar FastAPI como backend principal porque el proyecto necesita IA en Python, APIs tipadas, documentación OpenAPI y despliegue productivo.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Decisión de FastAPI": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Decisión de FastAPI" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Decisión de FastAPI".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
Stack recomendado:
- Cliente: Flutter + Dart + Riverpod + GoRouter + Dio
- API: FastAPI + Pydantic + SQLAlchemy + Alembic
- Datos: MySQL 8.4 LTS + Qdrant + Redis
- IA: DeepSeek API con adaptador OpenAI-compatible y fallback Ollama
- Infra: Docker + Nginx + TLS + GitHub Actions + monitoreo
```


<!-- pagebreak -->

## Página técnica 063: FASE 4.03 - Decisión de MySQL transaccional

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Decisión de MySQL transaccional" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Decisión de MySQL transaccional": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Decisión de MySQL transaccional" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Decisión de MySQL transaccional".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
Stack recomendado:
- Cliente: Flutter + Dart + Riverpod + GoRouter + Dio
- API: FastAPI + Pydantic + SQLAlchemy + Alembic
- Datos: MySQL 8.4 LTS + Qdrant + Redis
- IA: DeepSeek API con adaptador OpenAI-compatible y fallback Ollama
- Infra: Docker + Nginx + TLS + GitHub Actions + monitoreo
```


<!-- pagebreak -->

## Página técnica 064: FASE 4.04 - Decisión de MySQL + Qdrant

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Decisión de MySQL + Qdrant" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Decisión de MySQL + Qdrant": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Decisión de MySQL + Qdrant" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Decisión de MySQL + Qdrant".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
Stack recomendado:
- Cliente: Flutter + Dart + Riverpod + GoRouter + Dio
- API: FastAPI + Pydantic + SQLAlchemy + Alembic
- Datos: MySQL 8.4 LTS + Qdrant + Redis
- IA: DeepSeek API con adaptador OpenAI-compatible y fallback Ollama
- Infra: Docker + Nginx + TLS + GitHub Actions + monitoreo
```


<!-- pagebreak -->

## Página técnica 065: FASE 4.05 - Arquitectura lógica

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Arquitectura lógica" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Arquitectura lógica": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Arquitectura lógica" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Arquitectura lógica".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
Stack recomendado:
- Cliente: Flutter + Dart + Riverpod + GoRouter + Dio
- API: FastAPI + Pydantic + SQLAlchemy + Alembic
- Datos: MySQL 8.4 LTS + Qdrant + Redis
- IA: DeepSeek API con adaptador OpenAI-compatible y fallback Ollama
- Infra: Docker + Nginx + TLS + GitHub Actions + monitoreo
```


<!-- pagebreak -->

## Página técnica 066: FASE 4.06 - Arquitectura física

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Arquitectura física" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Arquitectura física": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Arquitectura física" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Arquitectura física".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 067: FASE 4.07 - Arquitectura limpia

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Arquitectura limpia" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Arquitectura limpia": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Arquitectura limpia" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Arquitectura limpia".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 068: FASE 4.08 - DDD básico

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "DDD básico" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "DDD básico": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "DDD básico" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "DDD básico".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 069: FASE 4.09 - Monolito modular inicial

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Monolito modular inicial" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Monolito modular inicial": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Monolito modular inicial" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Monolito modular inicial".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 070: FASE 4.10 - Evolución a microservicios

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Evolución a microservicios" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Evolución a microservicios": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Evolución a microservicios" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Evolución a microservicios".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 071: FASE 4.11 - API Gateway

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "API Gateway" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "API Gateway": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "API Gateway" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "API Gateway".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 072: FASE 4.12 - Gestión de configuración

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Gestión de configuración" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Gestión de configuración": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Gestión de configuración" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Gestión de configuración".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 073: FASE 4.13 - Patrón repositorio

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Patrón repositorio" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Patrón repositorio": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Patrón repositorio" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Patrón repositorio".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 074: FASE 4.14 - Patrón servicio

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Patrón servicio" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Patrón servicio": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Patrón servicio" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Patrón servicio".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 075: FASE 4.15 - Patrón adaptador IA

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Patrón adaptador IA" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Patrón adaptador IA": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Patrón adaptador IA" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Patrón adaptador IA".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 076: FASE 4.16 - Manejo de errores

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Manejo de errores" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Manejo de errores": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Manejo de errores" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Manejo de errores".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 077: FASE 4.17 - Escalabilidad horizontal

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Escalabilidad horizontal" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Escalabilidad horizontal": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Escalabilidad horizontal" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Escalabilidad horizontal".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 078: FASE 4.18 - Alta disponibilidad

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Alta disponibilidad" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Alta disponibilidad": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Alta disponibilidad" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Alta disponibilidad".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 079: FASE 4.19 - Costos cloud

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Costos cloud" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Costos cloud": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Costos cloud" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Costos cloud".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 080: FASE 4.20 - Arquitectura final aprobada

**Fase:** Arquitectura de software y selección del stack tecnológico  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Arquitectura final aprobada" dentro de arquitectura de software y selección del stack tecnológico, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase define la arquitectura tecnológica recomendada para construir una solución robusta, mantenible y escalable.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Arquitectura final aprobada": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Arquitectura final aprobada" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Arquitectura final aprobada".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 081: FASE 5.01 - Modelo entidad-relación MySQL + Qdrant

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Estudiante

### Objetivo
Preparar Qdrant como motor vectorial independiente, mientras MySQL conserva los datos transaccionales principales del aplicativo.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Modelo entidad-relación MySQL + Qdrant": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Modelo entidad-relación MySQL + Qdrant" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Modelo entidad-relación MySQL + Qdrant".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 082: FASE 5.02 - Tabla instituciones

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Tabla instituciones" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla instituciones": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla instituciones" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla instituciones".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_instituciones (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 083: FASE 5.03 - Tabla usuarios

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Tabla usuarios" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla usuarios": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla usuarios" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla usuarios".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_usuarios (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 084: FASE 5.04 - Tabla roles y permisos

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Tabla roles y permisos" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla roles y permisos": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla roles y permisos" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla roles y permisos".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_roles_y_permisos (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 085: FASE 5.05 - Tabla estudiantes

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Tabla estudiantes" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla estudiantes": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla estudiantes" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla estudiantes".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_estudiantes (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 086: FASE 5.06 - Tabla representantes

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Tabla representantes" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla representantes": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla representantes" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla representantes".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_representantes (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 087: FASE 5.07 - Tabla sesiones de test

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Tabla sesiones de test" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla sesiones de test": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla sesiones de test" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla sesiones de test".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_sesiones_de_test (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 088: FASE 5.08 - Tabla preguntas IPPJ

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Tabla preguntas IPPJ" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla preguntas IPPJ": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla preguntas IPPJ" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla preguntas IPPJ".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_preguntas_ippj (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 089: FASE 5.09 - Tabla respuestas

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Tabla respuestas" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla respuestas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla respuestas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla respuestas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_respuestas (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 090: FASE 5.10 - Tabla puntajes RIASEC

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Tabla puntajes RIASEC" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla puntajes RIASEC": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla puntajes RIASEC" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla puntajes RIASEC".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_puntajes_riasec (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 091: FASE 5.11 - Tabla carreras

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Tabla carreras" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla carreras": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla carreras" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla carreras".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_carreras (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 092: FASE 5.12 - Tabla categorías RIASEC

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Tabla categorías RIASEC" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla categorías RIASEC": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla categorías RIASEC" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla categorías RIASEC".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_categor_as_riasec (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 093: FASE 5.13 - Tabla recomendaciones

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Tabla recomendaciones" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla recomendaciones": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla recomendaciones" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla recomendaciones".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_recomendaciones (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 094: FASE 5.14 - Tabla reportes PDF

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Tabla reportes PDF" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla reportes PDF": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla reportes PDF" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla reportes PDF".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_reportes_pdf (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 095: FASE 5.15 - Tabla auditoría

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Tabla auditoría" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla auditoría": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla auditoría" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla auditoría".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_auditor_a (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 096: FASE 5.16 - Tabla prompts

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Tabla prompts" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla prompts": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla prompts" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla prompts".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_prompts (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 097: FASE 5.17 - Tabla proveedores IA

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Tabla proveedores IA" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla proveedores IA": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla proveedores IA" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla proveedores IA".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_proveedores_ia (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 098: FASE 5.18 - Tabla feedback

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Tabla feedback" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla feedback": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla feedback" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla feedback".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_feedback (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 099: FASE 5.19 - Tabla métricas

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Tabla métricas" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla métricas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla métricas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla métricas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_m_tricas (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 100: FASE 5.20 - Tabla consentimientos

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Tabla consentimientos" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tabla consentimientos": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tabla consentimientos" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tabla consentimientos".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
CREATE TABLE tabla_consentimientos (
    id UUID PRIMARY KEY,
    institution_id UUID NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    status VARCHAR(30) NOT NULL DEFAULT 'active'
);
-- Agregar campos específicos según el diccionario de datos de esta ficha.
```


<!-- pagebreak -->

## Página técnica 101: FASE 5.21 - Índices y constraints

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Índices y constraints" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Índices y constraints": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Índices y constraints" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Índices y constraints".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 102: FASE 5.22 - Migraciones Alembic

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Migraciones Alembic" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Migraciones Alembic": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Migraciones Alembic" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Migraciones Alembic".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 103: FASE 5.23 - Semillas de datos

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Semillas de datos" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Semillas de datos": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Semillas de datos" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Semillas de datos".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 104: FASE 5.24 - Backups

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Backups" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Backups": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Backups" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Backups".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 105: FASE 5.25 - Diccionario de datos

**Fase:** Modelo de datos, base de datos y catálogo vocacional  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Diccionario de datos" dentro de modelo de datos, base de datos y catálogo vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase diseña la información persistente del sistema, garantizando integridad, trazabilidad, auditoría y crecimiento futuro.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Diccionario de datos": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Diccionario de datos" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Diccionario de datos".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 106: FASE 6.01 - Estructura del backend

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Estructura del backend" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Estructura del backend": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Estructura del backend" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Estructura del backend".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
@router.post('/estructura-del-backend')
async def ejecutar_1(payload: SchemaEntrada, user: User = Depends(get_current_user)):
    validar_permisos(user)
    resultado = await service.ejecutar(payload)
    return ApiResponse(ok=True, data=resultado)
```


<!-- pagebreak -->

## Página técnica 107: FASE 6.02 - Configuración .env

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Configuración .env" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Configuración .env": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Configuración .env" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Configuración .env".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 108: FASE 6.03 - Autenticación JWT

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Autenticación JWT" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Autenticación JWT": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Autenticación JWT" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Autenticación JWT".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 109: FASE 6.04 - Registro institucional

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Registro institucional" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Registro institucional": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Registro institucional" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Registro institucional".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 110: FASE 6.05 - CRUD de usuarios

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "CRUD de usuarios" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "CRUD de usuarios": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "CRUD de usuarios" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "CRUD de usuarios".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
@router.post('/crud-de-usuarios')
async def ejecutar_5(payload: SchemaEntrada, user: User = Depends(get_current_user)):
    validar_permisos(user)
    resultado = await service.ejecutar(payload)
    return ApiResponse(ok=True, data=resultado)
```


<!-- pagebreak -->

## Página técnica 111: FASE 6.06 - CRUD de estudiantes

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "CRUD de estudiantes" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "CRUD de estudiantes": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "CRUD de estudiantes" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "CRUD de estudiantes".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 112: FASE 6.07 - CRUD de preguntas

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "CRUD de preguntas" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "CRUD de preguntas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "CRUD de preguntas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "CRUD de preguntas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 113: FASE 6.08 - Inicio de test

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Inicio de test" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Inicio de test": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Inicio de test" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Inicio de test".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 114: FASE 6.09 - Guardado de respuestas

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Guardado de respuestas" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Guardado de respuestas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Guardado de respuestas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Guardado de respuestas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
@router.post('/guardado-de-respuestas')
async def ejecutar_9(payload: SchemaEntrada, user: User = Depends(get_current_user)):
    validar_permisos(user)
    resultado = await service.ejecutar(payload)
    return ApiResponse(ok=True, data=resultado)
```


<!-- pagebreak -->

## Página técnica 115: FASE 6.10 - Cálculo de resultados

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Cálculo de resultados" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Cálculo de resultados": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Cálculo de resultados" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Cálculo de resultados".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 116: FASE 6.11 - Servicio de recomendaciones

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Servicio de recomendaciones" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Servicio de recomendaciones": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Servicio de recomendaciones" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Servicio de recomendaciones".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 117: FASE 6.12 - Servicio de PDF

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Servicio de PDF" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Servicio de PDF": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Servicio de PDF" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Servicio de PDF".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 118: FASE 6.13 - Servicio de notificaciones

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Servicio de notificaciones" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Servicio de notificaciones": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Servicio de notificaciones" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Servicio de notificaciones".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
@router.post('/servicio-de-notificaciones')
async def ejecutar_13(payload: SchemaEntrada, user: User = Depends(get_current_user)):
    validar_permisos(user)
    resultado = await service.ejecutar(payload)
    return ApiResponse(ok=True, data=resultado)
```


<!-- pagebreak -->

## Página técnica 119: FASE 6.14 - Servicio de auditoría

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Servicio de auditoría" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Servicio de auditoría": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Servicio de auditoría" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Servicio de auditoría".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 120: FASE 6.15 - OpenAPI Swagger

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "OpenAPI Swagger" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "OpenAPI Swagger": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "OpenAPI Swagger" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "OpenAPI Swagger".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 121: FASE 6.16 - Validaciones Pydantic

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Validaciones Pydantic" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Validaciones Pydantic": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Validaciones Pydantic" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Validaciones Pydantic".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 122: FASE 6.17 - Manejo de excepciones

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Manejo de excepciones" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Manejo de excepciones": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Manejo de excepciones" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Manejo de excepciones".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
@router.post('/manejo-de-excepciones')
async def ejecutar_17(payload: SchemaEntrada, user: User = Depends(get_current_user)):
    validar_permisos(user)
    resultado = await service.ejecutar(payload)
    return ApiResponse(ok=True, data=resultado)
```


<!-- pagebreak -->

## Página técnica 123: FASE 6.18 - Paginación y filtros

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Paginación y filtros" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Paginación y filtros": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Paginación y filtros" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Paginación y filtros".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 124: FASE 6.19 - Pruebas unitarias API

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Pruebas unitarias API" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pruebas unitarias API": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pruebas unitarias API" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pruebas unitarias API".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 125: FASE 6.20 - Pruebas de integración

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Pruebas de integración" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pruebas de integración": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pruebas de integración" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pruebas de integración".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 126: FASE 6.21 - Rate limiting

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Rate limiting" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Rate limiting": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Rate limiting" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Rate limiting".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
@router.post('/rate-limiting')
async def ejecutar_21(payload: SchemaEntrada, user: User = Depends(get_current_user)):
    validar_permisos(user)
    resultado = await service.ejecutar(payload)
    return ApiResponse(ok=True, data=resultado)
```


<!-- pagebreak -->

## Página técnica 127: FASE 6.22 - CORS y seguridad HTTP

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "CORS y seguridad HTTP" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "CORS y seguridad HTTP": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "CORS y seguridad HTTP" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "CORS y seguridad HTTP".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 128: FASE 6.23 - Tareas asíncronas

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Tareas asíncronas" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tareas asíncronas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tareas asíncronas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tareas asíncronas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 129: FASE 6.24 - Versionado de API

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Versionado de API" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Versionado de API": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Versionado de API" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Versionado de API".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 130: FASE 6.25 - Documentación backend

**Fase:** Backend, API, servicios y lógica de negocio  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Documentación backend" dentro de backend, api, servicios y lógica de negocio, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase describe la construcción del backend, sus endpoints, servicios, validaciones, seguridad y documentación API.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Documentación backend": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Documentación backend" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Documentación backend".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
@router.post('/documentacion-backend')
async def ejecutar_25(payload: SchemaEntrada, user: User = Depends(get_current_user)):
    validar_permisos(user)
    resultado = await service.ejecutar(payload)
    return ApiResponse(ok=True, data=resultado)
```


<!-- pagebreak -->

## Página técnica 131: FASE 7.01 - Fundamento RIASEC

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Fundamento RIASEC" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Fundamento RIASEC": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Fundamento RIASEC" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Fundamento RIASEC".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 132: FASE 7.02 - Diseño del test IPPJ

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Diseño del test IPPJ" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Diseño del test IPPJ": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Diseño del test IPPJ" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Diseño del test IPPJ".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 133: FASE 7.03 - Escala de respuestas

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Escala de respuestas" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Escala de respuestas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Escala de respuestas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Escala de respuestas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 134: FASE 7.04 - Algoritmo de puntaje

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Algoritmo de puntaje" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Algoritmo de puntaje": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Algoritmo de puntaje" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Algoritmo de puntaje".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 135: FASE 7.05 - Perfil primario y secundario

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Perfil primario y secundario" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Perfil primario y secundario": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Perfil primario y secundario" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Perfil primario y secundario".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 136: FASE 7.06 - Interpretación de perfil

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Interpretación de perfil" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Interpretación de perfil": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Interpretación de perfil" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Interpretación de perfil".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 137: FASE 7.07 - Catálogo de 436 carreras

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Catálogo de 436 carreras" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Catálogo de 436 carreras": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Catálogo de 436 carreras" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Catálogo de 436 carreras".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 138: FASE 7.08 - Mapeo carrera-perfil

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Mapeo carrera-perfil" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Mapeo carrera-perfil": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Mapeo carrera-perfil" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Mapeo carrera-perfil".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 139: FASE 7.09 - Embeddings de carreras

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Embeddings de carreras" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Embeddings de carreras": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Embeddings de carreras" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Embeddings de carreras".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 140: FASE 7.10 - RAG vocacional

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Administrador Institucional

### Objetivo
Implementar recuperación aumentada por generación para que la IA recomiende carreras usando únicamente el catálogo validado y reglas vocacionales.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "RAG vocacional": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "RAG vocacional" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "RAG vocacional".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 141: FASE 7.11 - Prompt del recomendador

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Prompt del recomendador" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Prompt del recomendador": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Prompt del recomendador" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Prompt del recomendador".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 142: FASE 7.12 - Prompt del informe

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Prompt del informe" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Prompt del informe": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Prompt del informe" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Prompt del informe".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 143: FASE 7.13 - Guardrails del modelo

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Guardrails del modelo" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Guardrails del modelo": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Guardrails del modelo" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Guardrails del modelo".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 144: FASE 7.14 - Validación de salida IA

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Validación de salida IA" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Validación de salida IA": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Validación de salida IA" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Validación de salida IA".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 145: FASE 7.15 - Fallback sin IA

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Fallback sin IA" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Fallback sin IA": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Fallback sin IA" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Fallback sin IA".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 146: FASE 7.16 - Comparación software vs psicólogo

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Comparación software vs psicólogo" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Comparación software vs psicólogo": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Comparación software vs psicólogo" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Comparación software vs psicólogo".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 147: FASE 7.17 - Matriz de confusión

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Matriz de confusión" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Matriz de confusión": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Matriz de confusión" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Matriz de confusión".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 148: FASE 7.18 - Alfa de Cronbach

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Alfa de Cronbach" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Alfa de Cronbach": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Alfa de Cronbach" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Alfa de Cronbach".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 149: FASE 7.19 - Sesgo y equidad

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Sesgo y equidad" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Sesgo y equidad": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Sesgo y equidad" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Sesgo y equidad".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 150: FASE 7.20 - Explicabilidad de recomendaciones

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Explicabilidad de recomendaciones" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Explicabilidad de recomendaciones": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Explicabilidad de recomendaciones" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Explicabilidad de recomendaciones".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 151: FASE 7.21 - Registro de prompts

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Registro de prompts" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Registro de prompts": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Registro de prompts" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Registro de prompts".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 152: FASE 7.22 - Evaluación de calidad IA

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Evaluación de calidad IA" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Evaluación de calidad IA": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Evaluación de calidad IA" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Evaluación de calidad IA".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 153: FASE 7.23 - Control de costos IA

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Control de costos IA" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Control de costos IA": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Control de costos IA" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Control de costos IA".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 154: FASE 7.24 - Privacidad en prompts

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Privacidad en prompts" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Privacidad en prompts": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Privacidad en prompts" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Privacidad en prompts".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 155: FASE 7.25 - Versionado del motor

**Fase:** Motor RIASEC, IA, prompts y recomendador vocacional  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Versionado del motor" dentro de motor riasec, ia, prompts y recomendador vocacional, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase desarrolla el corazón vocacional: test, cálculo RIASEC, recomendador, IA generativa, RAG, validación y explicabilidad.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Versionado del motor": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Versionado del motor" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Versionado del motor".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 156: FASE 8.01 - Estructura Flutter

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Estructura Flutter" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Estructura Flutter": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Estructura Flutter" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Estructura Flutter".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
class TestVocacionalPage extends ConsumerWidget {
  const TestVocacionalPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(testProvider);
    return Scaffold(body: TestStepper(state: state));
  }
}
```


<!-- pagebreak -->

## Página técnica 157: FASE 8.02 - Configuración de ambientes

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Configuración de ambientes" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Configuración de ambientes": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Configuración de ambientes" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Configuración de ambientes".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 158: FASE 8.03 - Tema visual

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Tema visual" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Tema visual": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Tema visual" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Tema visual".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 159: FASE 8.04 - Sistema de rutas

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Sistema de rutas" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Sistema de rutas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Sistema de rutas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Sistema de rutas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 160: FASE 8.05 - Estado con Riverpod

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Estado con Riverpod" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Estado con Riverpod": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Estado con Riverpod" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Estado con Riverpod".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 161: FASE 8.06 - Cliente HTTP Dio

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Cliente HTTP Dio" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Cliente HTTP Dio": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Cliente HTTP Dio" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Cliente HTTP Dio".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
class TestVocacionalPage extends ConsumerWidget {
  const TestVocacionalPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(testProvider);
    return Scaffold(body: TestStepper(state: state));
  }
}
```


<!-- pagebreak -->

## Página técnica 162: FASE 8.07 - Modelos Freezed

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Modelos Freezed" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Modelos Freezed": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Modelos Freezed" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Modelos Freezed".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 163: FASE 8.08 - Login

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Login" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Login": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Login" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Login".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 164: FASE 8.09 - Registro y recuperación

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Registro y recuperación" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Registro y recuperación": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Registro y recuperación" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Registro y recuperación".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 165: FASE 8.10 - Consentimiento

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Consentimiento" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Consentimiento": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Consentimiento" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Consentimiento".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 166: FASE 8.11 - Test paginado

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Test paginado" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Test paginado": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Test paginado" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Test paginado".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
class TestVocacionalPage extends ConsumerWidget {
  const TestVocacionalPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(testProvider);
    return Scaffold(body: TestStepper(state: state));
  }
}
```


<!-- pagebreak -->

## Página técnica 167: FASE 8.12 - Modo offline básico

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Modo offline básico" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Modo offline básico": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Modo offline básico" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Modo offline básico".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 168: FASE 8.13 - Sincronización

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Sincronización" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Sincronización": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Sincronización" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Sincronización".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 169: FASE 8.14 - Resultados RIASEC

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Resultados RIASEC" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Resultados RIASEC": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Resultados RIASEC" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Resultados RIASEC".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 170: FASE 8.15 - Vista de carreras

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Vista de carreras" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Vista de carreras": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Vista de carreras" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Vista de carreras".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 171: FASE 8.16 - Chat orientador

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Chat orientador" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Chat orientador": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Chat orientador" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Chat orientador".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
class TestVocacionalPage extends ConsumerWidget {
  const TestVocacionalPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(testProvider);
    return Scaffold(body: TestStepper(state: state));
  }
}
```


<!-- pagebreak -->

## Página técnica 172: FASE 8.17 - Descarga PDF

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Descarga PDF" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Descarga PDF": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Descarga PDF" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Descarga PDF".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 173: FASE 8.18 - Panel psicólogo

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Panel psicólogo" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Panel psicólogo": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Panel psicólogo" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Panel psicólogo".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 174: FASE 8.19 - Panel administrador

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Panel administrador" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Panel administrador": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Panel administrador" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Panel administrador".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 175: FASE 8.20 - Internacionalización

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Internacionalización" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Internacionalización": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Internacionalización" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Internacionalización".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 176: FASE 8.21 - Accesibilidad móvil

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Accesibilidad móvil" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Accesibilidad móvil": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Accesibilidad móvil" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Accesibilidad móvil".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
class TestVocacionalPage extends ConsumerWidget {
  const TestVocacionalPage({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(testProvider);
    return Scaffold(body: TestStepper(state: state));
  }
}
```


<!-- pagebreak -->

## Página técnica 177: FASE 8.22 - Pruebas widget

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Pruebas widget" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pruebas widget": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pruebas widget" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pruebas widget".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 178: FASE 8.23 - Build Android

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Build Android" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Build Android": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Build Android" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Build Android".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 179: FASE 8.24 - Build iOS

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Build iOS" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Build iOS": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Build iOS" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Build iOS".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 180: FASE 8.25 - Build Web

**Fase:** Frontend Flutter multiplataforma  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Build Web" dentro de frontend flutter multiplataforma, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase construye el cliente multiplataforma con Flutter, incluyendo pantallas, navegación, estado, consumo de API y builds.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Build Web": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Build Web" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Build Web".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 181: FASE 9.01 - Diseño del informe PDF

**Fase:** Reportes PDF, analítica, paneles y trazabilidad  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Diseño del informe PDF" dentro de reportes pdf, analítica, paneles y trazabilidad, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte los resultados en informes comprensibles, paneles de gestión, exportaciones y evidencia institucional.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Diseño del informe PDF": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Diseño del informe PDF" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Diseño del informe PDF".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 182: FASE 9.02 - Plantilla institucional

**Fase:** Reportes PDF, analítica, paneles y trazabilidad  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Plantilla institucional" dentro de reportes pdf, analítica, paneles y trazabilidad, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte los resultados en informes comprensibles, paneles de gestión, exportaciones y evidencia institucional.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Plantilla institucional": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Plantilla institucional" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Plantilla institucional".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 183: FASE 9.03 - Resumen ejecutivo del estudiante

**Fase:** Reportes PDF, analítica, paneles y trazabilidad  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Resumen ejecutivo del estudiante" dentro de reportes pdf, analítica, paneles y trazabilidad, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte los resultados en informes comprensibles, paneles de gestión, exportaciones y evidencia institucional.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Resumen ejecutivo del estudiante": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Resumen ejecutivo del estudiante" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Resumen ejecutivo del estudiante".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 184: FASE 9.04 - Perfil RIASEC en informe

**Fase:** Reportes PDF, analítica, paneles y trazabilidad  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Perfil RIASEC en informe" dentro de reportes pdf, analítica, paneles y trazabilidad, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte los resultados en informes comprensibles, paneles de gestión, exportaciones y evidencia institucional.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Perfil RIASEC en informe": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Perfil RIASEC en informe" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Perfil RIASEC en informe".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 185: FASE 9.05 - Carreras recomendadas

**Fase:** Reportes PDF, analítica, paneles y trazabilidad  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Carreras recomendadas" dentro de reportes pdf, analítica, paneles y trazabilidad, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte los resultados en informes comprensibles, paneles de gestión, exportaciones y evidencia institucional.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Carreras recomendadas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Carreras recomendadas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Carreras recomendadas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 186: FASE 9.06 - Plan de acción vocacional

**Fase:** Reportes PDF, analítica, paneles y trazabilidad  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Plan de acción vocacional" dentro de reportes pdf, analítica, paneles y trazabilidad, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte los resultados en informes comprensibles, paneles de gestión, exportaciones y evidencia institucional.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Plan de acción vocacional": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Plan de acción vocacional" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Plan de acción vocacional".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 187: FASE 9.07 - Firma/validación psicólogo

**Fase:** Reportes PDF, analítica, paneles y trazabilidad  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Firma/validación psicólogo" dentro de reportes pdf, analítica, paneles y trazabilidad, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte los resultados en informes comprensibles, paneles de gestión, exportaciones y evidencia institucional.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Firma/validación psicólogo": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Firma/validación psicólogo" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Firma/validación psicólogo".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 188: FASE 9.08 - Historial de reportes

**Fase:** Reportes PDF, analítica, paneles y trazabilidad  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Historial de reportes" dentro de reportes pdf, analítica, paneles y trazabilidad, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte los resultados en informes comprensibles, paneles de gestión, exportaciones y evidencia institucional.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Historial de reportes": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Historial de reportes" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Historial de reportes".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 189: FASE 9.09 - Analítica institucional

**Fase:** Reportes PDF, analítica, paneles y trazabilidad  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Analítica institucional" dentro de reportes pdf, analítica, paneles y trazabilidad, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte los resultados en informes comprensibles, paneles de gestión, exportaciones y evidencia institucional.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Analítica institucional": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Analítica institucional" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Analítica institucional".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 190: FASE 9.10 - Indicadores DECE

**Fase:** Reportes PDF, analítica, paneles y trazabilidad  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Indicadores DECE" dentro de reportes pdf, analítica, paneles y trazabilidad, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte los resultados en informes comprensibles, paneles de gestión, exportaciones y evidencia institucional.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Indicadores DECE": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Indicadores DECE" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Indicadores DECE".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 191: FASE 9.11 - Dashboard administrador

**Fase:** Reportes PDF, analítica, paneles y trazabilidad  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Dashboard administrador" dentro de reportes pdf, analítica, paneles y trazabilidad, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte los resultados en informes comprensibles, paneles de gestión, exportaciones y evidencia institucional.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Dashboard administrador": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Dashboard administrador" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Dashboard administrador".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 192: FASE 9.12 - Exportación CSV/Excel

**Fase:** Reportes PDF, analítica, paneles y trazabilidad  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Exportación CSV/Excel" dentro de reportes pdf, analítica, paneles y trazabilidad, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte los resultados en informes comprensibles, paneles de gestión, exportaciones y evidencia institucional.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Exportación CSV/Excel": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Exportación CSV/Excel" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Exportación CSV/Excel".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 193: FASE 9.13 - Trazabilidad de resultados

**Fase:** Reportes PDF, analítica, paneles y trazabilidad  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Trazabilidad de resultados" dentro de reportes pdf, analítica, paneles y trazabilidad, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte los resultados en informes comprensibles, paneles de gestión, exportaciones y evidencia institucional.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Trazabilidad de resultados": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Trazabilidad de resultados" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Trazabilidad de resultados".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 194: FASE 9.14 - Reimpresión y descarga

**Fase:** Reportes PDF, analítica, paneles y trazabilidad  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Reimpresión y descarga" dentro de reportes pdf, analítica, paneles y trazabilidad, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte los resultados en informes comprensibles, paneles de gestión, exportaciones y evidencia institucional.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Reimpresión y descarga": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Reimpresión y descarga" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Reimpresión y descarga".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 195: FASE 9.15 - Gobierno de reportes

**Fase:** Reportes PDF, analítica, paneles y trazabilidad  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Gobierno de reportes" dentro de reportes pdf, analítica, paneles y trazabilidad, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase convierte los resultados en informes comprensibles, paneles de gestión, exportaciones y evidencia institucional.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Gobierno de reportes": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Gobierno de reportes" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Gobierno de reportes".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 196: FASE 10.01 - Modelo de amenazas

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Modelo de amenazas" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Modelo de amenazas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Modelo de amenazas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Modelo de amenazas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 197: FASE 10.02 - Datos sensibles

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Datos sensibles" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Datos sensibles": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Datos sensibles" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Datos sensibles".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 198: FASE 10.03 - Consentimiento informado

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Consentimiento informado" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Consentimiento informado": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Consentimiento informado" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Consentimiento informado".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 199: FASE 10.04 - Política de privacidad

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Política de privacidad" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Política de privacidad": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Política de privacidad" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Política de privacidad".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 200: FASE 10.05 - Cifrado TLS

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Cifrado TLS" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Cifrado TLS": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Cifrado TLS" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Cifrado TLS".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 201: FASE 10.06 - Hash de contraseñas

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Hash de contraseñas" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Hash de contraseñas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Hash de contraseñas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Hash de contraseñas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 202: FASE 10.07 - Control de acceso RBAC

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Control de acceso RBAC" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Control de acceso RBAC": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Control de acceso RBAC" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Control de acceso RBAC".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 203: FASE 10.08 - Protección de API

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Protección de API" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Protección de API": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Protección de API" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Protección de API".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 204: FASE 10.09 - Protección de prompts

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Protección de prompts" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Protección de prompts": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Protección de prompts" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Protección de prompts".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 205: FASE 10.10 - Logs sin datos sensibles

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Logs sin datos sensibles" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Logs sin datos sensibles": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Logs sin datos sensibles" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Logs sin datos sensibles".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 206: FASE 10.11 - Auditoría

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Auditoría" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Auditoría": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Auditoría" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Auditoría".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 207: FASE 10.12 - Backups seguros

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Backups seguros" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Backups seguros": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Backups seguros" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Backups seguros".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 208: FASE 10.13 - Retención de datos

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Retención de datos" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Retención de datos": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Retención de datos" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Retención de datos".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 209: FASE 10.14 - Anonimización

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Anonimización" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Anonimización": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Anonimización" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Anonimización".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 210: FASE 10.15 - Seguridad móvil

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Seguridad móvil" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Seguridad móvil": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Seguridad móvil" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Seguridad móvil".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 211: FASE 10.16 - Seguridad web

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Seguridad web" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Seguridad web": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Seguridad web" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Seguridad web".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 212: FASE 10.17 - OWASP ASVS

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "OWASP ASVS" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "OWASP ASVS": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "OWASP ASVS" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "OWASP ASVS".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 213: FASE 10.18 - Pruebas SAST/DAST

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Pruebas SAST/DAST" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pruebas SAST/DAST": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pruebas SAST/DAST" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pruebas SAST/DAST".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 214: FASE 10.19 - Respuesta a incidentes

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Respuesta a incidentes" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Respuesta a incidentes": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Respuesta a incidentes" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Respuesta a incidentes".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 215: FASE 10.20 - Ética de IA

**Fase:** Seguridad, privacidad, ética y cumplimiento  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Ética de IA" dentro de seguridad, privacidad, ética y cumplimiento, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase protege a estudiantes, instituciones y datos sensibles mediante controles de seguridad, privacidad y ética de IA.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Ética de IA": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Ética de IA" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Ética de IA".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 216: FASE 11.01 - Estrategia QA

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Estrategia QA" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Estrategia QA": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Estrategia QA" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Estrategia QA".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 217: FASE 11.02 - Plan de pruebas

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Plan de pruebas" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Plan de pruebas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Plan de pruebas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Plan de pruebas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 218: FASE 11.03 - Casos de prueba estudiante

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Casos de prueba estudiante" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Casos de prueba estudiante": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Casos de prueba estudiante" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Casos de prueba estudiante".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 219: FASE 11.04 - Casos de prueba psicólogo

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Casos de prueba psicólogo" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Casos de prueba psicólogo": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Casos de prueba psicólogo" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Casos de prueba psicólogo".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 220: FASE 11.05 - Casos de prueba administrador

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Casos de prueba administrador" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Casos de prueba administrador": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Casos de prueba administrador" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Casos de prueba administrador".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 221: FASE 11.06 - Pruebas unitarias

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Pruebas unitarias" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pruebas unitarias": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pruebas unitarias" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pruebas unitarias".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 222: FASE 11.07 - Pruebas integración

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Pruebas integración" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pruebas integración": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pruebas integración" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pruebas integración".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 223: FASE 11.08 - Pruebas E2E

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Pruebas E2E" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pruebas E2E": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pruebas E2E" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pruebas E2E".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 224: FASE 11.09 - Pruebas usabilidad

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Pruebas usabilidad" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pruebas usabilidad": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pruebas usabilidad" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pruebas usabilidad".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 225: FASE 11.10 - Pruebas accesibilidad

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Pruebas accesibilidad" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pruebas accesibilidad": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pruebas accesibilidad" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pruebas accesibilidad".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 226: FASE 11.11 - Pruebas rendimiento

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Pruebas rendimiento" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pruebas rendimiento": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pruebas rendimiento" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pruebas rendimiento".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 227: FASE 11.12 - Pruebas seguridad

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Pruebas seguridad" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pruebas seguridad": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pruebas seguridad" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pruebas seguridad".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 228: FASE 11.13 - Pruebas offline

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Pruebas offline" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Pruebas offline": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Pruebas offline" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Pruebas offline".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 229: FASE 11.14 - Validación psicológica

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Validación psicológica" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Validación psicológica": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Validación psicológica" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Validación psicológica".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 230: FASE 11.15 - Validación estadística

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Validación estadística" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Validación estadística": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Validación estadística" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Validación estadística".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 231: FASE 11.16 - Encuesta de satisfacción

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Encuesta de satisfacción" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Encuesta de satisfacción": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Encuesta de satisfacción" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Encuesta de satisfacción".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 232: FASE 11.17 - Modelo DeLone y McLean

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Modelo DeLone y McLean" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Modelo DeLone y McLean": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Modelo DeLone y McLean" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Modelo DeLone y McLean".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 233: FASE 11.18 - Informe de defectos

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Informe de defectos" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Informe de defectos": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Informe de defectos" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Informe de defectos".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 234: FASE 11.19 - Cierre QA

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Cierre QA" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Cierre QA": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Cierre QA" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Cierre QA".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 235: FASE 11.20 - Aprobación UAT

**Fase:** Pruebas QA, validación psicológica y evaluación estadística  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Aprobación UAT" dentro de pruebas qa, validación psicológica y evaluación estadística, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase valida que el sistema funcione correctamente, sea usable, sea seguro y emita recomendaciones confiables.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Aprobación UAT": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Aprobación UAT" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Aprobación UAT".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 236: FASE 12.01 - Repositorios Git

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Repositorios Git" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Repositorios Git": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Repositorios Git" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Repositorios Git".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 237: FASE 12.02 - Estrategia de ramas

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Estrategia de ramas" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Estrategia de ramas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Estrategia de ramas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Estrategia de ramas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 238: FASE 12.03 - Dockerfile backend

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Dockerfile backend" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Dockerfile backend": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Dockerfile backend" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Dockerfile backend".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 239: FASE 12.04 - Dockerfile frontend web

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Dockerfile frontend web" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Dockerfile frontend web": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Dockerfile frontend web" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Dockerfile frontend web".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 240: FASE 12.05 - docker-compose local

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "docker-compose local" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "docker-compose local": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "docker-compose local" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "docker-compose local".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 241: FASE 12.06 - Base de datos producción

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Base de datos producción" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Base de datos producción": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Base de datos producción" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Base de datos producción".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 242: FASE 12.07 - Nginx reverse proxy

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Nginx reverse proxy" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Nginx reverse proxy": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Nginx reverse proxy" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Nginx reverse proxy".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 243: FASE 12.08 - TLS Let’s Encrypt

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "TLS Let’s Encrypt" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "TLS Let’s Encrypt": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "TLS Let’s Encrypt" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "TLS Let’s Encrypt".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 244: FASE 12.09 - GitHub Actions

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "GitHub Actions" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "GitHub Actions": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "GitHub Actions" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "GitHub Actions".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 245: FASE 12.10 - CI pruebas

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "CI pruebas" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "CI pruebas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "CI pruebas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "CI pruebas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 246: FASE 12.11 - CD staging

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "CD staging" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "CD staging": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "CD staging" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "CD staging".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 247: FASE 12.12 - CD producción

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "CD producción" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "CD producción": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "CD producción" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "CD producción".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 248: FASE 12.13 - Variables secretas

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Variables secretas" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Variables secretas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Variables secretas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Variables secretas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 249: FASE 12.14 - Migraciones producción

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Migraciones producción" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Migraciones producción": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Migraciones producción" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Migraciones producción".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 250: FASE 12.15 - Monitoreo inicial

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Monitoreo inicial" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Monitoreo inicial": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Monitoreo inicial" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Monitoreo inicial".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 251: FASE 12.16 - Logs centralizados

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Logs centralizados" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Logs centralizados": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Logs centralizados" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Logs centralizados".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 252: FASE 12.17 - Backups automáticos

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Backups automáticos" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Backups automáticos": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Backups automáticos" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Backups automáticos".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 253: FASE 12.18 - Plan rollback

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Plan rollback" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Plan rollback": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Plan rollback" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Plan rollback".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 254: FASE 12.19 - Publicación Android

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Publicación Android" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Publicación Android": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Publicación Android" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Publicación Android".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 255: FASE 12.20 - Publicación Web

**Fase:** DevOps, infraestructura, CI/CD y publicación  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Publicación Web" dentro de devops, infraestructura, ci/cd y publicación, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase prepara infraestructura, automatización, despliegue y publicación hasta ambientes productivos.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Publicación Web": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Publicación Web" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Publicación Web".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 256: FASE 13.01 - Go-live

**Fase:** Producción, soporte, monitoreo y mejora continua  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Go-live" dentro de producción, soporte, monitoreo y mejora continua, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase controla la salida a producción, soporte, monitoreo, mejora continua y crecimiento posterior del producto.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Go-live": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Go-live" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Go-live".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 257: FASE 13.02 - Checklist producción

**Fase:** Producción, soporte, monitoreo y mejora continua  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Checklist producción" dentro de producción, soporte, monitoreo y mejora continua, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase controla la salida a producción, soporte, monitoreo, mejora continua y crecimiento posterior del producto.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Checklist producción": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Checklist producción" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Checklist producción".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 258: FASE 13.03 - Mesa de ayuda

**Fase:** Producción, soporte, monitoreo y mejora continua  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Mesa de ayuda" dentro de producción, soporte, monitoreo y mejora continua, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase controla la salida a producción, soporte, monitoreo, mejora continua y crecimiento posterior del producto.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Mesa de ayuda": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Mesa de ayuda" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Mesa de ayuda".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 259: FASE 13.04 - SLA soporte

**Fase:** Producción, soporte, monitoreo y mejora continua  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "SLA soporte" dentro de producción, soporte, monitoreo y mejora continua, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase controla la salida a producción, soporte, monitoreo, mejora continua y crecimiento posterior del producto.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "SLA soporte": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "SLA soporte" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "SLA soporte".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 260: FASE 13.05 - Monitoreo de costos

**Fase:** Producción, soporte, monitoreo y mejora continua  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Monitoreo de costos" dentro de producción, soporte, monitoreo y mejora continua, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase controla la salida a producción, soporte, monitoreo, mejora continua y crecimiento posterior del producto.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Monitoreo de costos": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Monitoreo de costos" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Monitoreo de costos".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 261: FASE 13.06 - Mantenimiento preventivo

**Fase:** Producción, soporte, monitoreo y mejora continua  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Mantenimiento preventivo" dentro de producción, soporte, monitoreo y mejora continua, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase controla la salida a producción, soporte, monitoreo, mejora continua y crecimiento posterior del producto.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Mantenimiento preventivo": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Mantenimiento preventivo" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Mantenimiento preventivo".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 262: FASE 13.07 - Actualización catálogo

**Fase:** Producción, soporte, monitoreo y mejora continua  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Actualización catálogo" dentro de producción, soporte, monitoreo y mejora continua, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase controla la salida a producción, soporte, monitoreo, mejora continua y crecimiento posterior del producto.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Actualización catálogo": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Actualización catálogo" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Actualización catálogo".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 263: FASE 13.08 - Actualización preguntas

**Fase:** Producción, soporte, monitoreo y mejora continua  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Actualización preguntas" dentro de producción, soporte, monitoreo y mejora continua, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase controla la salida a producción, soporte, monitoreo, mejora continua y crecimiento posterior del producto.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Actualización preguntas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Actualización preguntas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Actualización preguntas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 264: FASE 13.09 - Capacitación DECE

**Fase:** Producción, soporte, monitoreo y mejora continua  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Capacitación DECE" dentro de producción, soporte, monitoreo y mejora continua, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase controla la salida a producción, soporte, monitoreo, mejora continua y crecimiento posterior del producto.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Capacitación DECE": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Capacitación DECE" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Capacitación DECE".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 265: FASE 13.10 - Capacitación estudiantes

**Fase:** Producción, soporte, monitoreo y mejora continua  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Capacitación estudiantes" dentro de producción, soporte, monitoreo y mejora continua, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase controla la salida a producción, soporte, monitoreo, mejora continua y crecimiento posterior del producto.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Capacitación estudiantes": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Capacitación estudiantes" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Capacitación estudiantes".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 266: FASE 13.11 - Manual usuario

**Fase:** Producción, soporte, monitoreo y mejora continua  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Manual usuario" dentro de producción, soporte, monitoreo y mejora continua, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase controla la salida a producción, soporte, monitoreo, mejora continua y crecimiento posterior del producto.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Manual usuario": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Manual usuario" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Manual usuario".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 267: FASE 13.12 - Manual técnico

**Fase:** Producción, soporte, monitoreo y mejora continua  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Manual técnico" dentro de producción, soporte, monitoreo y mejora continua, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase controla la salida a producción, soporte, monitoreo, mejora continua y crecimiento posterior del producto.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Manual técnico": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Manual técnico" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Manual técnico".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 268: FASE 13.13 - Roadmap MVP

**Fase:** Producción, soporte, monitoreo y mejora continua  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Roadmap MVP" dentro de producción, soporte, monitoreo y mejora continua, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase controla la salida a producción, soporte, monitoreo, mejora continua y crecimiento posterior del producto.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Roadmap MVP": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Roadmap MVP" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Roadmap MVP".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 269: FASE 13.14 - Roadmap versión 2

**Fase:** Producción, soporte, monitoreo y mejora continua  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Roadmap versión 2" dentro de producción, soporte, monitoreo y mejora continua, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase controla la salida a producción, soporte, monitoreo, mejora continua y crecimiento posterior del producto.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Roadmap versión 2": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Roadmap versión 2" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Roadmap versión 2".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 270: FASE 13.15 - Cierre del proyecto

**Fase:** Producción, soporte, monitoreo y mejora continua  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Cierre del proyecto" dentro de producción, soporte, monitoreo y mejora continua, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Esta fase controla la salida a producción, soporte, monitoreo, mejora continua y crecimiento posterior del producto.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Cierre del proyecto": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Cierre del proyecto" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Cierre del proyecto".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 271: ANEXOS.01 - Estructura de carpetas backend

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Estructura de carpetas backend" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Estructura de carpetas backend": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Estructura de carpetas backend" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Estructura de carpetas backend".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 272: ANEXOS.02 - Estructura de carpetas frontend

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Estructura de carpetas frontend" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Estructura de carpetas frontend": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Estructura de carpetas frontend" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Estructura de carpetas frontend".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 273: ANEXOS.03 - Ejemplo .env backend

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Ejemplo .env backend" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Ejemplo .env backend": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Ejemplo .env backend" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Ejemplo .env backend".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 274: ANEXOS.04 - Ejemplo docker-compose

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Ejemplo docker-compose" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Ejemplo docker-compose": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Ejemplo docker-compose" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Ejemplo docker-compose".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 275: ANEXOS.05 - SQL base instituciones

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "SQL base instituciones" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "SQL base instituciones": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "SQL base instituciones" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "SQL base instituciones".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 276: ANEXOS.06 - SQL base usuarios

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "SQL base usuarios" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "SQL base usuarios": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "SQL base usuarios" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "SQL base usuarios".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 277: ANEXOS.07 - SQL preguntas IPPJ

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "SQL preguntas IPPJ" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "SQL preguntas IPPJ": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "SQL preguntas IPPJ" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "SQL preguntas IPPJ".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 278: ANEXOS.08 - SQL carreras

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "SQL carreras" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "SQL carreras": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "SQL carreras" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "SQL carreras".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 279: ANEXOS.09 - Contrato API auth

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Contrato API auth" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Contrato API auth": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Contrato API auth" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Contrato API auth".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 280: ANEXOS.10 - Contrato API estudiantes

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Contrato API estudiantes" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Contrato API estudiantes": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Contrato API estudiantes" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Contrato API estudiantes".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 281: ANEXOS.11 - Contrato API test

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Contrato API test" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Contrato API test": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Contrato API test" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Contrato API test".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 282: ANEXOS.12 - Contrato API recomendaciones

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Contrato API recomendaciones" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Contrato API recomendaciones": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Contrato API recomendaciones" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Contrato API recomendaciones".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 283: ANEXOS.13 - Contrato API reportes

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Contrato API reportes" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Contrato API reportes": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Contrato API reportes" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Contrato API reportes".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 284: ANEXOS.14 - Contrato API admin

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Contrato API admin" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Contrato API admin": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Contrato API admin" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Contrato API admin".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 285: ANEXOS.15 - OpenAPI mínimo

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "OpenAPI mínimo" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "OpenAPI mínimo": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "OpenAPI mínimo" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "OpenAPI mínimo".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 286: ANEXOS.16 - Prompt maestro DeepSeek

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Administrador Institucional

### Objetivo
Proporcionar una plantilla reutilizable de prompt para generar código, validar recomendaciones o construir documentación técnica sin perder control del alcance.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Prompt maestro DeepSeek": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Prompt maestro DeepSeek" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Prompt maestro DeepSeek".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
Actúa como arquitecto senior. Construye únicamente el módulo solicitado.
Contexto: OrientaVoc AI 360, Flutter + FastAPI + MySQL + Qdrant.
Entrega: archivos completos, rutas, comandos, pruebas y explicación.
Restricción: no inventes tablas; usa el modelo de datos del expediente.
```


<!-- pagebreak -->

## Página técnica 287: ANEXOS.17 - Prompt guardrail

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Administrador SaaS

### Objetivo
Proporcionar una plantilla reutilizable de prompt para generar código, validar recomendaciones o construir documentación técnica sin perder control del alcance.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Prompt guardrail": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Prompt guardrail" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Prompt guardrail".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
Actúa como arquitecto senior. Construye únicamente el módulo solicitado.
Contexto: OrientaVoc AI 360, Flutter + FastAPI + MySQL + Qdrant.
Entrega: archivos completos, rutas, comandos, pruebas y explicación.
Restricción: no inventes tablas; usa el modelo de datos del expediente.
```


<!-- pagebreak -->

## Página técnica 288: ANEXOS.18 - Prompt informe PDF

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Soporte Técnico

### Objetivo
Proporcionar una plantilla reutilizable de prompt para generar código, validar recomendaciones o construir documentación técnica sin perder control del alcance.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Prompt informe PDF": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Prompt informe PDF" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Prompt informe PDF".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
Actúa como arquitecto senior. Construye únicamente el módulo solicitado.
Contexto: OrientaVoc AI 360, Flutter + FastAPI + MySQL + Qdrant.
Entrega: archivos completos, rutas, comandos, pruebas y explicación.
Restricción: no inventes tablas; usa el modelo de datos del expediente.
```


<!-- pagebreak -->

## Página técnica 289: ANEXOS.19 - Prompt para Cursor 1

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Estudiante

### Objetivo
Proporcionar una plantilla reutilizable de prompt para generar código, validar recomendaciones o construir documentación técnica sin perder control del alcance.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Prompt para Cursor 1": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Prompt para Cursor 1" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Prompt para Cursor 1".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
Actúa como arquitecto senior. Construye únicamente el módulo solicitado.
Contexto: OrientaVoc AI 360, Flutter + FastAPI + MySQL + Qdrant.
Entrega: archivos completos, rutas, comandos, pruebas y explicación.
Restricción: no inventes tablas; usa el modelo de datos del expediente.
```


<!-- pagebreak -->

## Página técnica 290: ANEXOS.20 - Prompt para Cursor 2

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Representante/Familia

### Objetivo
Proporcionar una plantilla reutilizable de prompt para generar código, validar recomendaciones o construir documentación técnica sin perder control del alcance.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Prompt para Cursor 2": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Prompt para Cursor 2" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Prompt para Cursor 2".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

```text
Actúa como arquitecto senior. Construye únicamente el módulo solicitado.
Contexto: OrientaVoc AI 360, Flutter + FastAPI + MySQL + Qdrant.
Entrega: archivos completos, rutas, comandos, pruebas y explicación.
Restricción: no inventes tablas; usa el modelo de datos del expediente.
```


<!-- pagebreak -->

## Página técnica 291: ANEXOS.21 - Reglas para Cursor

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Reglas para Cursor" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Reglas para Cursor": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Reglas para Cursor" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Reglas para Cursor".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 292: ANEXOS.22 - Checklist sprint 0

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Checklist sprint 0" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Checklist sprint 0": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Checklist sprint 0" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Checklist sprint 0".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 293: ANEXOS.23 - Checklist sprint 1

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Checklist sprint 1" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Checklist sprint 1": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Checklist sprint 1" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Checklist sprint 1".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 294: ANEXOS.24 - Checklist sprint 2

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Checklist sprint 2" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Checklist sprint 2": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Checklist sprint 2" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Checklist sprint 2".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 295: ANEXOS.25 - Checklist sprint 3

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Checklist sprint 3" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Checklist sprint 3": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Checklist sprint 3" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Checklist sprint 3".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 296: ANEXOS.26 - Checklist seguridad

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Checklist seguridad" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Checklist seguridad": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Checklist seguridad" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Checklist seguridad".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 297: ANEXOS.27 - Checklist producción

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Checklist producción" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Checklist producción": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Checklist producción" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Checklist producción".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 298: ANEXOS.28 - Matriz roles-permisos

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Matriz roles-permisos" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Matriz roles-permisos": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Matriz roles-permisos" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Matriz roles-permisos".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 299: ANEXOS.29 - Matriz historias-pruebas

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Matriz historias-pruebas" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Matriz historias-pruebas": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Matriz historias-pruebas" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Matriz historias-pruebas".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 300: ANEXOS.30 - Casos de uso completos

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Casos de uso completos" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Casos de uso completos": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Casos de uso completos" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Casos de uso completos".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 301: ANEXOS.31 - Plantilla acta reunión

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Plantilla acta reunión" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Plantilla acta reunión": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Plantilla acta reunión" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Plantilla acta reunión".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 302: ANEXOS.32 - Plantilla validación psicólogo

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Plantilla validación psicólogo" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Plantilla validación psicólogo": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Plantilla validación psicólogo" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Plantilla validación psicólogo".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 303: ANEXOS.33 - Plantilla consentimiento

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Plantilla consentimiento" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Plantilla consentimiento": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Plantilla consentimiento" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Plantilla consentimiento".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 304: ANEXOS.34 - Plantilla encuesta satisfacción

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Plantilla encuesta satisfacción" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Plantilla encuesta satisfacción": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Plantilla encuesta satisfacción" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Plantilla encuesta satisfacción".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 305: ANEXOS.35 - Plan de capacitación

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Administrador SaaS

### Objetivo
Definir y ejecutar el componente "Plan de capacitación" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Plan de capacitación": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Plan de capacitación" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Plan de capacitación".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 306: ANEXOS.36 - Plan de costos Ecuador

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Soporte Técnico

### Objetivo
Definir y ejecutar el componente "Plan de costos Ecuador" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Plan de costos Ecuador": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Plan de costos Ecuador" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Plan de costos Ecuador".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 307: ANEXOS.37 - Plan escalabilidad SaaS

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Estudiante

### Objetivo
Definir y ejecutar el componente "Plan escalabilidad SaaS" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Plan escalabilidad SaaS": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Plan escalabilidad SaaS" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Plan escalabilidad SaaS".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 308: ANEXOS.38 - Plan legal básico

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Representante/Familia

### Objetivo
Definir y ejecutar el componente "Plan legal básico" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Plan legal básico": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Plan legal básico" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Plan legal básico".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 309: ANEXOS.39 - Plan de backups

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Psicólogo/DECE

### Objetivo
Definir y ejecutar el componente "Plan de backups" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Plan de backups": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Plan de backups" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Plan de backups".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

## Página técnica 310: ANEXOS.40 - Plan de continuidad

**Fase:** Plantillas técnicas, endpoints, SQL, checklists y prompts para Cursor  
**Rol principal:** Administrador Institucional

### Objetivo
Definir y ejecutar el componente "Plan de continuidad" dentro de plantillas técnicas, endpoints, sql, checklists y prompts para cursor, asegurando que OrientaVoc AI 360 pueda construirse de forma ordenada, medible y preparada para producción.

### Contexto
Los anexos contienen plantillas prácticas para copiar, adaptar y ejecutar durante la implementación real.

### Procedimiento paso a paso

1. Identificar entradas requeridas para "Plan de continuidad": usuarios, reglas, datos, restricciones, riesgos y dependencias técnicas.
2. Documentar el flujo principal y los flujos alternos usando lenguaje simple, orientado a estudiantes, DECE y administradores.
3. Definir campos, pantallas, endpoints o servicios que intervienen en "Plan de continuidad" y relacionarlos con la base de datos.
4. Establecer criterios de aceptación verificables: qué debe ocurrir, qué no debe ocurrir y cómo se comprobará.
5. Registrar riesgos de seguridad, privacidad, sesgo, pérdida de información y errores de recomendación vocacional.
6. Crear una tarea en el tablero Scrum con responsable, estimación, evidencia esperada y definición de terminado.
7. Probar el resultado en ambiente local, luego en staging, y solo después habilitarlo para producción.

### Entregables

- Documento o artefacto técnico aprobado para "Plan de continuidad".
- Historia de usuario o tarea técnica vinculada al backlog.
- Evidencia de prueba: captura, registro, reporte, endpoint probado o resultado validado.
- Criterios de aceptación marcados como cumplidos por QA o responsable funcional.

### Criterios de aceptación

- El componente se entiende sin depender de explicaciones verbales.
- La solución es trazable desde requisito hasta prueba.
- No se expone información sensible en logs, prompts ni respuestas públicas.
- El resultado puede mantenerse por otro desarrollador sin reescribirlo desde cero.

### Riesgos y controles

- Ambigüedad funcional: resolver con prototipo y revisión con usuarios.
- Sobrecosto técnico: priorizar MVP y diferir mejoras no críticas.
- Error de IA: aplicar guardrails, catálogo cerrado y validación profesional.
- Datos incompletos: usar migraciones, semillas y controles de integridad.

<!-- pagebreak -->

# ANEXO TÉCNICO v1.2 - Implementación real del stack Flutter + FastAPI + MySQL + Qdrant + Redis + Docker + DeepSeek API

Este anexo actualiza el expediente reemplazando PostgreSQL/pgvector por Qdrant. La regla principal es separar responsabilidades: MySQL guarda toda la operación del negocio y Qdrant resuelve búsquedas vectoriales, similitud semántica y RAG vocacional. phpMyAdmin queda como herramienta visual para administrar MySQL, no como base de datos.

## Matriz de responsabilidades

| Componente | Responsabilidad | No debe hacer |
|---|---|---|
| MySQL 8 | Usuarios, roles, instituciones, estudiantes, sesiones de test, respuestas, resultados, reportes, auditoría, consentimiento, configuración y catálogo maestro de carreras. | No debe usarse como motor vectorial principal ni guardar lógica IA crítica. |
| phpMyAdmin | Administración visual de MySQL en desarrollo, soporte, revisión de tablas, consultas manuales y verificación de datos. | No debe exponerse públicamente sin VPN, autenticación fuerte o restricción por IP. |
| Qdrant | Embeddings de carreras, perfiles RIASEC enriquecidos, documentos vocacionales, búsqueda semántica, filtros por metadatos y recuperación RAG. | No debe ser la fuente principal de usuarios, contraseñas, pagos, auditoría ni transacciones críticas. |
| Redis | Caché, rate limit, colas, locks, estado temporal de generación PDF, reintentos de sincronización y procesamiento IA. | No debe ser almacenamiento permanente ni reemplazar MySQL. |
| FastAPI | Orquestar API, reglas de negocio, transacciones MySQL, sincronización MySQL -> Qdrant, consumo DeepSeek y generación de PDF. | No debe exponer claves, prompts internos ni lógica sensible al frontend. |
| Flutter | Interfaz Android, iOS, Web, Windows, macOS y Linux, consumo de API, modo offline controlado y visualización de resultados. | No debe calcular recomendaciones finales sin validación backend. |

## Docker Compose base actualizado

```yaml
version: "3.9"
services:
  mysql:
    image: mysql:8.4
    container_name: avov_mysql
    environment:
      MYSQL_ROOT_PASSWORD: root_secret
      MYSQL_DATABASE: avov_core
      MYSQL_USER: avov_user
      MYSQL_PASSWORD: avov_pass
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./infra/mysql/init:/docker-entrypoint-initdb.d

  phpmyadmin:
    image: phpmyadmin:latest
    container_name: avov_phpmyadmin
    environment:
      PMA_HOST: mysql
      PMA_PORT: 3306
      UPLOAD_LIMIT: 128M
    ports:
      - "8081:80"
    depends_on:
      - mysql

  qdrant:
    image: qdrant/qdrant:latest
    container_name: avov_qdrant
    ports:
      - "6333:6333"
      - "6334:6334"
    volumes:
      - qdrant_data:/qdrant/storage

  redis:
    image: redis:7-alpine
    container_name: avov_redis
    ports:
      - "6379:6379"
    command: ["redis-server", "--appendonly", "yes"]
    volumes:
      - redis_data:/data

  api:
    build: ./backend
    container_name: avov_api
    env_file:
      - ./backend/.env
    ports:
      - "8000:8000"
    depends_on:
      - mysql
      - qdrant
      - redis

volumes:
  mysql_data:
  qdrant_data:
  redis_data:
```

## Variables de entorno backend actualizadas

```env
APP_NAME=OrientaVoc AI 360
APP_ENV=local
APP_DEBUG=true

MYSQL_HOST=mysql
MYSQL_PORT=3306
MYSQL_DATABASE=avov_core
MYSQL_USER=avov_user
MYSQL_PASSWORD=avov_pass
MYSQL_URL=mysql+aiomysql://avov_user:avov_pass@mysql:3306/avov_core

QDRANT_HOST=qdrant
QDRANT_PORT=6333
QDRANT_URL=http://qdrant:6333
QDRANT_API_KEY=
QDRANT_COLLECTION_CAREERS=careers_vectors
QDRANT_COLLECTION_DOCUMENTS=vocational_documents
QDRANT_VECTOR_SIZE=1536
QDRANT_DISTANCE=COSINE

REDIS_URL=redis://redis:6379/0
DEEPSEEK_API_KEY=colocar_clave_segura
DEEPSEEK_BASE_URL=https://api.deepseek.com
JWT_SECRET=colocar_secreto_largo
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
```

## DDL mínimo MySQL: núcleo transaccional

```sql
CREATE TABLE institutions (
  id CHAR(36) PRIMARY KEY,
  name VARCHAR(180) NOT NULL,
  city VARCHAR(120),
  province VARCHAR(120),
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE users (
  id CHAR(36) PRIMARY KEY,
  institution_id CHAR(36) NULL,
  full_name VARCHAR(180) NOT NULL,
  email VARCHAR(180) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (institution_id) REFERENCES institutions(id)
);

CREATE TABLE careers (
  id CHAR(36) PRIMARY KEY,
  name VARCHAR(220) NOT NULL,
  area VARCHAR(120) NOT NULL,
  level VARCHAR(80) NOT NULL,
  riasec_code VARCHAR(10) NOT NULL,
  description TEXT,
  status VARCHAR(30) NOT NULL DEFAULT 'active',
  qdrant_synced TINYINT(1) NOT NULL DEFAULT 0,
  updated_at TIMESTAMP NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE test_sessions (
  id CHAR(36) PRIMARY KEY,
  institution_id CHAR(36) NOT NULL,
  student_user_id CHAR(36) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'started',
  riasec_result_json JSON NULL,
  recommendation_status VARCHAR(30) DEFAULT 'pending',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  finished_at TIMESTAMP NULL,
  FOREIGN KEY (institution_id) REFERENCES institutions(id),
  FOREIGN KEY (student_user_id) REFERENCES users(id)
);

CREATE TABLE test_answers (
  id CHAR(36) PRIMARY KEY,
  session_id CHAR(36) NOT NULL,
  question_code VARCHAR(30) NOT NULL,
  riasec_dimension CHAR(1) NOT NULL,
  answer_value INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (session_id) REFERENCES test_sessions(id)
);
```

## Creación de colecciones Qdrant

```python
from qdrant_client import QdrantClient
from qdrant_client.models import Distance, VectorParams, PayloadSchemaType

client = QdrantClient(url="http://qdrant:6333")

client.recreate_collection(
    collection_name="careers_vectors",
    vectors_config=VectorParams(size=1536, distance=Distance.COSINE),
)

client.create_payload_index(
    collection_name="careers_vectors",
    field_name="riasec_code",
    field_schema=PayloadSchemaType.KEYWORD,
)
client.create_payload_index(
    collection_name="careers_vectors",
    field_name="area",
    field_schema=PayloadSchemaType.KEYWORD,
)
client.create_payload_index(
    collection_name="careers_vectors",
    field_name="level",
    field_schema=PayloadSchemaType.KEYWORD,
)

client.recreate_collection(
    collection_name="vocational_documents",
    vectors_config=VectorParams(size=1536, distance=Distance.COSINE),
)
```

## Flujo de sincronización MySQL -> Qdrant

1. Registrar o actualizar carrera en MySQL.
2. Crear evento de sincronización en Redis.
3. FastAPI Worker lee el evento y genera texto normalizado.
4. El servicio de embeddings convierte el texto a vector.
5. Se inserta o actualiza el punto vectorial en Qdrant.
6. El recomendador consulta Qdrant y obtiene IDs de carreras similares.
7. FastAPI valida esos IDs contra MySQL antes de generar respuesta.
8. DeepSeek redacta explicación usando solo carreras validadas.

```python
async def sync_career_to_qdrant(career_id: str):
    career = await mysql_repo.get_career(career_id)
    text = build_embedding_text(
        name=career.name,
        area=career.area,
        level=career.level,
        riasec_code=career.riasec_code,
        description=career.description,
    )
    embedding = await embedding_provider.embed(text)
    await qdrant_client.upsert(
        collection_name="careers_vectors",
        points=[{
            "id": career.id,
            "vector": embedding,
            "payload": {
                "mysql_career_id": career.id,
                "name": career.name,
                "area": career.area,
                "level": career.level,
                "riasec_code": career.riasec_code,
                "status": career.status,
            }
        }]
    )
    await mysql_repo.mark_career_as_synced(career.id)

async def recommend_by_profile(profile_embedding, riasec_code: str):
    hits = await qdrant_client.search(
        collection_name="careers_vectors",
        query_vector=profile_embedding,
        query_filter={"must": [{"key": "riasec_code", "match": {"value": riasec_code}}]},
        limit=10,
    )
    ids = [hit.payload["mysql_career_id"] for hit in hits]
    return await mysql_repo.get_active_careers_by_ids(ids)
```

## Criterios de producción con Qdrant

- Si Qdrant falla, el sistema debe seguir permitiendo login, administración, test y consulta de resultados históricos.
- Si MySQL falla, el sistema no debe aceptar nuevas respuestas ni generar recomendaciones porque se pierde la fuente de verdad.
- Cada recomendación debe guardar sesión, perfil RIASEC, carreras candidatas, prompt usado, versión del motor IA, fecha, usuario y resultado final.
- Los vectores en Qdrant son reconstruibles: nunca deben ser el único lugar donde exista una carrera o dato legalmente relevante.
- phpMyAdmin no debe publicarse abierto a internet; en producción se recomienda deshabilitarlo o restringirlo.
- Backups obligatorios: MySQL diario, almacenamiento de PDFs diario y snapshots de Qdrant según volumen.
- El stack actualizado queda oficialmente como: Flutter + FastAPI + MySQL + phpMyAdmin + Qdrant + Redis + Docker + DeepSeek API.
