-- ============================================================
-- SkyTrip – Database Modifications for hotel_app
-- Run against MariaDB 10.4 via phpMyAdmin or MySQL CLI
-- ============================================================

-- ── 1. usuarios ──────────────────────────────────────────────
-- Add: rol, direccion, pais_nacimiento, fecha_nacimiento
-- The app's /me endpoint and profile page expect these fields.

ALTER TABLE `usuarios`
  ADD COLUMN `rol` ENUM('usuario','admin') NOT NULL DEFAULT 'usuario' AFTER `contrasena`,
  ADD COLUMN `direccion` VARCHAR(255) DEFAULT NULL AFTER `rol`,
  ADD COLUMN `pais_nacimiento` VARCHAR(100) DEFAULT NULL AFTER `direccion`,
  ADD COLUMN `fecha_nacimiento` DATE DEFAULT NULL AFTER `pais_nacimiento`;

-- Promote the admin user
UPDATE `usuarios` SET `rol` = 'admin' WHERE `usuario` = 'admin';

-- ── 2. habitaciones ──────────────────────────────────────────
-- Rename: precio → precio_noche  (matches app field names)
-- Add: tipo_habitacion, disponible

ALTER TABLE `habitaciones`
  CHANGE `precio` `precio_noche` DECIMAL(10,2) DEFAULT NULL,
  ADD COLUMN `tipo_habitacion` VARCHAR(100) DEFAULT NULL AFTER `tipo`,
  ADD COLUMN `disponible` TINYINT(1) NOT NULL DEFAULT 1 AFTER `tipo_habitacion`;

-- Copy existing 'tipo' values into the new campo
UPDATE `habitaciones` SET `tipo_habitacion` = `tipo` WHERE `tipo_habitacion` IS NULL;

-- ── 3. reservas ──────────────────────────────────────────────
-- Add: id_habitacion FK  (links reservation to a specific room)
-- Rename date columns so they match what the app expects

-- Check current column names first – if your dump already uses
-- fecha_entrada / fecha_salida you can skip the CHANGE lines.
ALTER TABLE `reservas`
  CHANGE `fecha_inicio` `fecha_entrada` DATE NOT NULL,
  CHANGE `fecha_fin` `fecha_salida` DATE NOT NULL,
  CHANGE `total_precio` `precio_total` DECIMAL(10,2) DEFAULT NULL,
  ADD COLUMN `id_habitacion` INT(11) DEFAULT NULL AFTER `id_hotel`;

-- Add FK only if habitaciones table has the referenced column
ALTER TABLE `reservas`
  ADD CONSTRAINT `reservas_ibfk_habitacion`
    FOREIGN KEY (`id_habitacion`) REFERENCES `habitaciones` (`id_habitacion`)
    ON DELETE SET NULL ON UPDATE CASCADE;

-- ── 4. resenas ───────────────────────────────────────────────
-- Change puntuacion from INT to DECIMAL for half-star ratings (e.g. 4.5)

ALTER TABLE `resenas`
  MODIFY COLUMN `puntuacion` DECIMAL(3,1) DEFAULT NULL;

-- ── 5. favoritos table ───────────────────────────────────────
-- The app expects a /favoritos endpoint. Create the table if missing.

CREATE TABLE IF NOT EXISTS `favoritos` (
  `id_favorito` INT(11) NOT NULL AUTO_INCREMENT,
  `id_usuario`  INT(11) NOT NULL,
  `id_hotel`    INT(11) NOT NULL,
  `created_at`  TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_favorito`),
  UNIQUE KEY `uq_usuario_hotel` (`id_usuario`, `id_hotel`),
  CONSTRAINT `favoritos_ibfk_usuario` FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`) ON DELETE CASCADE,
  CONSTRAINT `favoritos_ibfk_hotel`   FOREIGN KEY (`id_hotel`)   REFERENCES `hoteles`  (`id_hotel`)   ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 6. hoteles_detalle VIEW ──────────────────────────────────
-- Provides ciudad_nombre and pais_nombre alongside hotel data.
-- The API's JOIN queries can SELECT from this view instead of
-- repeating the joins.

CREATE OR REPLACE VIEW `hoteles_detalle` AS
  SELECT
    h.*,
    c.nombre AS ciudad_nombre,
    p.nombre AS pais_nombre
  FROM `hoteles` h
  LEFT JOIN `ciudades` c ON h.`id_ciudad` = c.`id_ciudad`
  LEFT JOIN `paises`   p ON c.`id_pais`   = p.`id_pais`;

-- ── 7. Optional: servicios per hotel ─────────────────────────
-- If servicios are currently a comma-separated string in hoteles,
-- this table lets the API return them as an array.
-- Only run if you want normalised service data.

CREATE TABLE IF NOT EXISTS `hotel_servicios` (
  `id`        INT(11) NOT NULL AUTO_INCREMENT,
  `id_hotel`  INT(11) NOT NULL,
  `servicio`  VARCHAR(100) NOT NULL,
  PRIMARY KEY (`id`),
  CONSTRAINT `hs_ibfk_hotel` FOREIGN KEY (`id_hotel`) REFERENCES `hoteles` (`id_hotel`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── reservas: add created_at if missing ──────────────────
-- Safe to run even if column already exists (IF NOT EXISTS guard).

ALTER TABLE `reservas`
  ADD COLUMN IF NOT EXISTS `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- ── English biography for hotels ─────────────────────────
-- Adds an optional English biography column.
-- When NULL the app falls back to the Spanish `biografia`.

ALTER TABLE `hoteles`
  ADD COLUMN `biografia_en` TEXT DEFAULT NULL AFTER `biografia`;

-- ============================================================
-- End of modifications
-- ============================================================
