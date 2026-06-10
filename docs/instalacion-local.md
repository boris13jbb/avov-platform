# Instalación local — AVOV

## Requisitos previos

| Herramienta | Estado en Windows | Notas |
|-------------|-------------------|-------|
| Python 3.12+ | Requerido | Backend local |
| Git | Instalado vía winget | Clonar y versionar |
| Flutter SDK | `C:\Users\BRS\develop\flutter` | Agregado al PATH del usuario |
| Docker Desktop | Requiere WSL2 + reinicio | Ver sección Docker abajo |
| Chrome | Disponible | Para `flutter run -d chrome` |

## Instalación automática (scripts incluidos)

### 1. Dependencias del proyecto (sin admin)

```powershell
cd c:\Users\BRS\Documents\aplicstibi
.\scripts\install-project-deps.ps1
```

Instala: venv Python, `requirements.txt`, `flutter pub get`, `flutter analyze`, `flutter test`.

### 2. Flutter SDK (sin admin, si falta)

```powershell
.\scripts\install-flutter.ps1
```

### 3. WSL2 + Docker Desktop (requiere Administrador + reinicio)

```powershell
# Clic derecho → Ejecutar con PowerShell como administrador
.\scripts\install-prerequisites.ps1
```

Después del reinicio:
1. Abrir **Docker Desktop** y aceptar términos.
2. Ejecutar `.\scripts\dev-up.ps1`.

## Pasos manuales

1. Copiar variables de entorno:
   ```powershell
   Copy-Item .env.example .env
   ```

2. Backend local (sin Docker):
   ```powershell
   cd backend
   .\.venv\Scripts\Activate.ps1
   uvicorn app.main:app --reload --port 8000
   ```

3. Frontend web:
   ```powershell
   cd frontend
   flutter run -d chrome
   ```

4. Con Docker (cuando esté instalado):
   ```powershell
   .\scripts\dev-up.ps1
   curl http://localhost:8000/api/v1/health/live
   ```

## Verificación rápida

```powershell
git --version
python --version
flutter --version
cd backend; .\.venv\Scripts\python -m pytest -q
cd ..\frontend; flutter test
```

## Solución de problemas

- **MySQL no inicia**: verificar que el puerto 3306 no esté ocupado.
- **Backend degraded**: normal si MySQL/Redis/Qdrant aún están iniciando; esperar 30–60 segundos.
- **Docker falla al instalar**: instalar WSL2 primero (`wsl --install`) y reiniciar Windows.
- **Flutter no encontrado**: cerrar y reabrir la terminal tras `install-flutter.ps1`.
- **Android SDK no instalado**: opcional; usar `flutter run -d chrome` para desarrollo web.
