# FASE 5 — Autenticación y seguridad

## Objetivo

Implementar autenticación JWT con refresh tokens, hash bcrypt, protección por roles y endpoints de sesión.

## Componentes implementados

| Capa | Archivo | Responsabilidad |
|------|---------|-----------------|
| Security | `security/password.py` | Hash y verificación bcrypt |
| Security | `security/jwt.py` | Access/refresh tokens, hash SHA-256 para refresh |
| Security | `security/permissions.py` | `require_roles()` y `user_has_role()` |
| Schema | `schemas/auth.py` | Login, logout, refresh, change-password |
| Repository | `repositories/user_repository.py` | Acceso a usuarios |
| Repository | `repositories/refresh_token_repository.py` | Gestión de refresh tokens |
| Service | `services/auth_service.py` | Lógica de autenticación |
| Routes | `api/routes/auth.py` | Endpoints REST |
| Deps | `api/deps.py` | `get_current_user`, Bearer JWT |

## Endpoints

| Método | Ruta | Auth | Descripción |
|--------|------|------|-------------|
| POST | `/api/v1/auth/login` | No | Iniciar sesión |
| POST | `/api/v1/auth/logout` | Sí | Revocar refresh token |
| POST | `/api/v1/auth/refresh` | No | Renovar tokens |
| GET | `/api/v1/auth/me` | Sí | Perfil del usuario |
| POST | `/api/v1/auth/change-password` | Sí | Cambiar contraseña |

## Usuario seed (desarrollo)

Migración `e1f2a3b4c5d6_seed_super_admin.py`:

- **Email:** `admin@avov.edu.co`
- **Contraseña:** `Admin123!`
- **Rol:** `SUPER_ADMIN`

## Validaciones

### Login
- Email requerido y formato válido
- Contraseña requerida
- Usuario debe estar `ACTIVE`
- Error genérico sin revelar si el email existe

### Change password
- Contraseña actual requerida
- Nueva: mínimo 8 caracteres, mayúscula, minúscula, número y símbolo
- Confirmación debe coincidir
- Nueva distinta a la actual
- Revoca todos los refresh tokens al cambiar contraseña

## Swagger

OpenAPI incluye esquema `BearerAuth` (JWT) en rutas protegidas.

## Criterios de validación

- [x] Sin token → 401 en `/auth/me`
- [x] Token inválido → 401
- [x] Roles disponibles en perfil y helper `require_roles`
- [x] Contraseñas hasheadas con bcrypt
- [x] Swagger muestra Bearer Token
- [x] Tests pytest de autenticación

## Siguiente fase

**FASE 6 — CRUD instituciones**
