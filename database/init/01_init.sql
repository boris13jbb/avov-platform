-- AVOV — Script inicial de base de datos
-- Las migraciones formales se gestionarán con Alembic en fases posteriores.

CREATE DATABASE IF NOT EXISTS avov_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE avov_db;

-- Verificación de conexión inicial
SELECT 'Base de datos AVOV inicializada correctamente' AS status;
