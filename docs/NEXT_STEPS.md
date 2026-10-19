# Próximos pasos verificados

No se continúa una fase funcional hasta que el entorno de este Windows quede comprobado y el usuario lo autorice.

## Bloqueos de entorno

1. El MySQL de AVOV queda publicado en el puerto 3307. El 3306 sigue siendo XAMPP y no debe usarse para las pruebas de AVOV.
2. Ya existe un `.env` local. No pegar la API key de DeepSeek en el chat. Su `DATABASE_URL` usa el host interno `mysql` y el puerto `3306`; desde Windows no debe reescribirse a `localhost:3306`.
3. `pytest` no debe lanzarse contra el MySQL de XAMPP: los fixtures crean y borran instituciones y usuarios. Sin `DATABASE_URL`, el valor predeterminado apunta a `127.0.0.1:3307`.

## Después de desbloquear la base

1. Copiar `.env.example` a `.env` y revisar secretos locales.
2. Instalar dependencias del backend y del frontend.
3. Ejecutar `flutter analyze` y `flutter test`.
4. El stack AVOV ya está en marcha. MySQL en `127.0.0.1:3307`, Redis propio en `127.0.0.1:6380`, XAMPP en 3306 y `sc-pne-redis` en 6379.
5. Las pruebas de backend ya pasaron contra `avov_test`. No volver a lanzarlas contra `avov_db`.
6. Abrir `http://localhost:8000/api/v1/health` y `flutter run -d chrome`.

## Trabajo de producto, aún no validado en ejecución

- Reconciliar `docs/plan-desarrollo.md` con el código: hay rutas y pruebas de fases posteriores a la 4, y el frontend solo muestra splash, home y login.
- No implementar pantallas nuevas hasta confirmar con el usuario cuál es la fase vigente.
- La arquitectura de referencia sigue siendo `docs/arquitectura.md`. No hace falta otro documento de arquitectura.
