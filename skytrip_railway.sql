-- ============================================================
--  SKYTRIP_DB  –  Script de migración y creación completo
--  Generado: 2026-05-20
--  Motor: MySQL 8.0+ / MariaDB 10.4+  |  InnoDB  |  utf8mb4
-- ============================================================

-- ────────────────────────────────────────────────
--  0. CONFIGURACIÓN DE SESIÓN
-- ────────────────────────────────────────────────
SET SQL_MODE   = 'NO_AUTO_VALUE_ON_ZERO';
SET time_zone  = '+00:00';
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_SAFE_UPDATES   = 0;

-- ────────────────────────────────────────────────
--  1. BASE DE DATOS
-- ────────────────────────────────────────────────
DROP DATABASE IF EXISTS `skytrip_db`;
CREATE DATABASE `skytrip_db`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE `railway`;

-- ════════════════════════════════════════════════
--  2. TABLAS
-- ════════════════════════════════════════════════

-- ────────────────────────────────────────────────
--  2.01  paises
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `paises` (
  `id_pais`    INT          NOT NULL AUTO_INCREMENT,
  `nombre`     VARCHAR(100) NOT NULL,
  `codigo_iso` CHAR(2)      NULL COMMENT 'ISO 3166-1 alpha-2',
  PRIMARY KEY (`id_pais`),
  UNIQUE KEY `uq_paises_nombre` (`nombre`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Catálogo de países';

-- ────────────────────────────────────────────────
--  2.02  ciudades
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `ciudades` (
  `id_ciudad` INT          NOT NULL AUTO_INCREMENT,
  `nombre`    VARCHAR(100) NOT NULL,
  `id_pais`   INT          NOT NULL,
  PRIMARY KEY (`id_ciudad`),
  UNIQUE KEY `uq_ciudad_pais` (`nombre`, `id_pais`),
  KEY `idx_ciudades_pais` (`id_pais`),
  CONSTRAINT `fk_ciudades_pais`
    FOREIGN KEY (`id_pais`) REFERENCES `paises` (`id_pais`)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Ciudades ligadas a un país';

-- ────────────────────────────────────────────────
--  2.03  servicios
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `servicios` (
  `id_servicio` INT          NOT NULL AUTO_INCREMENT,
  `nombre`      VARCHAR(100) NOT NULL,
  `icono`       VARCHAR(100) NULL  COMMENT 'Nombre del icono en la app Flutter',
  `activo`      TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_servicio`),
  UNIQUE KEY `uq_servicios_nombre` (`nombre`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Catálogo de 22 amenidades / servicios';

-- ────────────────────────────────────────────────
--  2.04  usuarios
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `usuarios` (
  `id_usuario`             INT          NOT NULL AUTO_INCREMENT,
  `usuario`                VARCHAR(50)  NOT NULL,
  `email`                  VARCHAR(100) NOT NULL,
  `password`               VARCHAR(255) NOT NULL COMMENT 'Hash bcrypt',
  `rol`                    ENUM('admin','usuario') NOT NULL DEFAULT 'usuario',
  `direccion`              VARCHAR(255) NULL,
  `pais_nacimiento`        VARCHAR(100) NULL,
  `fecha_nacimiento`       DATE         NULL,
  `notifications_enabled`  TINYINT(1)   NOT NULL DEFAULT 1,
  `totp_secret`            VARCHAR(64)  NULL COMMENT 'Secreto TOTP Base32 para 2FA',
  `totp_enabled`           TINYINT(1)   NOT NULL DEFAULT 0,
  `token`                  VARCHAR(512) NULL COMMENT 'Bearer JWT activo',
  `created_at`             DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`             DATETIME     NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_usuario`),
  UNIQUE KEY `uq_usuarios_usuario` (`usuario`),
  UNIQUE KEY `uq_usuarios_email`   (`email`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Usuarios de la app (admin y normales)';

-- ────────────────────────────────────────────────
--  2.05  hoteles
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `hoteles` (
  `id_hotel`               INT            NOT NULL AUTO_INCREMENT,
  `nombre`                 VARCHAR(150)   NOT NULL,
  `biografia`              TEXT           NULL,
  `id_ciudad`              INT            NOT NULL,
  `precio_noche`           DECIMAL(10,2)  NOT NULL,
  `puntuacion`             DECIMAL(3,1)   NOT NULL DEFAULT 0.0
                             COMMENT '0.0 – 10.0, recalculado por trigger',
  `estrellas`              TINYINT        NOT NULL DEFAULT 3,
  `capacidad_personas`     INT            NOT NULL DEFAULT 2,
  `distancia_centro_km`    DECIMAL(5,2)   NULL,
  `distancia_aeropuerto_km` DECIMAL(5,2)  NULL,
  `latitud`                DECIMAL(10,7)  NULL,
  `longitud`               DECIMAL(10,7)  NULL,
  `imagen`                 VARCHAR(500)   NULL,
  `activo`                 TINYINT(1)     NOT NULL DEFAULT 1,
  `created_at`             DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`             DATETIME       NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_hotel`),
  KEY `idx_hoteles_ciudad`      (`id_ciudad`),
  KEY `idx_hoteles_precio`      (`precio_noche`),
  KEY `idx_hoteles_puntuacion`  (`puntuacion`),
  KEY `idx_hoteles_estrellas`   (`estrellas`),
  CONSTRAINT `fk_hoteles_ciudad`
    FOREIGN KEY (`id_ciudad`) REFERENCES `ciudades` (`id_ciudad`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `chk_estrellas`
    CHECK (`estrellas` BETWEEN 1 AND 5),
  CONSTRAINT `chk_puntuacion_hotel`
    CHECK (`puntuacion` BETWEEN 0.0 AND 10.0)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Hoteles con datos geográficos y de negocio';

-- ────────────────────────────────────────────────
--  2.06  hotel_imagenes
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `hotel_imagenes` (
  `id_imagen`  INT          NOT NULL AUTO_INCREMENT,
  `id_hotel`   INT          NOT NULL,
  `url`        VARCHAR(500) NOT NULL,
  `orden`      TINYINT      NOT NULL DEFAULT 0,
  `created_at` DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_imagen`),
  KEY `idx_himagenes_hotel` (`id_hotel`),
  CONSTRAINT `fk_himagenes_hotel`
    FOREIGN KEY (`id_hotel`) REFERENCES `hoteles` (`id_hotel`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Galería de imágenes por hotel';

-- ────────────────────────────────────────────────
--  2.07  hotel_servicios  (N:M)
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `hotel_servicios` (
  `id_hotel`    INT NOT NULL,
  `id_servicio` INT NOT NULL,
  PRIMARY KEY (`id_hotel`, `id_servicio`),
  KEY `idx_hserv_servicio` (`id_servicio`),
  CONSTRAINT `fk_hserv_hotel`
    FOREIGN KEY (`id_hotel`) REFERENCES `hoteles` (`id_hotel`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_hserv_servicio`
    FOREIGN KEY (`id_servicio`) REFERENCES `servicios` (`id_servicio`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Relación N:M hotel – servicio';

-- ────────────────────────────────────────────────
--  contacto_canales
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `contacto_canales` (
  `id`       INT(11)      NOT NULL AUTO_INCREMENT,
  `tipo`     VARCHAR(50)  NOT NULL,
  `etiqueta` VARCHAR(100) NOT NULL,
  `valor`    VARCHAR(255) NOT NULL,
  `icono`    VARCHAR(100) NOT NULL DEFAULT '',
  `posicion` INT(11)      NOT NULL DEFAULT 0,
  `activo`   TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `idx_posicion` (`posicion`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ────────────────────────────────────────────────
--  home_carrusel
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `home_carrusel` (
  `id`       INT(11)     NOT NULL AUTO_INCREMENT,
  `seccion`  VARCHAR(32) NOT NULL,
  `id_hotel` INT(11)     NOT NULL,
  `posicion` INT(11)     NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_seccion_hotel` (`seccion`, `id_hotel`),
  KEY `idx_seccion` (`seccion`),
  CONSTRAINT `hc_fk_hotel`
    FOREIGN KEY (`id_hotel`) REFERENCES `hoteles`(`id_hotel`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ────────────────────────────────────────────────
--  2.08  habitaciones
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `habitaciones` (
  `id_habitacion`    INT            NOT NULL AUTO_INCREMENT,
  `id_hotel`         INT            NOT NULL,
  `tipo_habitacion`  VARCHAR(100)   NOT NULL,
  `capacidad`        INT            NOT NULL,
  `precio_noche`     DECIMAL(10,2)  NOT NULL,
  `descripcion`      TEXT           NULL,
  `activo`           TINYINT(1)     NOT NULL DEFAULT 1,
  `created_at`       DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_habitacion`),
  KEY `idx_habitaciones_hotel` (`id_hotel`),
  CONSTRAINT `fk_habitaciones_hotel`
    FOREIGN KEY (`id_hotel`) REFERENCES `hoteles` (`id_hotel`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Tipos de habitación por hotel';

-- ────────────────────────────────────────────────
--  2.09  reservas
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `reservas` (
  `id_reserva`      INT            NOT NULL AUTO_INCREMENT,
  `id_usuario`      INT            NOT NULL,
  `id_hotel`        INT            NOT NULL,
  `id_habitacion`   INT            NULL,
  `nombre_huesped`  VARCHAR(150)   NOT NULL,
  `dni`             VARCHAR(20)    NOT NULL,
  `telefono`        VARCHAR(20)    NOT NULL,
  `fecha_inicio`    DATE           NOT NULL,
  `fecha_fin`       DATE           NOT NULL,
  `adultos`         INT            NOT NULL DEFAULT 1,
  `bebes`           INT            NOT NULL DEFAULT 0,
  `necesita_cuna`   TINYINT(1)     NOT NULL DEFAULT 0,
  `con_desayuno`    TINYINT(1)     NOT NULL DEFAULT 0,
  `es_reembolsable` TINYINT(1)     NOT NULL DEFAULT 1,
  `total_precio`    DECIMAL(10,2)  NOT NULL,
  `estado`          ENUM('confirmada','cancelada','completada') NOT NULL DEFAULT 'confirmada',
  `created_at`      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`      DATETIME       NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_reserva`),
  KEY `idx_reservas_usuario`     (`id_usuario`),
  KEY `idx_reservas_hotel`       (`id_hotel`),
  KEY `idx_reservas_fecha_inicio`(`fecha_inicio`),
  KEY `idx_reservas_fecha_fin`   (`fecha_fin`),
  KEY `idx_reservas_estado`      (`estado`),
  CONSTRAINT `fk_reservas_usuario`
    FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_reservas_hotel`
    FOREIGN KEY (`id_hotel`) REFERENCES `hoteles` (`id_hotel`)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `fk_reservas_habitacion`
    FOREIGN KEY (`id_habitacion`) REFERENCES `habitaciones` (`id_habitacion`)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_fechas_reserva`
    CHECK (`fecha_fin` > `fecha_inicio`),
  CONSTRAINT `chk_adultos_min`
    CHECK (`adultos` >= 1)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Reservas de habitaciones por usuario';

-- ────────────────────────────────────────────────
--  2.10  reviews
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `reviews` (
  `id_review`   INT           NOT NULL AUTO_INCREMENT,
  `id_hotel`    INT           NOT NULL,
  `id_usuario`  INT           NOT NULL,
  `puntuacion`  DECIMAL(2,1)  NOT NULL
                  COMMENT '0.5 – 5.0 estrellas',
  `comentario`  TEXT          NULL,
  `fecha`       DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_review`),
  UNIQUE KEY `uq_review_hotel_usuario` (`id_hotel`, `id_usuario`),
  KEY `idx_reviews_hotel`   (`id_hotel`),
  KEY `idx_reviews_usuario` (`id_usuario`),
  CONSTRAINT `fk_reviews_hotel`
    FOREIGN KEY (`id_hotel`) REFERENCES `hoteles` (`id_hotel`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_reviews_usuario`
    FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_puntuacion_review`
    CHECK (`puntuacion` BETWEEN 0.5 AND 5.0)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Reseñas: un usuario solo puede reseñar un hotel una vez';

-- ────────────────────────────────────────────────
--  2.11  favoritos_hoteles
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `favoritos_hoteles` (
  `id_usuario`  INT      NOT NULL,
  `id_hotel`    INT      NOT NULL,
  `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_usuario`, `id_hotel`),
  KEY `idx_favh_hotel` (`id_hotel`),
  CONSTRAINT `fk_favh_usuario`
    FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_favh_hotel`
    FOREIGN KEY (`id_hotel`) REFERENCES `hoteles` (`id_hotel`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Hoteles marcados como favoritos por usuario';

-- ────────────────────────────────────────────────
--  2.12  favoritos_destinos
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `favoritos_destinos` (
  `id_usuario`  INT      NOT NULL,
  `id_pais`     INT      NOT NULL,
  `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_usuario`, `id_pais`),
  KEY `idx_favd_pais` (`id_pais`),
  CONSTRAINT `fk_favd_usuario`
    FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_favd_pais`
    FOREIGN KEY (`id_pais`) REFERENCES `paises` (`id_pais`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Países favoritos por usuario';

-- ────────────────────────────────────────────────
--  2.13  recently_viewed
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `recently_viewed` (
  `id`          INT      NOT NULL AUTO_INCREMENT,
  `id_usuario`  INT      NOT NULL,
  `id_hotel`    INT      NOT NULL,
  `visto_en`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_rv_usuario_fecha` (`id_usuario`, `visto_en`),
  KEY `idx_rv_hotel`         (`id_hotel`),
  CONSTRAINT `fk_rv_usuario`
    FOREIGN KEY (`id_usuario`) REFERENCES `usuarios` (`id_usuario`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_rv_hotel`
    FOREIGN KEY (`id_hotel`) REFERENCES `hoteles` (`id_hotel`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Últimos 8 hoteles vistos por usuario (límite a nivel app)';

-- ────────────────────────────────────────────────
--  cms_contenido
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS cms_contenido (
    id         TINYINT UNSIGNED NOT NULL DEFAULT 1,
    datos      JSON             NOT NULL,
    updated_at TIMESTAMP        DEFAULT CURRENT_TIMESTAMP
                                ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id)
);

-- ────────────────────────────────────────────────
--  2.14  cms_paginas
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `cms_paginas` (
  `id_pagina`  INT          NOT NULL AUTO_INCREMENT,
  `clave`      VARCHAR(100) NOT NULL COMMENT 'ej: condiciones, destinos, atencion',
  `titulo`     VARCHAR(200) NOT NULL,
  `contenido`  LONGTEXT     NULL,
  `orden`      TINYINT      NOT NULL DEFAULT 0,
  `activo`     TINYINT(1)   NOT NULL DEFAULT 1,
  `updated_at` DATETIME     NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id_pagina`),
  UNIQUE KEY `uq_cms_paginas_clave` (`clave`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Páginas dinámicas del CMS';

-- ────────────────────────────────────────────────
--  2.15  cms_secciones
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `cms_secciones` (
  `id_seccion` INT          NOT NULL AUTO_INCREMENT,
  `id_pagina`  INT          NOT NULL,
  `titulo`     VARCHAR(200) NOT NULL,
  `contenido`  TEXT         NULL,
  `orden`      TINYINT      NOT NULL DEFAULT 0,
  `activo`     TINYINT(1)   NOT NULL DEFAULT 1,
  PRIMARY KEY (`id_seccion`),
  KEY `idx_cmss_pagina` (`id_pagina`),
  CONSTRAINT `fk_cmss_pagina`
    FOREIGN KEY (`id_pagina`) REFERENCES `cms_paginas` (`id_pagina`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Sub-secciones de páginas CMS';

-- ────────────────────────────────────────────────
--  2.16  cms_home_config
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `cms_home_config` (
  `clave`  VARCHAR(100) NOT NULL,
  `valor`  VARCHAR(255) NOT NULL,
  `tipo`   ENUM('bool','string','int') NOT NULL DEFAULT 'string',
  PRIMARY KEY (`clave`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Toggles de secciones de la pantalla Home';

-- ────────────────────────────────────────────────
--  2.17  cms_filtros
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `cms_filtros` (
  `id_filtro`   INT          NOT NULL AUTO_INCREMENT,
  `nombre`      VARCHAR(100) NOT NULL,
  `id_servicio` INT          NULL,
  `activo`      TINYINT(1)   NOT NULL DEFAULT 1,
  `orden`       TINYINT      NOT NULL DEFAULT 0,
  PRIMARY KEY (`id_filtro`),
  KEY `idx_filtros_servicio` (`id_servicio`),
  CONSTRAINT `fk_filtros_servicio`
    FOREIGN KEY (`id_servicio`) REFERENCES `servicios` (`id_servicio`)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Filtros rápidos configurables en pantalla de búsqueda';

-- ────────────────────────────────────────────────
--  2.18  monedas
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `monedas` (
  `codigo`       CHAR(3)        NOT NULL,
  `simbolo`      VARCHAR(5)     NOT NULL,
  `tasa_cambio`  DECIMAL(12,6)  NOT NULL COMMENT 'Relativa a EUR como base',
  `nombre`       VARCHAR(50)    NOT NULL,
  PRIMARY KEY (`codigo`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Divisas disponibles en el selector de moneda';

-- ────────────────────────────────────────────────
--  2.19  idiomas
-- ────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS `idiomas` (
  `codigo` CHAR(2)     NOT NULL,
  `nombre` VARCHAR(50) NOT NULL,
  `activo` TINYINT(1)  NOT NULL DEFAULT 1,
  PRIMARY KEY (`codigo`)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='Idiomas soportados por la app';

-- ════════════════════════════════════════════════
--  3. DATOS – CATÁLOGOS BASE
-- ════════════════════════════════════════════════

INSERT IGNORE INTO `paises` (`id_pais`, `nombre`, `codigo_iso`) VALUES
(1,  'España',            'ES'),
(2,  'Francia',           'FR'),
(3,  'Italia',            'IT'),
(4,  'Alemania',          'DE'),
(5,  'Reino Unido',       'GB'),
(6,  'Estados Unidos',    'US'),
(7,  'Canadá',            'CA'),
(8,  'México',            'MX'),
(9,  'Brasil',            'BR'),
(10, 'Argentina',         'AR'),
(11, 'Noruega',           'NO'),
(12, 'Suecia',            'SE'),
(13, 'Japón',             'JP'),
(14, 'Australia',         'AU'),
(15, 'Emiratos Árabes',   'AE'),
(16, 'Suiza',             'CH'),
(17, 'China',             'CN'),
(18, 'Corea del Sur',     'KR'),
(19, 'Turquía',           'TR'),
(20, 'Sudáfrica',         'ZA'),
(24, 'Nueva Zelanda',     'NZ'),
(25, 'Egipto',            'EG'),
(27, 'Tailandia',         'TH'),
(28, 'Vietnam',           'VN'),
(29, 'Indonesia',         'ID'),
(30, 'India',             'IN'),
(31, 'Marruecos',         'MA'),
(33, 'Rusia',             'RU'),
(34, 'Polonia',           'PL'),
(35, 'República Checa',   'CZ'),
(36, 'Irlanda',           'IE'),
(39, 'Dinamarca',         'DK'),
(40, 'Finlandia',         'FI'),
(41, 'Croacia',           'HR'),
(42, 'Hungría',           'HU'),
(43, 'Rumanía',           'RO'),
(44, 'Bulgaria',          'BG'),
(45, 'Ucrania',           'UA');

INSERT IGNORE INTO `ciudades` (`id_ciudad`, `nombre`, `id_pais`) VALUES
(1,  'Madrid',           1),
(2,  'Paris',            2),
(3,  'Roma',             3),
(4,  'Berlin',           4),
(5,  'Londres',          5),
(6,  'New York',         6),
(7,  'Toronto',          7),
(8,  'Ciudad de Mexico', 8),
(9,  'Rio de Janeiro',   9),
(10, 'Buenos Aires',     10),
(11, 'Oslo',             11),
(12, 'Estocolmo',        12),
(13, 'Tokyo',            13),
(14, 'Sydney',           14),
(15, 'Dubai',            15),
(16, 'Zurich',           16),
(17, 'Beijing',          17),
(18, 'Seoul',            18),
(19, 'Estambul',         19),
(20, 'Cape Town',        20);

INSERT IGNORE INTO `servicios` (`id_servicio`, `nombre`, `icono`, `activo`) VALUES
(1,  'WiFi gratis',                              'wifi',              1),
(2,  'Parking',                                  'parking',           1),
(3,  'Parking gratis',                           'parking_free',      1),
(4,  'Piscina',                                  'pool',              1),
(5,  'Gimnasio',                                 'fitness_center',    1),
(6,  'Restaurante',                              'restaurant',        1),
(7,  'Servicio de habitaciones',                 'room_service',      1),
(8,  'Recepción 24 horas',                       'reception_24h',     1),
(9,  'Spa y centro de bienestar',                'spa',               1),
(10, 'Traslado aeropuerto',                      'airport_shuttle',   1),
(11, 'Adaptado para sillas de ruedas',           'accessible',        1),
(12, 'Estación de carga vehículos eléctricos',   'ev_station',        1),
(13, 'Bañera de hidromasaje / jacuzzi',          'hot_tub',           1),
(14, 'Habitaciones sin humo',                    'smoke_free',        1),
(15, 'Admite mascotas',                          'pets',              1),
(16, 'Solo adultos',                             'adults_only',       1),
(17, 'Desayuno incluido',                        'free_breakfast',    1),
(18, 'Cancelación gratis',                       'cancel',            1),
(19, 'Zona favorita de los clientes',            'favorite_zone',     1),
(20, 'Fantástico: 9 o más',                      'star_9',            1),
(21, 'Muy bien: 8 o más',                        'star_8',            1),
(22, 'Vista al mar',                             'sea_view',          1);

-- ════════════════════════════════════════════════
--  4. USUARIOS
-- ════════════════════════════════════════════════
INSERT IGNORE INTO `usuarios`
  (`id_usuario`, `usuario`, `email`, `password`, `rol`,
   `notifications_enabled`, `created_at`) VALUES
(1, 'admin', 'admin@gmail.com',
   '$2y$10$LPqR3tlpHyKq.i5odch5dejILDyobgJaPvage9MQiyewlioCc80iK',
   'admin', 1, '2026-04-25 11:32:33'),
(2, 'juan',  'juan@gmail.com',
   '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uFpZhJCVO',
   'usuario', 1, '2026-04-25 11:32:33'),
(3, 'maria', 'maria@gmail.com',
   '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uFpZhJCVO',
   'usuario', 1, '2026-04-25 11:32:33');

-- ════════════════════════════════════════════════
--  5. HOTELES
-- ════════════════════════════════════════════════
INSERT IGNORE INTO `hoteles`
  (`id_hotel`,`nombre`,`id_ciudad`,`estrellas`,`puntuacion`,
   `precio_noche`,`capacidad_personas`,`distancia_centro_km`,
   `distancia_aeropuerto_km`,`imagen`,`biografia`,`activo`) VALUES
(1,'Hotel Central Madrid',1,5,9.4,400.00,2,0.50,15.00,
 'https://lh3.googleusercontent.com/gps-cs-s/APNQkAELlODpvz1rC5M8l7s3jwp2PttidfGkiL-hKpAhIHT5tGQx9ASxVd-iehEb7wTw2JKRn3nsEx3te_FRU1-2TZzckugT-DqF57dcLf_AyUGK7TUivGAyB-n915SwYsITfR2yPnY6cA=s1360-w1360-h1020-rw',
 'Lujo en Madrid con spa y restaurante gourmet.',1),
(2,'Gran Via Palace',1,4,8.6,220.00,3,0.80,16.00,
 'https://cf.bstatic.com/xdata/images/hotel/max1024x768/614285764.jpg?k=e25267e3542d2cf3256ecd21ef5a72523f326f0abf2330a3c63cbc1e2f0a88d8&o=',
 'Hotel moderno en Gran Vía.',1),
(3,'Hostal Madrid Centro',1,3,8.2,90.00,2,0.60,15.00,NULL,
 'Alojamiento económico en el centro de Madrid.',1),
(4,'Paris Luxury Hotel',2,5,9.6,600.00,2,1.00,20.00,NULL,
 'Hotel de lujo con vistas a la Torre Eiffel.',1),
(5,'Eiffel Palace',2,5,9.8,580.00,2,0.70,19.00,NULL,
 'Hotel premium junto a la Torre Eiffel.',1),
(6,'Louvre Grand Hotel',2,5,9.4,620.00,2,0.90,21.00,NULL,
 'Cerca del Louvre.',1),
(7,'Paris Comfort Inn',2,3,8.0,120.00,2,1.50,22.00,NULL,
 'Hotel económico en París.',1),
(8,'Rome Imperial Hotel',3,5,9.2,470.00,2,0.60,18.00,NULL,
 'Hotel histórico en Roma.',1),
(9,'Colosseum Palace',3,5,9.4,500.00,2,0.40,17.00,NULL,
 'Hotel junto al Coliseo.',1),
(10,'Rome Luxury Suites',3,5,9.6,450.00,2,0.80,19.00,NULL,
 'Suites de lujo en Roma.',1),
(11,'Rome Budget Stay',3,2,7.8,80.00,2,1.80,20.00,NULL,
 'Hotel económico en Roma.',1),
(12,'Berlin Grand Hotel',4,5,9.0,480.00,2,1.20,25.00,NULL,
 'Hotel elegante en Berlín.',1),
(13,'Brandenburg Hotel',4,5,9.2,510.00,2,0.90,24.00,NULL,
 'Cerca de la Puerta de Brandeburgo.',1),
(14,'Berlin Business Hotel',4,4,8.4,210.00,3,1.50,26.00,NULL,
 'Hotel de negocios.',1),
(15,'Berlin Easy Stay',4,3,8.0,110.00,2,1.50,26.00,NULL,
 'Hotel económico en Berlín.',1),
(16,'London Savoy Palace',5,5,9.6,520.00,2,1.10,30.00,NULL,
 'Hotel icónico en Londres.',1),
(17,'Buckingham Hotel',5,5,9.8,580.00,2,0.50,28.00,NULL,
 'Cerca del Palacio Real.',1),
(18,'London Bridge Hotel',5,4,8.8,260.00,3,1.00,29.00,NULL,
 'Hotel moderno en Londres.',1),
(19,'London Budget Rooms',5,3,8.2,130.00,2,1.40,31.00,NULL,
 'Hotel económico en Londres.',1),
(20,'New York Plaza',6,5,9.4,550.00,2,0.80,22.00,NULL,
 'Hotel en Manhattan.',1),
(21,'Times Square Hotel',6,5,9.2,600.00,2,0.30,20.00,NULL,
 'En Times Square.',1),
(22,'NY Manhattan Hotel',6,4,8.6,300.00,3,1.20,23.00,NULL,
 'Hotel céntrico.',1),
(23,'NY Economy Hotel',6,3,8.0,140.00,2,1.30,23.00,NULL,
 'Hotel barato en NY.',1),
(24,'Toronto Royal Hotel',7,5,9.2,420.00,2,0.90,18.00,NULL,
 'Hotel de lujo en Toronto.',1),
(25,'CN Tower Hotel',7,5,9.4,450.00,2,0.50,17.00,NULL,
 'Cerca de la CN Tower.',1),
(26,'Toronto Budget Inn',7,3,8.0,110.00,2,1.50,19.00,NULL,
 'Hotel económico en Toronto.',1),
(27,'Mexico Palace Hotel',8,5,9.0,390.00,2,1.00,19.00,NULL,
 'Hotel de lujo en CDMX.',1),
(28,'Aztec Grand Hotel',8,5,9.2,420.00,2,0.70,18.00,NULL,
 'Hotel histórico.',1),
(29,'CDMX Budget Hotel',8,3,8.0,100.00,2,1.60,20.00,NULL,
 'Hotel económico en CDMX.',1),
(30,'Rio Luxury Resort',9,5,9.2,420.00,2,1.00,22.00,NULL,
 'Resort en Río.',1),
(31,'Copacabana Palace',9,5,9.6,500.00,2,0.30,20.00,NULL,
 'Frente a la playa.',1),
(32,'Rio Budget Stay',9,3,8.0,95.00,2,1.50,22.00,NULL,
 'Hotel económico en Río.',1),
(33,'Buenos Aires Palace',10,5,9.0,350.00,2,0.90,21.00,NULL,
 'Hotel elegante.',1),
(34,'Tango Grand Hotel',10,5,9.2,370.00,2,1.10,22.00,NULL,
 'Hotel cultural.',1),
(35,'Buenos Aires Budget Hotel',10,3,8.0,90.00,2,1.60,23.00,NULL,
 'Hotel económico.',1),
(36,'Oslo Grand Hotel',11,5,9.2,420.00,2,1.00,25.00,NULL,
 'Hotel en Oslo.',1),
(37,'Fjord View Hotel',11,5,9.4,450.00,2,0.50,24.00,NULL,
 'Vistas a fiordos.',1),
(38,'Oslo Budget Hotel',11,3,8.0,120.00,2,1.40,25.00,NULL,
 'Hotel económico en Oslo.',1),
(39,'Stockholm Palace',12,5,9.0,380.00,2,1.20,23.00,NULL,
 'Hotel en Estocolmo.',1),
(40,'Nobel Hotel',12,5,9.2,400.00,2,0.80,22.00,NULL,
 'Hotel moderno.',1),
(41,'Stockholm Budget Hotel',12,3,8.0,110.00,2,1.50,23.00,NULL,
 'Hotel económico.',1),
(42,'Tokyo Luxury Hotel',13,5,9.6,520.00,2,0.70,19.00,NULL,
 'Hotel de lujo en Tokio.',1),
(43,'Shibuya Grand Hotel',13,5,9.8,580.00,2,0.40,18.00,NULL,
 'En Shibuya.',1),
(44,'Tokyo Budget Inn',13,3,8.0,130.00,2,1.40,19.00,NULL,
 'Hotel económico.',1),
(45,'Sydney Luxury Hotel',14,5,9.4,500.00,2,1.00,21.00,NULL,
 'Hotel en Sydney.',1),
(46,'Opera House Hotel',14,5,9.6,550.00,2,0.30,20.00,NULL,
 'Junto a la ópera.',1),
(47,'Sydney Budget Hotel',14,3,8.0,120.00,2,1.50,21.00,NULL,
 'Hotel económico.',1),
(48,'Dubai Luxury Palace',15,5,9.8,1200.00,2,0.50,10.00,NULL,
 'Ultra lujo en Dubai.',1),
(49,'Burj Al Arab Hotel',15,5,10.0,1500.00,2,0.30,8.00,NULL,
 'El más lujoso del mundo.',1),
(50,'Dubai City Hotel',15,3,8.4,200.00,2,1.50,12.00,NULL,
 'Hotel económico en Dubai.',1),
(51,'Zurich Elite Hotel',16,5,9.2,700.00,2,0.90,15.00,NULL,
 'Hotel alpino.',1),
(52,'Zurich Budget Hotel',16,3,8.0,150.00,2,1.30,16.00,NULL,
 'Hotel económico en Zurich.',1),
(53,'Beijing Imperial Hotel',17,5,9.0,450.00,2,1.00,18.00,NULL,
 'Hotel histórico.',1),
(54,'Beijing Budget Inn',17,3,8.0,120.00,2,1.60,18.00,NULL,
 'Hotel económico en Beijing.',1),
(55,'Seoul Sky Hotel',18,5,9.4,500.00,2,0.60,17.00,NULL,
 'Hotel moderno.',1),
(56,'Seoul Budget Hotel',18,3,8.0,130.00,2,1.50,17.00,NULL,
 'Hotel económico en Seoul.',1),
(57,'Istanbul Sultan Hotel',19,5,9.2,400.00,2,0.80,19.00,NULL,
 'Hotel histórico.',1),
(58,'Istanbul Budget Hotel',19,3,8.0,110.00,2,1.40,19.00,NULL,
 'Hotel económico en Estambul.',1),
(59,'Cape Town Ocean Hotel',20,5,9.0,380.00,2,1.20,22.00,NULL,
 'Vistas al océano.',1),
(60,'Cape Town Budget Hotel',20,3,8.0,100.00,2,1.60,22.00,NULL,
 'Hotel económico en Cape Town.',1);

-- ════════════════════════════════════════════════
--  6. HOTEL_SERVICIOS
-- ════════════════════════════════════════════════
INSERT IGNORE INTO `hotel_servicios` (`id_hotel`, `id_servicio`)
SELECT h.id_hotel, s.id_servicio
FROM   `hoteles`   h
CROSS JOIN `servicios` s
WHERE  s.id_servicio BETWEEN 1 AND 21;

INSERT IGNORE INTO `hotel_servicios` (`id_hotel`, `id_servicio`) VALUES
(31, 22),
(46, 22),
(59, 22);

-- ════════════════════════════════════════════════
--  7. HABITACIONES
-- ════════════════════════════════════════════════
INSERT IGNORE INTO `habitaciones` (`id_habitacion`,`id_hotel`,`tipo_habitacion`,`capacidad`,`precio_noche`,`descripcion`,`activo`) VALUES
(1,1,'Individual',1,240.00,'Habitación individual con todas las comodidades',1),
(2,2,'Individual',1,132.00,'Habitación individual con todas las comodidades',1),
(3,3,'Individual',1,54.00,'Habitación individual con todas las comodidades',1),
(4,4,'Individual',1,360.00,'Habitación individual con todas las comodidades',1),
(5,5,'Individual',1,348.00,'Habitación individual con todas las comodidades',1),
(6,6,'Individual',1,372.00,'Habitación individual con todas las comodidades',1),
(7,7,'Individual',1,72.00,'Habitación individual con todas las comodidades',1),
(8,8,'Individual',1,282.00,'Habitación individual con todas las comodidades',1),
(9,9,'Individual',1,300.00,'Habitación individual con todas las comodidades',1),
(10,10,'Individual',1,270.00,'Habitación individual con todas las comodidades',1),
(11,11,'Individual',1,48.00,'Habitación individual con todas las comodidades',1),
(12,12,'Individual',1,288.00,'Habitación individual con todas las comodidades',1),
(13,13,'Individual',1,306.00,'Habitación individual con todas las comodidades',1),
(14,14,'Individual',1,126.00,'Habitación individual con todas las comodidades',1),
(15,15,'Individual',1,66.00,'Habitación individual con todas las comodidades',1),
(16,16,'Individual',1,312.00,'Habitación individual con todas las comodidades',1),
(17,17,'Individual',1,348.00,'Habitación individual con todas las comodidades',1),
(18,18,'Individual',1,156.00,'Habitación individual con todas las comodidades',1),
(19,19,'Individual',1,78.00,'Habitación individual con todas las comodidades',1),
(20,20,'Individual',1,330.00,'Habitación individual con todas las comodidades',1),
(21,21,'Individual',1,360.00,'Habitación individual con todas las comodidades',1),
(22,22,'Individual',1,180.00,'Habitación individual con todas las comodidades',1),
(23,23,'Individual',1,84.00,'Habitación individual con todas las comodidades',1),
(24,24,'Individual',1,252.00,'Habitación individual con todas las comodidades',1),
(25,25,'Individual',1,270.00,'Habitación individual con todas las comodidades',1),
(26,26,'Individual',1,66.00,'Habitación individual con todas las comodidades',1),
(27,27,'Individual',1,234.00,'Habitación individual con todas las comodidades',1),
(28,28,'Individual',1,252.00,'Habitación individual con todas las comodidades',1),
(29,29,'Individual',1,60.00,'Habitación individual con todas las comodidades',1),
(30,30,'Individual',1,252.00,'Habitación individual con todas las comodidades',1),
(31,31,'Individual',1,300.00,'Habitación individual con todas las comodidades',1),
(32,32,'Individual',1,57.00,'Habitación individual con todas las comodidades',1),
(33,33,'Individual',1,210.00,'Habitación individual con todas las comodidades',1),
(34,34,'Individual',1,222.00,'Habitación individual con todas las comodidades',1),
(35,35,'Individual',1,54.00,'Habitación individual con todas las comodidades',1),
(36,36,'Individual',1,252.00,'Habitación individual con todas las comodidades',1),
(37,37,'Individual',1,270.00,'Habitación individual con todas las comodidades',1),
(38,38,'Individual',1,72.00,'Habitación individual con todas las comodidades',1),
(39,39,'Individual',1,228.00,'Habitación individual con todas las comodidades',1),
(40,40,'Individual',1,240.00,'Habitación individual con todas las comodidades',1),
(41,41,'Individual',1,66.00,'Habitación individual con todas las comodidades',1),
(42,42,'Individual',1,312.00,'Habitación individual con todas las comodidades',1),
(43,43,'Individual',1,348.00,'Habitación individual con todas las comodidades',1),
(44,44,'Individual',1,78.00,'Habitación individual con todas las comodidades',1),
(45,45,'Individual',1,300.00,'Habitación individual con todas las comodidades',1),
(46,46,'Individual',1,330.00,'Habitación individual con todas las comodidades',1),
(47,47,'Individual',1,72.00,'Habitación individual con todas las comodidades',1),
(48,48,'Individual',1,720.00,'Habitación individual con todas las comodidades',1),
(49,49,'Individual',1,900.00,'Habitación individual con todas las comodidades',1),
(50,50,'Individual',1,120.00,'Habitación individual con todas las comodidades',1),
(51,51,'Individual',1,420.00,'Habitación individual con todas las comodidades',1),
(52,52,'Individual',1,90.00,'Habitación individual con todas las comodidades',1),
(53,53,'Individual',1,270.00,'Habitación individual con todas las comodidades',1),
(54,54,'Individual',1,72.00,'Habitación individual con todas las comodidades',1),
(55,55,'Individual',1,300.00,'Habitación individual con todas las comodidades',1),
(56,56,'Individual',1,78.00,'Habitación individual con todas las comodidades',1),
(57,57,'Individual',1,240.00,'Habitación individual con todas las comodidades',1),
(58,58,'Individual',1,66.00,'Habitación individual con todas las comodidades',1),
(59,59,'Individual',1,228.00,'Habitación individual con todas las comodidades',1),
(60,60,'Individual',1,60.00,'Habitación individual con todas las comodidades',1),
(61,1,'Doble',2,360.00,'Habitación doble con cama de matrimonio',1),
(62,2,'Doble',2,198.00,'Habitación doble con cama de matrimonio',1),
(63,3,'Doble',2,81.00,'Habitación doble con cama de matrimonio',1),
(64,4,'Doble',2,540.00,'Habitación doble con cama de matrimonio',1),
(65,5,'Doble',2,522.00,'Habitación doble con cama de matrimonio',1),
(66,6,'Doble',2,558.00,'Habitación doble con cama de matrimonio',1),
(67,7,'Doble',2,108.00,'Habitación doble con cama de matrimonio',1),
(68,8,'Doble',2,423.00,'Habitación doble con cama de matrimonio',1),
(69,9,'Doble',2,450.00,'Habitación doble con cama de matrimonio',1),
(70,10,'Doble',2,405.00,'Habitación doble con cama de matrimonio',1),
(71,11,'Doble',2,72.00,'Habitación doble con cama de matrimonio',1),
(72,12,'Doble',2,432.00,'Habitación doble con cama de matrimonio',1),
(73,13,'Doble',2,459.00,'Habitación doble con cama de matrimonio',1),
(74,14,'Doble',2,189.00,'Habitación doble con cama de matrimonio',1),
(75,15,'Doble',2,99.00,'Habitación doble con cama de matrimonio',1),
(76,16,'Doble',2,468.00,'Habitación doble con cama de matrimonio',1),
(77,17,'Doble',2,522.00,'Habitación doble con cama de matrimonio',1),
(78,18,'Doble',2,234.00,'Habitación doble con cama de matrimonio',1),
(79,19,'Doble',2,117.00,'Habitación doble con cama de matrimonio',1),
(80,20,'Doble',2,495.00,'Habitación doble con cama de matrimonio',1),
(81,21,'Doble',2,540.00,'Habitación doble con cama de matrimonio',1),
(82,22,'Doble',2,270.00,'Habitación doble con cama de matrimonio',1),
(83,23,'Doble',2,126.00,'Habitación doble con cama de matrimonio',1),
(84,24,'Doble',2,378.00,'Habitación doble con cama de matrimonio',1),
(85,25,'Doble',2,405.00,'Habitación doble con cama de matrimonio',1),
(86,26,'Doble',2,99.00,'Habitación doble con cama de matrimonio',1),
(87,27,'Doble',2,351.00,'Habitación doble con cama de matrimonio',1),
(88,28,'Doble',2,378.00,'Habitación doble con cama de matrimonio',1),
(89,29,'Doble',2,90.00,'Habitación doble con cama de matrimonio',1),
(90,30,'Doble',2,378.00,'Habitación doble con cama de matrimonio',1),
(91,31,'Doble',2,450.00,'Habitación doble con cama de matrimonio',1),
(92,32,'Doble',2,85.50,'Habitación doble con cama de matrimonio',1),
(93,33,'Doble',2,315.00,'Habitación doble con cama de matrimonio',1),
(94,34,'Doble',2,333.00,'Habitación doble con cama de matrimonio',1),
(95,35,'Doble',2,81.00,'Habitación doble con cama de matrimonio',1),
(96,36,'Doble',2,378.00,'Habitación doble con cama de matrimonio',1),
(97,37,'Doble',2,405.00,'Habitación doble con cama de matrimonio',1),
(98,38,'Doble',2,108.00,'Habitación doble con cama de matrimonio',1),
(99,39,'Doble',2,342.00,'Habitación doble con cama de matrimonio',1),
(100,40,'Doble',2,360.00,'Habitación doble con cama de matrimonio',1),
(101,41,'Doble',2,99.00,'Habitación doble con cama de matrimonio',1),
(102,42,'Doble',2,468.00,'Habitación doble con cama de matrimonio',1),
(103,43,'Doble',2,522.00,'Habitación doble con cama de matrimonio',1),
(104,44,'Doble',2,117.00,'Habitación doble con cama de matrimonio',1),
(105,45,'Doble',2,450.00,'Habitación doble con cama de matrimonio',1),
(106,46,'Doble',2,495.00,'Habitación doble con cama de matrimonio',1),
(107,47,'Doble',2,108.00,'Habitación doble con cama de matrimonio',1),
(108,48,'Doble',2,1080.00,'Habitación doble con cama de matrimonio',1),
(109,49,'Doble',2,1350.00,'Habitación doble con cama de matrimonio',1),
(110,50,'Doble',2,180.00,'Habitación doble con cama de matrimonio',1),
(111,51,'Doble',2,630.00,'Habitación doble con cama de matrimonio',1),
(112,52,'Doble',2,135.00,'Habitación doble con cama de matrimonio',1),
(113,53,'Doble',2,405.00,'Habitación doble con cama de matrimonio',1),
(114,54,'Doble',2,108.00,'Habitación doble con cama de matrimonio',1),
(115,55,'Doble',2,450.00,'Habitación doble con cama de matrimonio',1),
(116,56,'Doble',2,117.00,'Habitación doble con cama de matrimonio',1),
(117,57,'Doble',2,360.00,'Habitación doble con cama de matrimonio',1),
(118,58,'Doble',2,99.00,'Habitación doble con cama de matrimonio',1),
(119,59,'Doble',2,342.00,'Habitación doble con cama de matrimonio',1),
(120,60,'Doble',2,90.00,'Habitación doble con cama de matrimonio',1),
(121,1,'Estándar',2,320.00,'Habitación estándar con tarifa no reembolsable',1),
(122,2,'Estándar',2,176.00,'Habitación estándar con tarifa no reembolsable',1),
(123,3,'Estándar',2,72.00,'Habitación estándar con tarifa no reembolsable',1),
(124,4,'Estándar',2,480.00,'Habitación estándar con tarifa no reembolsable',1),
(125,5,'Estándar',2,464.00,'Habitación estándar con tarifa no reembolsable',1),
(126,6,'Estándar',2,496.00,'Habitación estándar con tarifa no reembolsable',1),
(127,7,'Estándar',2,96.00,'Habitación estándar con tarifa no reembolsable',1),
(128,8,'Estándar',2,376.00,'Habitación estándar con tarifa no reembolsable',1),
(129,9,'Estándar',2,400.00,'Habitación estándar con tarifa no reembolsable',1),
(130,10,'Estándar',2,360.00,'Habitación estándar con tarifa no reembolsable',1),
(131,11,'Estándar',2,64.00,'Habitación estándar con tarifa no reembolsable',1),
(132,12,'Estándar',2,384.00,'Habitación estándar con tarifa no reembolsable',1),
(133,13,'Estándar',2,408.00,'Habitación estándar con tarifa no reembolsable',1),
(134,14,'Estándar',2,168.00,'Habitación estándar con tarifa no reembolsable',1),
(135,15,'Estándar',2,88.00,'Habitación estándar con tarifa no reembolsable',1),
(136,16,'Estándar',2,416.00,'Habitación estándar con tarifa no reembolsable',1),
(137,17,'Estándar',2,464.00,'Habitación estándar con tarifa no reembolsable',1),
(138,18,'Estándar',2,208.00,'Habitación estándar con tarifa no reembolsable',1),
(139,19,'Estándar',2,104.00,'Habitación estándar con tarifa no reembolsable',1),
(140,20,'Estándar',2,440.00,'Habitación estándar con tarifa no reembolsable',1),
(141,21,'Estándar',2,480.00,'Habitación estándar con tarifa no reembolsable',1),
(142,22,'Estándar',2,240.00,'Habitación estándar con tarifa no reembolsable',1),
(143,23,'Estándar',2,112.00,'Habitación estándar con tarifa no reembolsable',1),
(144,24,'Estándar',2,336.00,'Habitación estándar con tarifa no reembolsable',1),
(145,25,'Estándar',2,360.00,'Habitación estándar con tarifa no reembolsable',1),
(146,26,'Estándar',2,88.00,'Habitación estándar con tarifa no reembolsable',1),
(147,27,'Estándar',2,312.00,'Habitación estándar con tarifa no reembolsable',1),
(148,28,'Estándar',2,336.00,'Habitación estándar con tarifa no reembolsable',1),
(149,29,'Estándar',2,80.00,'Habitación estándar con tarifa no reembolsable',1),
(150,30,'Estándar',2,336.00,'Habitación estándar con tarifa no reembolsable',1),
(151,31,'Estándar',2,400.00,'Habitación estándar con tarifa no reembolsable',1),
(152,32,'Estándar',2,76.00,'Habitación estándar con tarifa no reembolsable',1),
(153,33,'Estándar',2,280.00,'Habitación estándar con tarifa no reembolsable',1),
(154,34,'Estándar',2,296.00,'Habitación estándar con tarifa no reembolsable',1),
(155,35,'Estándar',2,72.00,'Habitación estándar con tarifa no reembolsable',1),
(156,36,'Estándar',2,336.00,'Habitación estándar con tarifa no reembolsable',1),
(157,37,'Estándar',2,360.00,'Habitación estándar con tarifa no reembolsable',1),
(158,38,'Estándar',2,96.00,'Habitación estándar con tarifa no reembolsable',1),
(159,39,'Estándar',2,304.00,'Habitación estándar con tarifa no reembolsable',1),
(160,40,'Estándar',2,320.00,'Habitación estándar con tarifa no reembolsable',1),
(161,41,'Estándar',2,88.00,'Habitación estándar con tarifa no reembolsable',1),
(162,42,'Estándar',2,416.00,'Habitación estándar con tarifa no reembolsable',1),
(163,43,'Estándar',2,464.00,'Habitación estándar con tarifa no reembolsable',1),
(164,44,'Estándar',2,104.00,'Habitación estándar con tarifa no reembolsable',1),
(165,45,'Estándar',2,400.00,'Habitación estándar con tarifa no reembolsable',1),
(166,46,'Estándar',2,440.00,'Habitación estándar con tarifa no reembolsable',1),
(167,47,'Estándar',2,96.00,'Habitación estándar con tarifa no reembolsable',1),
(168,48,'Estándar',2,960.00,'Habitación estándar con tarifa no reembolsable',1),
(169,49,'Estándar',2,1200.00,'Habitación estándar con tarifa no reembolsable',1),
(170,50,'Estándar',2,160.00,'Habitación estándar con tarifa no reembolsable',1),
(171,51,'Estándar',2,560.00,'Habitación estándar con tarifa no reembolsable',1),
(172,52,'Estándar',2,120.00,'Habitación estándar con tarifa no reembolsable',1),
(173,53,'Estándar',2,360.00,'Habitación estándar con tarifa no reembolsable',1),
(174,54,'Estándar',2,96.00,'Habitación estándar con tarifa no reembolsable',1),
(175,55,'Estándar',2,400.00,'Habitación estándar con tarifa no reembolsable',1),
(176,56,'Estándar',2,104.00,'Habitación estándar con tarifa no reembolsable',1),
(177,57,'Estándar',2,320.00,'Habitación estándar con tarifa no reembolsable',1),
(178,58,'Estándar',2,88.00,'Habitación estándar con tarifa no reembolsable',1),
(179,59,'Estándar',2,304.00,'Habitación estándar con tarifa no reembolsable',1),
(180,60,'Estándar',2,80.00,'Habitación estándar con tarifa no reembolsable',1),
(181,1,'Suite',4,720.00,'Suite de lujo con salón y jacuzzi',1),
(182,2,'Suite',4,396.00,'Suite de lujo con salón y jacuzzi',1),
(183,3,'Suite',4,162.00,'Suite de lujo con salón y jacuzzi',1),
(184,4,'Suite',4,1080.00,'Suite de lujo con salón y jacuzzi',1),
(185,5,'Suite',4,1044.00,'Suite de lujo con salón y jacuzzi',1),
(186,6,'Suite',4,1116.00,'Suite de lujo con salón y jacuzzi',1),
(187,7,'Suite',4,216.00,'Suite de lujo con salón y jacuzzi',1),
(188,8,'Suite',4,846.00,'Suite de lujo con salón y jacuzzi',1),
(189,9,'Suite',4,900.00,'Suite de lujo con salón y jacuzzi',1),
(190,10,'Suite',4,810.00,'Suite de lujo con salón y jacuzzi',1),
(191,11,'Suite',4,144.00,'Suite de lujo con salón y jacuzzi',1),
(192,12,'Suite',4,864.00,'Suite de lujo con salón y jacuzzi',1),
(193,13,'Suite',4,918.00,'Suite de lujo con salón y jacuzzi',1),
(194,14,'Suite',4,378.00,'Suite de lujo con salón y jacuzzi',1),
(195,15,'Suite',4,198.00,'Suite de lujo con salón y jacuzzi',1),
(196,16,'Suite',4,936.00,'Suite de lujo con salón y jacuzzi',1),
(197,17,'Suite',4,1044.00,'Suite de lujo con salón y jacuzzi',1),
(198,18,'Suite',4,468.00,'Suite de lujo con salón y jacuzzi',1),
(199,19,'Suite',4,234.00,'Suite de lujo con salón y jacuzzi',1),
(200,20,'Suite',4,990.00,'Suite de lujo con salón y jacuzzi',1),
(201,21,'Suite',4,1080.00,'Suite de lujo con salón y jacuzzi',1),
(202,22,'Suite',4,540.00,'Suite de lujo con salón y jacuzzi',1),
(203,23,'Suite',4,252.00,'Suite de lujo con salón y jacuzzi',1),
(204,24,'Suite',4,756.00,'Suite de lujo con salón y jacuzzi',1),
(205,25,'Suite',4,810.00,'Suite de lujo con salón y jacuzzi',1),
(206,26,'Suite',4,198.00,'Suite de lujo con salón y jacuzzi',1),
(207,27,'Suite',4,702.00,'Suite de lujo con salón y jacuzzi',1),
(208,28,'Suite',4,756.00,'Suite de lujo con salón y jacuzzi',1),
(209,29,'Suite',4,180.00,'Suite de lujo con salón y jacuzzi',1),
(210,30,'Suite',4,756.00,'Suite de lujo con salón y jacuzzi',1),
(211,31,'Suite',4,900.00,'Suite de lujo con salón y jacuzzi',1),
(212,32,'Suite',4,171.00,'Suite de lujo con salón y jacuzzi',1),
(213,33,'Suite',4,630.00,'Suite de lujo con salón y jacuzzi',1),
(214,34,'Suite',4,666.00,'Suite de lujo con salón y jacuzzi',1),
(215,35,'Suite',4,162.00,'Suite de lujo con salón y jacuzzi',1),
(216,36,'Suite',4,756.00,'Suite de lujo con salón y jacuzzi',1),
(217,37,'Suite',4,810.00,'Suite de lujo con salón y jacuzzi',1),
(218,38,'Suite',4,216.00,'Suite de lujo con salón y jacuzzi',1),
(219,39,'Suite',4,684.00,'Suite de lujo con salón y jacuzzi',1),
(220,40,'Suite',4,720.00,'Suite de lujo con salón y jacuzzi',1),
(221,41,'Suite',4,198.00,'Suite de lujo con salón y jacuzzi',1),
(222,42,'Suite',4,936.00,'Suite de lujo con salón y jacuzzi',1),
(223,43,'Suite',4,1044.00,'Suite de lujo con salón y jacuzzi',1),
(224,44,'Suite',4,234.00,'Suite de lujo con salón y jacuzzi',1),
(225,45,'Suite',4,900.00,'Suite de lujo con salón y jacuzzi',1),
(226,46,'Suite',4,990.00,'Suite de lujo con salón y jacuzzi',1),
(227,47,'Suite',4,216.00,'Suite de lujo con salón y jacuzzi',1),
(228,48,'Suite',4,2160.00,'Suite de lujo con salón y jacuzzi',1),
(229,49,'Suite',4,2700.00,'Suite de lujo con salón y jacuzzi',1),
(230,50,'Suite',4,360.00,'Suite de lujo con salón y jacuzzi',1),
(231,51,'Suite',4,1260.00,'Suite de lujo con salón y jacuzzi',1),
(232,52,'Suite',4,270.00,'Suite de lujo con salón y jacuzzi',1),
(233,53,'Suite',4,810.00,'Suite de lujo con salón y jacuzzi',1),
(234,54,'Suite',4,216.00,'Suite de lujo con salón y jacuzzi',1),
(235,55,'Suite',4,900.00,'Suite de lujo con salón y jacuzzi',1),
(236,56,'Suite',4,234.00,'Suite de lujo con salón y jacuzzi',1),
(237,57,'Suite',4,720.00,'Suite de lujo con salón y jacuzzi',1),
(238,58,'Suite',4,198.00,'Suite de lujo con salón y jacuzzi',1),
(239,59,'Suite',4,684.00,'Suite de lujo con salón y jacuzzi',1),
(240,60,'Suite',4,180.00,'Suite de lujo con salón y jacuzzi',1),
(241,1,'Deluxe',3,880.00,'Habitación deluxe con amenities premium',1),
(242,2,'Deluxe',3,484.00,'Habitación deluxe con amenities premium',1),
(243,3,'Deluxe',3,198.00,'Habitación deluxe con amenities premium',1),
(244,4,'Deluxe',3,1320.00,'Habitación deluxe con amenities premium',1),
(245,5,'Deluxe',3,1276.00,'Habitación deluxe con amenities premium',1),
(246,6,'Deluxe',3,1364.00,'Habitación deluxe con amenities premium',1),
(247,7,'Deluxe',3,264.00,'Habitación deluxe con amenities premium',1),
(248,8,'Deluxe',3,1034.00,'Habitación deluxe con amenities premium',1),
(249,9,'Deluxe',3,1100.00,'Habitación deluxe con amenities premium',1),
(250,10,'Deluxe',3,990.00,'Habitación deluxe con amenities premium',1),
(251,11,'Deluxe',3,176.00,'Habitación deluxe con amenities premium',1),
(252,12,'Deluxe',3,1056.00,'Habitación deluxe con amenities premium',1),
(253,13,'Deluxe',3,1122.00,'Habitación deluxe con amenities premium',1),
(254,14,'Deluxe',3,462.00,'Habitación deluxe con amenities premium',1),
(255,15,'Deluxe',3,242.00,'Habitación deluxe con amenities premium',1),
(256,16,'Deluxe',3,1144.00,'Habitación deluxe con amenities premium',1),
(257,17,'Deluxe',3,1276.00,'Habitación deluxe con amenities premium',1),
(258,18,'Deluxe',3,572.00,'Habitación deluxe con amenities premium',1),
(259,19,'Deluxe',3,286.00,'Habitación deluxe con amenities premium',1),
(260,20,'Deluxe',3,1210.00,'Habitación deluxe con amenities premium',1),
(261,21,'Deluxe',3,1320.00,'Habitación deluxe con amenities premium',1),
(262,22,'Deluxe',3,660.00,'Habitación deluxe con amenities premium',1),
(263,23,'Deluxe',3,308.00,'Habitación deluxe con amenities premium',1),
(264,24,'Deluxe',3,924.00,'Habitación deluxe con amenities premium',1),
(265,25,'Deluxe',3,990.00,'Habitación deluxe con amenities premium',1),
(266,26,'Deluxe',3,242.00,'Habitación deluxe con amenities premium',1),
(267,27,'Deluxe',3,858.00,'Habitación deluxe con amenities premium',1),
(268,28,'Deluxe',3,924.00,'Habitación deluxe con amenities premium',1),
(269,29,'Deluxe',3,220.00,'Habitación deluxe con amenities premium',1),
(270,30,'Deluxe',3,924.00,'Habitación deluxe con amenities premium',1),
(271,31,'Deluxe',3,1100.00,'Habitación deluxe con amenities premium',1),
(272,32,'Deluxe',3,209.00,'Habitación deluxe con amenities premium',1),
(273,33,'Deluxe',3,770.00,'Habitación deluxe con amenities premium',1),
(274,34,'Deluxe',3,814.00,'Habitación deluxe con amenities premium',1),
(275,35,'Deluxe',3,198.00,'Habitación deluxe con amenities premium',1),
(276,36,'Deluxe',3,924.00,'Habitación deluxe con amenities premium',1),
(277,37,'Deluxe',3,990.00,'Habitación deluxe con amenities premium',1),
(278,38,'Deluxe',3,264.00,'Habitación deluxe con amenities premium',1),
(279,39,'Deluxe',3,836.00,'Habitación deluxe con amenities premium',1),
(280,40,'Deluxe',3,880.00,'Habitación deluxe con amenities premium',1),
(281,41,'Deluxe',3,242.00,'Habitación deluxe con amenities premium',1),
(282,42,'Deluxe',3,1144.00,'Habitación deluxe con amenities premium',1),
(283,43,'Deluxe',3,1276.00,'Habitación deluxe con amenities premium',1),
(284,44,'Deluxe',3,286.00,'Habitación deluxe con amenities premium',1),
(285,45,'Deluxe',3,1100.00,'Habitación deluxe con amenities premium',1),
(286,46,'Deluxe',3,1210.00,'Habitación deluxe con amenities premium',1),
(287,47,'Deluxe',3,264.00,'Habitación deluxe con amenities premium',1),
(288,48,'Deluxe',3,2640.00,'Habitación deluxe con amenities premium',1),
(289,49,'Deluxe',3,3300.00,'Habitación deluxe con amenities premium',1),
(290,50,'Deluxe',3,440.00,'Habitación deluxe con amenities premium',1),
(291,51,'Deluxe',3,1540.00,'Habitación deluxe con amenities premium',1),
(292,52,'Deluxe',3,330.00,'Habitación deluxe con amenities premium',1),
(293,53,'Deluxe',3,990.00,'Habitación deluxe con amenities premium',1),
(294,54,'Deluxe',3,264.00,'Habitación deluxe con amenities premium',1),
(295,55,'Deluxe',3,1100.00,'Habitación deluxe con amenities premium',1),
(296,56,'Deluxe',3,286.00,'Habitación deluxe con amenities premium',1),
(297,57,'Deluxe',3,880.00,'Habitación deluxe con amenities premium',1),
(298,58,'Deluxe',3,242.00,'Habitación deluxe con amenities premium',1),
(299,59,'Deluxe',3,836.00,'Habitación deluxe con amenities premium',1),
(300,60,'Deluxe',3,220.00,'Habitación deluxe con amenities premium',1),
(301,1,'Familiar',5,560.00,'Habitación familiar para hasta 5 personas',1),
(302,2,'Familiar',5,308.00,'Habitación familiar para hasta 5 personas',1),
(303,3,'Familiar',5,126.00,'Habitación familiar para hasta 5 personas',1),
(304,4,'Familiar',5,840.00,'Habitación familiar para hasta 5 personas',1),
(305,5,'Familiar',5,812.00,'Habitación familiar para hasta 5 personas',1),
(306,6,'Familiar',5,868.00,'Habitación familiar para hasta 5 personas',1),
(307,7,'Familiar',5,168.00,'Habitación familiar para hasta 5 personas',1),
(308,8,'Familiar',5,658.00,'Habitación familiar para hasta 5 personas',1),
(309,9,'Familiar',5,700.00,'Habitación familiar para hasta 5 personas',1),
(310,10,'Familiar',5,630.00,'Habitación familiar para hasta 5 personas',1),
(311,11,'Familiar',5,112.00,'Habitación familiar para hasta 5 personas',1),
(312,12,'Familiar',5,672.00,'Habitación familiar para hasta 5 personas',1),
(313,13,'Familiar',5,714.00,'Habitación familiar para hasta 5 personas',1),
(314,14,'Familiar',5,294.00,'Habitación familiar para hasta 5 personas',1),
(315,15,'Familiar',5,154.00,'Habitación familiar para hasta 5 personas',1),
(316,16,'Familiar',5,728.00,'Habitación familiar para hasta 5 personas',1),
(317,17,'Familiar',5,812.00,'Habitación familiar para hasta 5 personas',1),
(318,18,'Familiar',5,364.00,'Habitación familiar para hasta 5 personas',1),
(319,19,'Familiar',5,182.00,'Habitación familiar para hasta 5 personas',1),
(320,20,'Familiar',5,770.00,'Habitación familiar para hasta 5 personas',1),
(321,21,'Familiar',5,840.00,'Habitación familiar para hasta 5 personas',1),
(322,22,'Familiar',5,420.00,'Habitación familiar para hasta 5 personas',1),
(323,23,'Familiar',5,196.00,'Habitación familiar para hasta 5 personas',1),
(324,24,'Familiar',5,588.00,'Habitación familiar para hasta 5 personas',1),
(325,25,'Familiar',5,630.00,'Habitación familiar para hasta 5 personas',1),
(326,26,'Familiar',5,154.00,'Habitación familiar para hasta 5 personas',1),
(327,27,'Familiar',5,546.00,'Habitación familiar para hasta 5 personas',1),
(328,28,'Familiar',5,588.00,'Habitación familiar para hasta 5 personas',1),
(329,29,'Familiar',5,140.00,'Habitación familiar para hasta 5 personas',1),
(330,30,'Familiar',5,588.00,'Habitación familiar para hasta 5 personas',1),
(331,31,'Familiar',5,700.00,'Habitación familiar para hasta 5 personas',1),
(332,32,'Familiar',5,133.00,'Habitación familiar para hasta 5 personas',1),
(333,33,'Familiar',5,490.00,'Habitación familiar para hasta 5 personas',1),
(334,34,'Familiar',5,518.00,'Habitación familiar para hasta 5 personas',1),
(335,35,'Familiar',5,126.00,'Habitación familiar para hasta 5 personas',1),
(336,36,'Familiar',5,588.00,'Habitación familiar para hasta 5 personas',1),
(337,37,'Familiar',5,630.00,'Habitación familiar para hasta 5 personas',1),
(338,38,'Familiar',5,168.00,'Habitación familiar para hasta 5 personas',1),
(339,39,'Familiar',5,532.00,'Habitación familiar para hasta 5 personas',1),
(340,40,'Familiar',5,560.00,'Habitación familiar para hasta 5 personas',1),
(341,41,'Familiar',5,154.00,'Habitación familiar para hasta 5 personas',1),
(342,42,'Familiar',5,728.00,'Habitación familiar para hasta 5 personas',1),
(343,43,'Familiar',5,812.00,'Habitación familiar para hasta 5 personas',1),
(344,44,'Familiar',5,182.00,'Habitación familiar para hasta 5 personas',1),
(345,45,'Familiar',5,700.00,'Habitación familiar para hasta 5 personas',1),
(346,46,'Familiar',5,770.00,'Habitación familiar para hasta 5 personas',1),
(347,47,'Familiar',5,168.00,'Habitación familiar para hasta 5 personas',1),
(348,48,'Familiar',5,1680.00,'Habitación familiar para hasta 5 personas',1),
(349,49,'Familiar',5,2100.00,'Habitación familiar para hasta 5 personas',1),
(350,50,'Familiar',5,280.00,'Habitación familiar para hasta 5 personas',1),
(351,51,'Familiar',5,980.00,'Habitación familiar para hasta 5 personas',1),
(352,52,'Familiar',5,210.00,'Habitación familiar para hasta 5 personas',1),
(353,53,'Familiar',5,630.00,'Habitación familiar para hasta 5 personas',1),
(354,54,'Familiar',5,168.00,'Habitación familiar para hasta 5 personas',1),
(355,55,'Familiar',5,700.00,'Habitación familiar para hasta 5 personas',1),
(356,56,'Familiar',5,182.00,'Habitación familiar para hasta 5 personas',1),
(357,57,'Familiar',5,560.00,'Habitación familiar para hasta 5 personas',1),
(358,58,'Familiar',5,154.00,'Habitación familiar para hasta 5 personas',1),
(359,59,'Familiar',5,532.00,'Habitación familiar para hasta 5 personas',1),
(360,60,'Familiar',5,140.00,'Habitación familiar para hasta 5 personas',1);

-- ════════════════════════════════════════════════
--  8. RESERVAS
-- ════════════════════════════════════════════════
INSERT IGNORE INTO `reservas`
  (`id_reserva`,`id_usuario`,`id_hotel`,`id_habitacion`,
   `nombre_huesped`,`dni`,`telefono`,
   `fecha_inicio`,`fecha_fin`,`adultos`,`bebes`,
   `necesita_cuna`,`con_desayuno`,`es_reembolsable`,
   `total_precio`,`estado`,`created_at`) VALUES
(4, 1, 3, 63, 'Jesus Sanchez', '54433560X', '746436536',
 '2026-04-26','2026-04-30', 2,1, 1,1,1, 450.00, 'confirmada','2026-04-26 18:20:44'),
(5, 2, 1, 61, 'Juan García López', '12345678A', '612345678',
 '2026-06-01','2026-06-05', 2,0, 0,1,1, 1440.00,'confirmada', '2026-05-10 10:00:00'),
(6, 2, 9, 189, 'Juan García López', '12345678A', '612345678',
 '2026-07-15','2026-07-20', 2,0, 0,0,0, 4500.00,'confirmada', '2026-05-12 14:30:00'),
(7, 3, 5, 185, 'María Pérez Ruiz', '87654321B', '698765432',
 '2026-05-01','2026-05-03', 2,0, 0,1,1, 2088.00,'completada', '2026-04-20 09:00:00'),
(8, 3, 17, 77, 'María Pérez Ruiz', '87654321B', '698765432',
 '2026-03-10','2026-03-14', 2,0, 0,0,1, 2088.00,'completada', '2026-03-01 11:00:00'),
(9, 2, 43, 343, 'Juan García López', '12345678A', '612345678',
 '2026-02-14','2026-02-17', 4,1, 1,1,0, 2436.00,'completada', '2026-02-01 08:00:00'),
(10, 1, 49, 229, 'Admin SkyTrip', '00000001Z', '900000000',
 '2026-08-01','2026-08-07', 2,0, 0,1,1,16200.00,'confirmada', '2026-05-15 12:00:00'),
(11, 3, 31, 211, 'María Pérez Ruiz', '87654321B', '698765432',
 '2026-01-05','2026-01-10', 2,0, 0,0,1, 4500.00,'cancelada',  '2025-12-20 10:00:00'),
(12, 2, 16, 196, 'Juan García López', '12345678A', '612345678',
 '2026-09-10','2026-09-15', 2,0, 0,1,1, 4680.00,'confirmada', '2026-05-18 16:00:00'),
(13, 3, 42, 282, 'María Pérez Ruiz', '87654321B', '698765432',
 '2026-04-01','2026-04-04', 3,0, 0,1,0, 3432.00,'completada', '2026-03-15 09:30:00');

-- ════════════════════════════════════════════════
--  9. REVIEWS
-- ════════════════════════════════════════════════
INSERT IGNORE INTO `reviews` (`id_hotel`,`id_usuario`,`puntuacion`,`comentario`,`fecha`) VALUES
(1, 2, 5.0, 'Hotel espectacular, el spa es increíble. Repetiré sin duda.','2026-05-12 10:00:00'),
(1, 3, 4.5, 'Muy buen hotel, céntrico y limpio. El desayuno es excelente.','2026-05-13 11:30:00'),
(3, 2, 4.0, 'Buena relación calidad-precio para estar en el centro de Madrid.','2026-04-30 18:00:00'),
(5, 3, 5.0, 'Vistas impresionantes a la Torre Eiffel. Servicio impecable.','2026-05-03 20:00:00'),
(9, 2, 4.5, 'Dormí con vistas al Coliseo. Una experiencia única.','2026-07-20 09:00:00'),
(17, 3, 5.0, 'El mejor hotel que he visitado. Tan cerca del Palacio.','2026-03-14 15:00:00'),
(17, 2, 4.5, 'Lujo absoluto. La suite presidencial es de otro nivel.','2026-03-16 12:00:00'),
(31, 2, 4.0, 'La ubicación en Copacabana es imbatible. Playa enfrente.','2026-02-17 10:00:00'),
(42, 3, 5.0, 'Tokio desde las alturas. Servicio japonés = perfección.','2026-04-04 08:00:00'),
(43, 2, 5.0, 'El Shibuya Grand supera todas las expectativas.','2026-02-17 19:00:00'),
(46, 1, 4.5, 'Con vistas a la Ópera de Sydney. Simplemente mágico.','2026-05-16 14:00:00'),
(49, 1, 5.0, 'El Burj Al Arab es la experiencia de lujo definitiva.','2026-08-07 20:00:00'),
(16, 1, 4.5, 'El Savoy de Londres nunca decepciona. Clase británica.','2026-05-17 10:00:00'),
(4,  3, 4.5, 'París desde la suite: las vistas a la Tour Eiffel son mágicas.','2026-05-03 22:00:00'),
(57, 2, 4.0, 'El Sultan Hotel captura perfectamente la esencia de Estambul.','2026-05-19 09:00:00');

-- ════════════════════════════════════════════════
--  10. FAVORITOS HOTELES
-- ════════════════════════════════════════════════
INSERT IGNORE INTO `favoritos_hoteles` (`id_usuario`,`id_hotel`,`created_at`) VALUES
(1, 3,  '2026-04-26 18:27:50'),
(2, 1,  '2026-05-10 10:05:00'),
(2, 5,  '2026-05-10 10:06:00'),
(2, 9,  '2026-05-12 14:35:00'),
(3, 17, '2026-04-20 09:10:00'),
(3, 43, '2026-03-15 09:35:00'),
(3, 49, '2026-04-21 11:00:00');

-- ════════════════════════════════════════════════
--  11. FAVORITOS DESTINOS
-- ════════════════════════════════════════════════
INSERT IGNORE INTO `favoritos_destinos` (`id_usuario`,`id_pais`,`created_at`) VALUES
(2, 2,  '2026-05-10 10:10:00'),
(2, 3,  '2026-05-10 10:11:00'),
(3, 5,  '2026-04-20 09:15:00'),
(3, 13, '2026-04-20 09:16:00'),
(1, 1,  '2026-04-25 12:00:00');

-- ════════════════════════════════════════════════
--  12. RECENTLY VIEWED
-- ════════════════════════════════════════════════
INSERT IGNORE INTO `recently_viewed` (`id_usuario`,`id_hotel`,`visto_en`) VALUES
(2, 1,  '2026-05-20 08:00:00'),
(2, 5,  '2026-05-20 08:05:00'),
(2, 9,  '2026-05-20 08:10:00'),
(2, 16, '2026-05-20 08:15:00'),
(3, 17, '2026-05-19 20:00:00'),
(3, 43, '2026-05-19 20:05:00'),
(3, 49, '2026-05-19 20:10:00'),
(1, 3,  '2026-05-18 12:00:00');

-- ════════════════════════════════════════════════
--  13. CONTACTO CANALES
-- ════════════════════════════════════════════════
INSERT IGNORE INTO `contacto_canales` (`tipo`,`etiqueta`,`valor`,`icono`,`posicion`,`activo`) VALUES
('phone',    'Teléfono',       'tel:+34 900 000 000',        'phone',    1, 1),
('email',    'Email',          'mailto:info@skytrip.com',    'email',    2, 1),
('whatsapp', 'WhatsApp',       'https://wa.me/34900000000',  'chat',     3, 1),
('web',      'Web de soporte', 'https://soporte.skytrip.com','language', 4, 1);

-- ════════════════════════════════════════════════
--  14. CMS PÁGINAS Y SECCIONES
-- ════════════════════════════════════════════════
INSERT IGNORE INTO `cms_paginas` (`id_pagina`,`clave`,`titulo`,`contenido`,`orden`,`activo`) VALUES
(1,'condiciones','Condiciones de uso',
 'Bienvenido a SkyTrip. El uso de esta aplicación implica la aceptación de las presentes condiciones.',1,1),
(2,'privacidad','Política de privacidad',
 'SkyTrip trata tus datos de forma segura conforme al RGPD.',2,1),
(3,'atencion','Atención al cliente',
 'Puedes contactarnos en soporte@skytrip.app o a través del chat en la app.',3,1),
(4,'destinos','Destinos destacados',
 'Explora los destinos más populares del mundo con SkyTrip.',4,1),
(5,'nosotros','Sobre SkyTrip',
 'SkyTrip es una plataforma de reserva de hoteles disponible en iOS y Android.',5,1);

INSERT IGNORE INTO `cms_secciones` (`id_seccion`,`id_pagina`,`titulo`,`contenido`,`orden`,`activo`) VALUES
(1,1,'Uso aceptable','Queda prohibido el uso fraudulento de la plataforma.',1,1),
(2,1,'Responsabilidad','SkyTrip no se hace responsable de cancelaciones por causas de fuerza mayor.',2,1),
(3,2,'Datos que recogemos','Recogemos nombre, email y datos de reserva.',1,1),
(4,2,'Tus derechos','Puedes solicitar la eliminación de tus datos en cualquier momento.',2,1),
(5,3,'Horario de atención','Disponible 24/7 por chat en la app.',1,1),
(6,4,'Europa','Madrid, París, Roma, Berlín y Londres son nuestros destinos top en Europa.',1,1),
(7,4,'Asia','Tokio, Seúl, Beijing y Dubai te esperan.',2,1),
(8,5,'Nuestra misión','Hacer que viajar sea fácil, seguro y asequible para todos.',1,1);

-- ════════════════════════════════════════════════
--  15. CMS HOME CONFIG
-- ════════════════════════════════════════════════
INSERT IGNORE INTO `cms_home_config` (`clave`,`valor`,`tipo`) VALUES
('fivestar_enabled',   '1', 'bool'),
('centric_enabled',    '1', 'bool'),
('bestvalue_enabled',  '1', 'bool'),
('promo_enabled',      '1', 'bool'),
('recent_enabled',     '1', 'bool'),
('destinations_enabled','1','bool'),
('whyskytrip_enabled', '1', 'bool');

-- ════════════════════════════════════════════════
--  16. CMS FILTROS
-- ════════════════════════════════════════════════
INSERT IGNORE INTO `cms_filtros` (`nombre`,`id_servicio`,`activo`,`orden`) VALUES
('Desayuno incluido', 17, 1, 1),
('Cancelación gratis',18, 1, 2),
('Piscina',           4,  1, 3),
('Admite mascotas',   15, 1, 4),
('Solo adultos',      16, 1, 5),
('WiFi gratis',       1,  1, 6),
('Parking gratis',    3,  1, 7),
('Spa',               9,  1, 8),
('Vista al mar',      22, 1, 9),
('Gimnasio',          5,  1, 10);

-- ════════════════════════════════════════════════
--  17. MONEDAS
-- ════════════════════════════════════════════════
INSERT IGNORE INTO `monedas` (`codigo`,`simbolo`,`tasa_cambio`,`nombre`) VALUES
('EUR','€',  1.000000, 'Euro'),
('USD','$',  1.080000, 'Dólar estadounidense'),
('GBP','£',  0.860000, 'Libra esterlina'),
('JPY','¥',160.000000, 'Yen japonés'),
('MXN','$', 18.500000, 'Peso mexicano');

-- ════════════════════════════════════════════════
--  18. IDIOMAS
-- ════════════════════════════════════════════════
INSERT IGNORE INTO `idiomas` (`codigo`,`nombre`,`activo`) VALUES
('es', 'Español', 1),
('en', 'English', 1);

-- ════════════════════════════════════════════════
--  19. AUTO_INCREMENT
-- ════════════════════════════════════════════════
ALTER TABLE `paises`          AUTO_INCREMENT = 100;
ALTER TABLE `ciudades`        AUTO_INCREMENT = 21;
ALTER TABLE `servicios`       AUTO_INCREMENT = 23;
ALTER TABLE `usuarios`        AUTO_INCREMENT = 4;
ALTER TABLE `hoteles`         AUTO_INCREMENT = 61;
ALTER TABLE `hotel_imagenes`  AUTO_INCREMENT = 1;
ALTER TABLE `habitaciones`    AUTO_INCREMENT = 361;
ALTER TABLE `reservas`        AUTO_INCREMENT = 14;
ALTER TABLE `reviews`         AUTO_INCREMENT = 16;
ALTER TABLE `cms_paginas`     AUTO_INCREMENT = 6;
ALTER TABLE `cms_secciones`   AUTO_INCREMENT = 9;
ALTER TABLE `cms_filtros`     AUTO_INCREMENT = 11;
ALTER TABLE `recently_viewed` AUTO_INCREMENT = 9;

-- ════════════════════════════════════════════════
--  20. VISTAS
-- ════════════════════════════════════════════════
DROP VIEW IF EXISTS `v_hoteles_completos`;
CREATE VIEW `v_hoteles_completos` AS
SELECT
    h.id_hotel,
    h.nombre                                        AS hotel,
    h.estrellas,
    h.puntuacion,
    h.precio_noche,
    h.capacidad_personas,
    h.distancia_centro_km,
    h.distancia_aeropuerto_km,
    h.imagen,
    h.biografia,
    h.activo,
    c.id_ciudad,
    c.nombre                                        AS ciudad,
    p.id_pais,
    p.nombre                                        AS pais,
    p.codigo_iso,
    ROUND(AVG(r.puntuacion), 2)                     AS media_reviews,
    COUNT(DISTINCT r.id_review)                     AS total_reviews,
    GROUP_CONCAT(DISTINCT s.nombre ORDER BY s.nombre SEPARATOR ', ') AS servicios
FROM `hoteles`        h
JOIN `ciudades`       c ON c.id_ciudad    = h.id_ciudad
JOIN `paises`         p ON p.id_pais      = c.id_pais
LEFT JOIN `reviews`   r ON r.id_hotel     = h.id_hotel
LEFT JOIN `hotel_servicios` hs ON hs.id_hotel   = h.id_hotel
LEFT JOIN `servicios` s  ON s.id_servicio = hs.id_servicio
GROUP BY
    h.id_hotel, h.nombre, h.estrellas, h.puntuacion, h.precio_noche,
    h.capacidad_personas, h.distancia_centro_km, h.distancia_aeropuerto_km,
    h.imagen, h.biografia, h.activo,
    c.id_ciudad, c.nombre, p.id_pais, p.nombre, p.codigo_iso;

DROP VIEW IF EXISTS `v_reservas_activas`;
CREATE VIEW `v_reservas_activas` AS
SELECT
    r.*,
    u.usuario,
    u.email,
    h.nombre   AS hotel,
    c.nombre   AS ciudad,
    p.nombre   AS pais
FROM `reservas`  r
JOIN `usuarios`  u ON u.id_usuario = r.id_usuario
JOIN `hoteles`   h ON h.id_hotel   = r.id_hotel
JOIN `ciudades`  c ON c.id_ciudad  = h.id_ciudad
JOIN `paises`    p ON p.id_pais    = c.id_pais
WHERE r.estado    = 'confirmada'
  AND r.fecha_fin >= CURDATE();

DROP VIEW IF EXISTS `v_estadisticas_hotel`;
CREATE VIEW `v_estadisticas_hotel` AS
SELECT
    h.id_hotel,
    h.nombre                            AS hotel,
    COUNT(DISTINCT res.id_reserva)      AS total_reservas,
    IFNULL(SUM(res.total_precio), 0)    AS ingresos_totales,
    ROUND(AVG(rv.puntuacion), 2)        AS media_puntuacion,
    COUNT(DISTINCT rv.id_review)        AS total_reviews,
    COUNT(DISTINCT fav.id_usuario)      AS total_favoritos
FROM `hoteles`   h
LEFT JOIN `reservas`         res ON res.id_hotel  = h.id_hotel
LEFT JOIN `reviews`          rv  ON rv.id_hotel   = h.id_hotel
LEFT JOIN `favoritos_hoteles` fav ON fav.id_hotel = h.id_hotel
GROUP BY h.id_hotel, h.nombre;

-- ════════════════════════════════════════════════
--  21. STORED PROCEDURES
-- ════════════════════════════════════════════════
DELIMITER $$

DROP PROCEDURE IF EXISTS `sp_cancelar_reserva`$$
CREATE PROCEDURE `sp_cancelar_reserva`(
    IN p_id_reserva INT,
    IN p_id_usuario INT
)
BEGIN
    DECLARE v_estado  VARCHAR(20);
    DECLARE v_propietario INT;

    SELECT estado, id_usuario
    INTO   v_estado, v_propietario
    FROM   reservas
    WHERE  id_reserva = p_id_reserva
    LIMIT  1;

    IF v_propietario IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Reserva no encontrada.';
    END IF;

    IF v_propietario <> p_id_usuario THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No tienes permiso para cancelar esta reserva.';
    END IF;

    IF v_estado = 'cancelada' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'La reserva ya está cancelada.';
    END IF;

    IF v_estado = 'completada' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede cancelar una reserva completada.';
    END IF;

    UPDATE reservas
    SET    estado = 'cancelada'
    WHERE  id_reserva = p_id_reserva;

    SELECT 'OK' AS resultado, p_id_reserva AS id_reserva;
END$$

DROP PROCEDURE IF EXISTS `sp_toggle_favorito`$$
CREATE PROCEDURE `sp_toggle_favorito`(
    IN p_id_usuario INT,
    IN p_id_hotel   INT
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    SELECT COUNT(*) INTO v_existe
    FROM   favoritos_hoteles
    WHERE  id_usuario = p_id_usuario
      AND  id_hotel   = p_id_hotel;

    IF v_existe > 0 THEN
        DELETE FROM favoritos_hoteles
        WHERE  id_usuario = p_id_usuario
          AND  id_hotel   = p_id_hotel;
        SELECT 'removed' AS accion;
    ELSE
        INSERT INTO favoritos_hoteles (id_usuario, id_hotel)
        VALUES (p_id_usuario, p_id_hotel);
        SELECT 'added' AS accion;
    END IF;
END$$

DROP PROCEDURE IF EXISTS `sp_actualizar_puntuacion_hotel`$$
CREATE PROCEDURE `sp_actualizar_puntuacion_hotel`(
    IN p_id_hotel INT
)
BEGIN
    DECLARE v_media DECIMAL(3,1) DEFAULT 0.0;

    SELECT ROUND(AVG(puntuacion) * 2, 1)
    INTO   v_media
    FROM   reviews
    WHERE  id_hotel = p_id_hotel;

    UPDATE hoteles
    SET    puntuacion = IFNULL(v_media, 0.0)
    WHERE  id_hotel   = p_id_hotel;
END$$

DELIMITER ;

-- ════════════════════════════════════════════════
--  22. TRIGGERS
-- ════════════════════════════════════════════════
DELIMITER $$

DROP TRIGGER IF EXISTS `trg_after_insert_review`$$
CREATE TRIGGER `trg_after_insert_review`
AFTER INSERT ON `reviews`
FOR EACH ROW
BEGIN
    CALL sp_actualizar_puntuacion_hotel(NEW.id_hotel);
END$$

DROP TRIGGER IF EXISTS `trg_after_delete_review`$$
CREATE TRIGGER `trg_after_delete_review`
AFTER DELETE ON `reviews`
FOR EACH ROW
BEGIN
    CALL sp_actualizar_puntuacion_hotel(OLD.id_hotel);
END$$

DROP TRIGGER IF EXISTS `trg_after_update_review`$$
CREATE TRIGGER `trg_after_update_review`
AFTER UPDATE ON `reviews`
FOR EACH ROW
BEGIN
    CALL sp_actualizar_puntuacion_hotel(NEW.id_hotel);
END$$

DROP TRIGGER IF EXISTS `trg_before_delete_usuario`$$
CREATE TRIGGER `trg_before_delete_usuario`
BEFORE DELETE ON `usuarios`
FOR EACH ROW
BEGIN
    DECLARE v_count INT DEFAULT 0;

    SELECT COUNT(*) INTO v_count
    FROM   reservas
    WHERE  id_usuario = OLD.id_usuario
      AND  estado     = 'confirmada'
      AND  fecha_fin  >= CURDATE();

    IF v_count > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede eliminar un usuario con reservas activas.';
    END IF;
END$$

DELIMITER ;

-- ════════════════════════════════════════════════
--  23. IMÁGENES DE HOTELES (portadas + galería)
-- ════════════════════════════════════════════════

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1543783207-ec64e4d95325?w=800&q=80' WHERE id_hotel = 3;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&q=80' WHERE id_hotel = 4;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?w=800&q=80' WHERE id_hotel = 5;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1605723517503-3cadb5818a0c?w=800&q=80' WHERE id_hotel = 6;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80' WHERE id_hotel = 7;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800&q=80' WHERE id_hotel = 8;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1529154036614-a60975f5c760?w=800&q=80' WHERE id_hotel = 9;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80' WHERE id_hotel = 10;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80' WHERE id_hotel = 11;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1560969184-10fe8719e047?w=800&q=80' WHERE id_hotel = 12;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1578681041175-9717c638f520?w=800&q=80' WHERE id_hotel = 13;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1601918774946-25832a4be0d6?w=800&q=80' WHERE id_hotel = 14;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1455587734955-081b22074882?w=800&q=80' WHERE id_hotel = 15;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800&q=80' WHERE id_hotel = 16;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1486299267070-83823f5448dd?w=800&q=80' WHERE id_hotel = 17;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=800&q=80' WHERE id_hotel = 18;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1595576508898-0ad5c879a061?w=800&q=80' WHERE id_hotel = 19;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1485871981521-5b1fd3805eee?w=800&q=80' WHERE id_hotel = 20;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=800&q=80' WHERE id_hotel = 21;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80' WHERE id_hotel = 22;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80' WHERE id_hotel = 23;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1517935706615-2717063c2225?w=800&q=80' WHERE id_hotel = 24;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1507992781348-310259076fe0?w=800&q=80' WHERE id_hotel = 25;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80' WHERE id_hotel = 26;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1585464231875-d9ef1f5ad396?w=800&q=80' WHERE id_hotel = 27;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800&q=80' WHERE id_hotel = 28;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80' WHERE id_hotel = 29;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=800&q=80' WHERE id_hotel = 30;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1544984243-ec57ea16fe25?w=800&q=80' WHERE id_hotel = 31;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80' WHERE id_hotel = 32;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1589909202802-8f4aadce1849?w=800&q=80' WHERE id_hotel = 33;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80' WHERE id_hotel = 34;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80' WHERE id_hotel = 35;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=800&q=80' WHERE id_hotel = 36;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=800&q=80' WHERE id_hotel = 37;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80' WHERE id_hotel = 38;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1509356843151-3e7d96241e11?w=800&q=80' WHERE id_hotel = 39;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1548872591-a42d9f9f4f87?w=800&q=80' WHERE id_hotel = 40;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80' WHERE id_hotel = 41;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&q=80' WHERE id_hotel = 42;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=800&q=80' WHERE id_hotel = 43;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1494522358652-f30e61a60313?w=800&q=80' WHERE id_hotel = 44;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800&q=80' WHERE id_hotel = 45;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1524397057410-1e775ed476f3?w=800&q=80' WHERE id_hotel = 46;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80' WHERE id_hotel = 47;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800&q=80' WHERE id_hotel = 48;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1580674684081-7617fbf3d745?w=800&q=80' WHERE id_hotel = 49;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80' WHERE id_hotel = 50;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1515488764276-beab7607c1e6?w=800&q=80' WHERE id_hotel = 51;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80' WHERE id_hotel = 52;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=800&q=80' WHERE id_hotel = 53;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1567861911437-538298e4232c?w=800&q=80' WHERE id_hotel = 54;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1517154421773-0529f29ea451?w=800&q=80' WHERE id_hotel = 55;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80' WHERE id_hotel = 56;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=800&q=80' WHERE id_hotel = 57;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80' WHERE id_hotel = 58;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1580060839134-75a5edca2e99?w=800&q=80' WHERE id_hotel = 59;
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80' WHERE id_hotel = 60;

-- ── Galería hotel_imagenes ────────────────────────
DELETE FROM hotel_imagenes WHERE id_hotel > 0;

INSERT INTO hotel_imagenes (id_hotel, url, orden) VALUES
(1,'https://images.unsplash.com/photo-1543783207-ec64e4d95325?w=800&q=80',1),
(1,'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80',2),
(1,'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80',3),
(1,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),
(2,'https://cf.bstatic.com/xdata/images/hotel/max1024x768/614285764.jpg?k=e25267e3542d2cf3256ecd21ef5a72523f326f0abf2330a3c63cbc1e2f0a88d8&o=',1),
(2,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',2),
(2,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',3),
(3,'https://images.unsplash.com/photo-1543783207-ec64e4d95325?w=800&q=80',1),
(3,'https://images.unsplash.com/photo-1595576508898-0ad5c879a061?w=800&q=80',2),
(3,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',3),
(4,'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&q=80',1),
(4,'https://images.unsplash.com/photo-1541417904950-b855846fe074?w=800&q=80',2),
(4,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(4,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),
(5,'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?w=800&q=80',1),
(5,'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&q=80',2),
(5,'https://images.unsplash.com/photo-1545126982-2d6429a0e50d?w=800&q=80',3),
(5,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',4),
(6,'https://images.unsplash.com/photo-1605723517503-3cadb5818a0c?w=800&q=80',1),
(6,'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&q=80',2),
(6,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(7,'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80',1),
(7,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),
(8,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800&q=80',1),
(8,'https://images.unsplash.com/photo-1529154036614-a60975f5c760?w=800&q=80',2),
(8,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(8,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),
(9,'https://images.unsplash.com/photo-1529154036614-a60975f5c760?w=800&q=80',1),
(9,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800&q=80',2),
(9,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(9,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',4),
(10,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',1),
(10,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800&q=80',2),
(10,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),
(11,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(11,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800&q=80',2),
(12,'https://images.unsplash.com/photo-1560969184-10fe8719e047?w=800&q=80',1),
(12,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',2),
(12,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),
(12,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',4),
(13,'https://images.unsplash.com/photo-1578681041175-9717c638f520?w=800&q=80',1),
(13,'https://images.unsplash.com/photo-1560969184-10fe8719e047?w=800&q=80',2),
(13,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(14,'https://images.unsplash.com/photo-1601918774946-25832a4be0d6?w=800&q=80',1),
(14,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),
(14,'https://images.unsplash.com/photo-1560969184-10fe8719e047?w=800&q=80',3),
(15,'https://images.unsplash.com/photo-1455587734955-081b22074882?w=800&q=80',1),
(15,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),
(16,'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800&q=80',1),
(16,'https://images.unsplash.com/photo-1486299267070-83823f5448dd?w=800&q=80',2),
(16,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(16,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),
(17,'https://images.unsplash.com/photo-1486299267070-83823f5448dd?w=800&q=80',1),
(17,'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800&q=80',2),
(17,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(18,'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=800&q=80',1),
(18,'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800&q=80',2),
(18,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',3),
(19,'https://images.unsplash.com/photo-1595576508898-0ad5c879a061?w=800&q=80',1),
(19,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),
(20,'https://images.unsplash.com/photo-1485871981521-5b1fd3805eee?w=800&q=80',1),
(20,'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=800&q=80',2),
(20,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(20,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),
(21,'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=800&q=80',1),
(21,'https://images.unsplash.com/photo-1485871981521-5b1fd3805eee?w=800&q=80',2),
(21,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(22,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',1),
(22,'https://images.unsplash.com/photo-1485871981521-5b1fd3805eee?w=800&q=80',2),
(22,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',3),
(23,'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80',1),
(23,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),
(24,'https://images.unsplash.com/photo-1517935706615-2717063c2225?w=800&q=80',1),
(24,'https://images.unsplash.com/photo-1507992781348-310259076fe0?w=800&q=80',2),
(24,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(25,'https://images.unsplash.com/photo-1507992781348-310259076fe0?w=800&q=80',1),
(25,'https://images.unsplash.com/photo-1517935706615-2717063c2225?w=800&q=80',2),
(25,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),
(26,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(26,'https://images.unsplash.com/photo-1507992781348-310259076fe0?w=800&q=80',2),
(27,'https://images.unsplash.com/photo-1585464231875-d9ef1f5ad396?w=800&q=80',1),
(27,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',2),
(27,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),
(28,'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800&q=80',1),
(28,'https://images.unsplash.com/photo-1585464231875-d9ef1f5ad396?w=800&q=80',2),
(28,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',3),
(29,'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80',1),
(29,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),
(30,'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=800&q=80',1),
(30,'https://images.unsplash.com/photo-1544984243-ec57ea16fe25?w=800&q=80',2),
(30,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(30,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),
(31,'https://images.unsplash.com/photo-1544984243-ec57ea16fe25?w=800&q=80',1),
(31,'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=800&q=80',2),
(31,'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',3),
(31,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',4),
(32,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(32,'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=800&q=80',2),
(33,'https://images.unsplash.com/photo-1589909202802-8f4aadce1849?w=800&q=80',1),
(33,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',2),
(33,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),
(34,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',1),
(34,'https://images.unsplash.com/photo-1589909202802-8f4aadce1849?w=800&q=80',2),
(34,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',3),
(35,'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80',1),
(35,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),
(36,'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=800&q=80',1),
(36,'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=800&q=80',2),
(36,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(37,'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=800&q=80',1),
(37,'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=800&q=80',2),
(37,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),
(37,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',4),
(38,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(38,'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=800&q=80',2),
(39,'https://images.unsplash.com/photo-1509356843151-3e7d96241e11?w=800&q=80',1),
(39,'https://images.unsplash.com/photo-1548872591-a42d9f9f4f87?w=800&q=80',2),
(39,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(40,'https://images.unsplash.com/photo-1548872591-a42d9f9f4f87?w=800&q=80',1),
(40,'https://images.unsplash.com/photo-1509356843151-3e7d96241e11?w=800&q=80',2),
(40,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),
(41,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(41,'https://images.unsplash.com/photo-1509356843151-3e7d96241e11?w=800&q=80',2),
(42,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&q=80',1),
(42,'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=800&q=80',2),
(42,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(42,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),
(43,'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=800&q=80',1),
(43,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&q=80',2),
(43,'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=800&q=80',3),
(43,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',4),
(44,'https://images.unsplash.com/photo-1494522358652-f30e61a60313?w=800&q=80',1),
(44,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),
(45,'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800&q=80',1),
(45,'https://images.unsplash.com/photo-1524397057410-1e775ed476f3?w=800&q=80',2),
(45,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(45,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),
(46,'https://images.unsplash.com/photo-1524397057410-1e775ed476f3?w=800&q=80',1),
(46,'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800&q=80',2),
(46,'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',3),
(46,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',4),
(47,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(47,'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800&q=80',2),
(48,'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800&q=80',1),
(48,'https://images.unsplash.com/photo-1580674684081-7617fbf3d745?w=800&q=80',2),
(48,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(48,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),
(49,'https://images.unsplash.com/photo-1580674684081-7617fbf3d745?w=800&q=80',1),
(49,'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800&q=80',2),
(49,'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80',3),
(49,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',4),
(50,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',1),
(50,'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800&q=80',2),
(50,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',3),
(51,'https://images.unsplash.com/photo-1515488764276-beab7607c1e6?w=800&q=80',1),
(51,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',2),
(51,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),
(52,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(52,'https://images.unsplash.com/photo-1515488764276-beab7607c1e6?w=800&q=80',2),
(53,'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=800&q=80',1),
(53,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',2),
(53,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),
(54,'https://images.unsplash.com/photo-1567861911437-538298e4232c?w=800&q=80',1),
(54,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),
(55,'https://images.unsplash.com/photo-1517154421773-0529f29ea451?w=800&q=80',1),
(55,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',2),
(55,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),
(56,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(56,'https://images.unsplash.com/photo-1517154421773-0529f29ea451?w=800&q=80',2),
(57,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=800&q=80',1),
(57,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',2),
(57,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),
(57,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',4),
(58,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(58,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=800&q=80',2),
(59,'https://images.unsplash.com/photo-1580060839134-75a5edca2e99?w=800&q=80',1),
(59,'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',2),
(59,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(59,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),
(60,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(60,'https://images.unsplash.com/photo-1580060839134-75a5edca2e99?w=800&q=80',2);

-- ════════════════════════════════════════════════
--  24. RESTAURAR CONFIGURACIÓN
-- ════════════════════════════════════════════════
SET FOREIGN_KEY_CHECKS = 1;
SET SQL_SAFE_UPDATES   = 1;

-- ════════════════════════════════════════════════
--  FIN DEL SCRIPT  skytrip_db.sql
-- ════════════════════════════════════════════════
