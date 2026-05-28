-- ============================================================
--  SkyTrip – Imágenes para los 60 hoteles de skytrip_db
--  Generado: 2026-05-25
--  Imágenes de Unsplash (libres, sin API key, 800px)
--  · Actualiza hoteles.imagen  (campo principal, portada)
--  · Rellena hotel_imagenes    (galería de varias fotos)
--  · Hoteles 1 y 2 ya tienen imagen → se respetan
-- ============================================================

USE `skytrip_db`;

-- ════════════════════════════════════════════════
--  BLOQUE 1 – hoteles.imagen  (portada principal)
--  Solo actualiza los hoteles cuyo campo imagen
--  esté NULL o vacío (hoteles 3-60)
-- ════════════════════════════════════════════════

-- ── MADRID (id_ciudad = 1) ───────────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1543783207-ec64e4d95325?w=800&q=80'
WHERE id_hotel = 3 AND (imagen IS NULL OR imagen = '');   -- Hostal Madrid Centro

-- ── PARIS (id_ciudad = 2) ────────────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&q=80'
WHERE id_hotel = 4 AND (imagen IS NULL OR imagen = '');   -- Paris Luxury Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?w=800&q=80'
WHERE id_hotel = 5 AND (imagen IS NULL OR imagen = '');   -- Eiffel Palace

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1605723517503-3cadb5818a0c?w=800&q=80'
WHERE id_hotel = 6 AND (imagen IS NULL OR imagen = '');   -- Louvre Grand Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80'
WHERE id_hotel = 7 AND (imagen IS NULL OR imagen = '');   -- Paris Comfort Inn

-- ── ROMA (id_ciudad = 3) ─────────────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800&q=80'
WHERE id_hotel = 8 AND (imagen IS NULL OR imagen = '');   -- Rome Imperial Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1529154036614-a60975f5c760?w=800&q=80'
WHERE id_hotel = 9 AND (imagen IS NULL OR imagen = '');   -- Colosseum Palace

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80'
WHERE id_hotel = 10 AND (imagen IS NULL OR imagen = ''); -- Rome Luxury Suites

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80'
WHERE id_hotel = 11 AND (imagen IS NULL OR imagen = ''); -- Rome Budget Stay

-- ── BERLIN (id_ciudad = 4) ───────────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1560969184-10fe8719e047?w=800&q=80'
WHERE id_hotel = 12 AND (imagen IS NULL OR imagen = ''); -- Berlin Grand Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1578681041175-9717c638f520?w=800&q=80'
WHERE id_hotel = 13 AND (imagen IS NULL OR imagen = ''); -- Brandenburg Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1601918774946-25832a4be0d6?w=800&q=80'
WHERE id_hotel = 14 AND (imagen IS NULL OR imagen = ''); -- Berlin Business Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1455587734955-081b22074882?w=800&q=80'
WHERE id_hotel = 15 AND (imagen IS NULL OR imagen = ''); -- Berlin Easy Stay

-- ── LONDRES (id_ciudad = 5) ──────────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800&q=80'
WHERE id_hotel = 16 AND (imagen IS NULL OR imagen = ''); -- London Savoy Palace

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1486299267070-83823f5448dd?w=800&q=80'
WHERE id_hotel = 17 AND (imagen IS NULL OR imagen = ''); -- Buckingham Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=800&q=80'
WHERE id_hotel = 18 AND (imagen IS NULL OR imagen = ''); -- London Bridge Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1595576508898-0ad5c879a061?w=800&q=80'
WHERE id_hotel = 19 AND (imagen IS NULL OR imagen = ''); -- London Budget Rooms

-- ── NEW YORK (id_ciudad = 6) ─────────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1485871981521-5b1fd3805eee?w=800&q=80'
WHERE id_hotel = 20 AND (imagen IS NULL OR imagen = ''); -- New York Plaza

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=800&q=80'
WHERE id_hotel = 21 AND (imagen IS NULL OR imagen = ''); -- Times Square Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80'
WHERE id_hotel = 22 AND (imagen IS NULL OR imagen = ''); -- NY Manhattan Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80'
WHERE id_hotel = 23 AND (imagen IS NULL OR imagen = ''); -- NY Economy Hotel

-- ── TORONTO (id_ciudad = 7) ──────────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1517935706615-2717063c2225?w=800&q=80'
WHERE id_hotel = 24 AND (imagen IS NULL OR imagen = ''); -- Toronto Royal Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1507992781348-310259076fe0?w=800&q=80'
WHERE id_hotel = 25 AND (imagen IS NULL OR imagen = ''); -- CN Tower Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80'
WHERE id_hotel = 26 AND (imagen IS NULL OR imagen = ''); -- Toronto Budget Inn

-- ── CIUDAD DE MEXICO (id_ciudad = 8) ─────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1585464231875-d9ef1f5ad396?w=800&q=80'
WHERE id_hotel = 27 AND (imagen IS NULL OR imagen = ''); -- Mexico Palace Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800&q=80'
WHERE id_hotel = 28 AND (imagen IS NULL OR imagen = ''); -- Aztec Grand Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80'
WHERE id_hotel = 29 AND (imagen IS NULL OR imagen = ''); -- CDMX Budget Hotel

-- ── RIO DE JANEIRO (id_ciudad = 9) ───────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=800&q=80'
WHERE id_hotel = 30 AND (imagen IS NULL OR imagen = ''); -- Rio Luxury Resort

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1544984243-ec57ea16fe25?w=800&q=80'
WHERE id_hotel = 31 AND (imagen IS NULL OR imagen = ''); -- Copacabana Palace

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80'
WHERE id_hotel = 32 AND (imagen IS NULL OR imagen = ''); -- Rio Budget Stay

-- ── BUENOS AIRES (id_ciudad = 10) ────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1589909202802-8f4aadce1849?w=800&q=80'
WHERE id_hotel = 33 AND (imagen IS NULL OR imagen = ''); -- Buenos Aires Palace

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80'
WHERE id_hotel = 34 AND (imagen IS NULL OR imagen = ''); -- Tango Grand Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80'
WHERE id_hotel = 35 AND (imagen IS NULL OR imagen = ''); -- Buenos Aires Budget Hotel

-- ── OSLO (id_ciudad = 11) ────────────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=800&q=80'
WHERE id_hotel = 36 AND (imagen IS NULL OR imagen = ''); -- Oslo Grand Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=800&q=80'
WHERE id_hotel = 37 AND (imagen IS NULL OR imagen = ''); -- Fjord View Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80'
WHERE id_hotel = 38 AND (imagen IS NULL OR imagen = ''); -- Oslo Budget Hotel

-- ── ESTOCOLMO (id_ciudad = 12) ───────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1509356843151-3e7d96241e11?w=800&q=80'
WHERE id_hotel = 39 AND (imagen IS NULL OR imagen = ''); -- Stockholm Palace

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1548872591-a42d9f9f4f87?w=800&q=80'
WHERE id_hotel = 40 AND (imagen IS NULL OR imagen = ''); -- Nobel Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80'
WHERE id_hotel = 41 AND (imagen IS NULL OR imagen = ''); -- Stockholm Budget Hotel

-- ── TOKYO (id_ciudad = 13) ───────────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&q=80'
WHERE id_hotel = 42 AND (imagen IS NULL OR imagen = ''); -- Tokyo Luxury Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=800&q=80'
WHERE id_hotel = 43 AND (imagen IS NULL OR imagen = ''); -- Shibuya Grand Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1494522358652-f30e61a60313?w=800&q=80'
WHERE id_hotel = 44 AND (imagen IS NULL OR imagen = ''); -- Tokyo Budget Inn

-- ── SYDNEY (id_ciudad = 14) ──────────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800&q=80'
WHERE id_hotel = 45 AND (imagen IS NULL OR imagen = ''); -- Sydney Luxury Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1524397057410-1e775ed476f3?w=800&q=80'
WHERE id_hotel = 46 AND (imagen IS NULL OR imagen = ''); -- Opera House Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80'
WHERE id_hotel = 47 AND (imagen IS NULL OR imagen = ''); -- Sydney Budget Hotel

-- ── DUBAI (id_ciudad = 15) ───────────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800&q=80'
WHERE id_hotel = 48 AND (imagen IS NULL OR imagen = ''); -- Dubai Luxury Palace

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1580674684081-7617fbf3d745?w=800&q=80'
WHERE id_hotel = 49 AND (imagen IS NULL OR imagen = ''); -- Burj Al Arab Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80'
WHERE id_hotel = 50 AND (imagen IS NULL OR imagen = ''); -- Dubai City Hotel

-- ── ZURICH (id_ciudad = 16) ──────────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1515488764276-beab7607c1e6?w=800&q=80'
WHERE id_hotel = 51 AND (imagen IS NULL OR imagen = ''); -- Zurich Elite Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80'
WHERE id_hotel = 52 AND (imagen IS NULL OR imagen = ''); -- Zurich Budget Hotel

-- ── BEIJING (id_ciudad = 17) ─────────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=800&q=80'
WHERE id_hotel = 53 AND (imagen IS NULL OR imagen = ''); -- Beijing Imperial Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1567861911437-538298e4232c?w=800&q=80'
WHERE id_hotel = 54 AND (imagen IS NULL OR imagen = ''); -- Beijing Budget Inn

-- ── SEOUL (id_ciudad = 18) ───────────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1517154421773-0529f29ea451?w=800&q=80'
WHERE id_hotel = 55 AND (imagen IS NULL OR imagen = ''); -- Seoul Sky Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80'
WHERE id_hotel = 56 AND (imagen IS NULL OR imagen = ''); -- Seoul Budget Hotel

-- ── ESTAMBUL (id_ciudad = 19) ────────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=800&q=80'
WHERE id_hotel = 57 AND (imagen IS NULL OR imagen = ''); -- Istanbul Sultan Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80'
WHERE id_hotel = 58 AND (imagen IS NULL OR imagen = ''); -- Istanbul Budget Hotel

-- ── CAPE TOWN (id_ciudad = 20) ───────────────────
UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1580060839134-75a5edca2e99?w=800&q=80'
WHERE id_hotel = 59 AND (imagen IS NULL OR imagen = ''); -- Cape Town Ocean Hotel

UPDATE hoteles SET imagen = 'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80'
WHERE id_hotel = 60 AND (imagen IS NULL OR imagen = ''); -- Cape Town Budget Hotel


-- ════════════════════════════════════════════════
--  BLOQUE 2 – hotel_imagenes  (galería de fotos)
--  3-4 imágenes adicionales por hotel
--  Se elimina lo anterior para evitar duplicados
-- ════════════════════════════════════════════════

DELETE FROM hotel_imagenes;

INSERT INTO hotel_imagenes (id_hotel, url, orden) VALUES

-- ── HOTEL 1 – Hotel Central Madrid ───────────────
(1,'https://images.unsplash.com/photo-1543783207-ec64e4d95325?w=800&q=80',1),
(1,'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=800&q=80',2),
(1,'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80',3),
(1,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),

-- ── HOTEL 2 – Gran Via Palace ────────────────────
(2,'https://cf.bstatic.com/xdata/images/hotel/max1024x768/614285764.jpg?k=e25267e3542d2cf3256ecd21ef5a72523f326f0abf2330a3c63cbc1e2f0a88d8&o=',1),
(2,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',2),
(2,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',3),

-- ── HOTEL 3 – Hostal Madrid Centro ───────────────
(3,'https://images.unsplash.com/photo-1543783207-ec64e4d95325?w=800&q=80',1),
(3,'https://images.unsplash.com/photo-1595576508898-0ad5c879a061?w=800&q=80',2),
(3,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',3),

-- ── HOTEL 4 – Paris Luxury Hotel ─────────────────
(4,'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&q=80',1),
(4,'https://images.unsplash.com/photo-1541417904950-b855846fe074?w=800&q=80',2),
(4,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(4,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),

-- ── HOTEL 5 – Eiffel Palace ───────────────────────
(5,'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?w=800&q=80',1),
(5,'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&q=80',2),
(5,'https://images.unsplash.com/photo-1545126982-2d6429a0e50d?w=800&q=80',3),
(5,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',4),

-- ── HOTEL 6 – Louvre Grand Hotel ─────────────────
(6,'https://images.unsplash.com/photo-1605723517503-3cadb5818a0c?w=800&q=80',1),
(6,'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=800&q=80',2),
(6,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),

-- ── HOTEL 7 – Paris Comfort Inn ──────────────────
(7,'https://images.unsplash.com/photo-1551882547-ff40c63fe5fa?w=800&q=80',1),
(7,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),

-- ── HOTEL 8 – Rome Imperial Hotel ────────────────
(8,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800&q=80',1),
(8,'https://images.unsplash.com/photo-1529154036614-a60975f5c760?w=800&q=80',2),
(8,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(8,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),

-- ── HOTEL 9 – Colosseum Palace ───────────────────
(9,'https://images.unsplash.com/photo-1529154036614-a60975f5c760?w=800&q=80',1),
(9,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800&q=80',2),
(9,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(9,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',4),

-- ── HOTEL 10 – Rome Luxury Suites ────────────────
(10,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',1),
(10,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800&q=80',2),
(10,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),

-- ── HOTEL 11 – Rome Budget Stay ──────────────────
(11,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(11,'https://images.unsplash.com/photo-1552832230-c0197dd311b5?w=800&q=80',2),

-- ── HOTEL 12 – Berlin Grand Hotel ────────────────
(12,'https://images.unsplash.com/photo-1560969184-10fe8719e047?w=800&q=80',1),
(12,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',2),
(12,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),
(12,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',4),

-- ── HOTEL 13 – Brandenburg Hotel ─────────────────
(13,'https://images.unsplash.com/photo-1578681041175-9717c638f520?w=800&q=80',1),
(13,'https://images.unsplash.com/photo-1560969184-10fe8719e047?w=800&q=80',2),
(13,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),

-- ── HOTEL 14 – Berlin Business Hotel ─────────────
(14,'https://images.unsplash.com/photo-1601918774946-25832a4be0d6?w=800&q=80',1),
(14,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),
(14,'https://images.unsplash.com/photo-1560969184-10fe8719e047?w=800&q=80',3),

-- ── HOTEL 15 – Berlin Easy Stay ──────────────────
(15,'https://images.unsplash.com/photo-1455587734955-081b22074882?w=800&q=80',1),
(15,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),

-- ── HOTEL 16 – London Savoy Palace ───────────────
(16,'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800&q=80',1),
(16,'https://images.unsplash.com/photo-1486299267070-83823f5448dd?w=800&q=80',2),
(16,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(16,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),

-- ── HOTEL 17 – Buckingham Hotel ──────────────────
(17,'https://images.unsplash.com/photo-1486299267070-83823f5448dd?w=800&q=80',1),
(17,'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800&q=80',2),
(17,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),

-- ── HOTEL 18 – London Bridge Hotel ───────────────
(18,'https://images.unsplash.com/photo-1554995207-c18c203602cb?w=800&q=80',1),
(18,'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?w=800&q=80',2),
(18,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',3),

-- ── HOTEL 19 – London Budget Rooms ───────────────
(19,'https://images.unsplash.com/photo-1595576508898-0ad5c879a061?w=800&q=80',1),
(19,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),

-- ── HOTEL 20 – New York Plaza ─────────────────────
(20,'https://images.unsplash.com/photo-1485871981521-5b1fd3805eee?w=800&q=80',1),
(20,'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=800&q=80',2),
(20,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(20,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),

-- ── HOTEL 21 – Times Square Hotel ────────────────
(21,'https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=800&q=80',1),
(21,'https://images.unsplash.com/photo-1485871981521-5b1fd3805eee?w=800&q=80',2),
(21,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),

-- ── HOTEL 22 – NY Manhattan Hotel ────────────────
(22,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',1),
(22,'https://images.unsplash.com/photo-1485871981521-5b1fd3805eee?w=800&q=80',2),
(22,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',3),

-- ── HOTEL 23 – NY Economy Hotel ──────────────────
(23,'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80',1),
(23,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),

-- ── HOTEL 24 – Toronto Royal Hotel ───────────────
(24,'https://images.unsplash.com/photo-1517935706615-2717063c2225?w=800&q=80',1),
(24,'https://images.unsplash.com/photo-1507992781348-310259076fe0?w=800&q=80',2),
(24,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),

-- ── HOTEL 25 – CN Tower Hotel ─────────────────────
(25,'https://images.unsplash.com/photo-1507992781348-310259076fe0?w=800&q=80',1),
(25,'https://images.unsplash.com/photo-1517935706615-2717063c2225?w=800&q=80',2),
(25,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),

-- ── HOTEL 26 – Toronto Budget Inn ────────────────
(26,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(26,'https://images.unsplash.com/photo-1507992781348-310259076fe0?w=800&q=80',2),

-- ── HOTEL 27 – Mexico Palace Hotel ───────────────
(27,'https://images.unsplash.com/photo-1585464231875-d9ef1f5ad396?w=800&q=80',1),
(27,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',2),
(27,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),

-- ── HOTEL 28 – Aztec Grand Hotel ─────────────────
(28,'https://images.unsplash.com/photo-1568605114967-8130f3a36994?w=800&q=80',1),
(28,'https://images.unsplash.com/photo-1585464231875-d9ef1f5ad396?w=800&q=80',2),
(28,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',3),

-- ── HOTEL 29 – CDMX Budget Hotel ─────────────────
(29,'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80',1),
(29,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),

-- ── HOTEL 30 – Rio Luxury Resort ─────────────────
(30,'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=800&q=80',1),
(30,'https://images.unsplash.com/photo-1544984243-ec57ea16fe25?w=800&q=80',2),
(30,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(30,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),

-- ── HOTEL 31 – Copacabana Palace ─────────────────
(31,'https://images.unsplash.com/photo-1544984243-ec57ea16fe25?w=800&q=80',1),
(31,'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=800&q=80',2),
(31,'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',3),
(31,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',4),

-- ── HOTEL 32 – Rio Budget Stay ───────────────────
(32,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(32,'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?w=800&q=80',2),

-- ── HOTEL 33 – Buenos Aires Palace ───────────────
(33,'https://images.unsplash.com/photo-1589909202802-8f4aadce1849?w=800&q=80',1),
(33,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',2),
(33,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),

-- ── HOTEL 34 – Tango Grand Hotel ─────────────────
(34,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',1),
(34,'https://images.unsplash.com/photo-1589909202802-8f4aadce1849?w=800&q=80',2),
(34,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',3),

-- ── HOTEL 35 – Buenos Aires Budget Hotel ─────────
(35,'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80',1),
(35,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),

-- ── HOTEL 36 – Oslo Grand Hotel ──────────────────
(36,'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=800&q=80',1),
(36,'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=800&q=80',2),
(36,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),

-- ── HOTEL 37 – Fjord View Hotel ──────────────────
(37,'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?w=800&q=80',1),
(37,'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=800&q=80',2),
(37,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),
(37,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',4),

-- ── HOTEL 38 – Oslo Budget Hotel ─────────────────
(38,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(38,'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?w=800&q=80',2),

-- ── HOTEL 39 – Stockholm Palace ──────────────────
(39,'https://images.unsplash.com/photo-1509356843151-3e7d96241e11?w=800&q=80',1),
(39,'https://images.unsplash.com/photo-1548872591-a42d9f9f4f87?w=800&q=80',2),
(39,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),

-- ── HOTEL 40 – Nobel Hotel ────────────────────────
(40,'https://images.unsplash.com/photo-1548872591-a42d9f9f4f87?w=800&q=80',1),
(40,'https://images.unsplash.com/photo-1509356843151-3e7d96241e11?w=800&q=80',2),
(40,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),

-- ── HOTEL 41 – Stockholm Budget Hotel ────────────
(41,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(41,'https://images.unsplash.com/photo-1509356843151-3e7d96241e11?w=800&q=80',2),

-- ── HOTEL 42 – Tokyo Luxury Hotel ────────────────
(42,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&q=80',1),
(42,'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=800&q=80',2),
(42,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(42,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),

-- ── HOTEL 43 – Shibuya Grand Hotel ───────────────
(43,'https://images.unsplash.com/photo-1536098561742-ca998e48cbcc?w=800&q=80',1),
(43,'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?w=800&q=80',2),
(43,'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?w=800&q=80',3),
(43,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',4),

-- ── HOTEL 44 – Tokyo Budget Inn ──────────────────
(44,'https://images.unsplash.com/photo-1494522358652-f30e61a60313?w=800&q=80',1),
(44,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),

-- ── HOTEL 45 – Sydney Luxury Hotel ───────────────
(45,'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800&q=80',1),
(45,'https://images.unsplash.com/photo-1524397057410-1e775ed476f3?w=800&q=80',2),
(45,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(45,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),

-- ── HOTEL 46 – Opera House Hotel ─────────────────
(46,'https://images.unsplash.com/photo-1524397057410-1e775ed476f3?w=800&q=80',1),
(46,'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800&q=80',2),
(46,'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',3),
(46,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',4),

-- ── HOTEL 47 – Sydney Budget Hotel ───────────────
(47,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(47,'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?w=800&q=80',2),

-- ── HOTEL 48 – Dubai Luxury Palace ───────────────
(48,'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800&q=80',1),
(48,'https://images.unsplash.com/photo-1580674684081-7617fbf3d745?w=800&q=80',2),
(48,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(48,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),

-- ── HOTEL 49 – Burj Al Arab Hotel ────────────────
(49,'https://images.unsplash.com/photo-1580674684081-7617fbf3d745?w=800&q=80',1),
(49,'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800&q=80',2),
(49,'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800&q=80',3),
(49,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',4),

-- ── HOTEL 50 – Dubai City Hotel ──────────────────
(50,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',1),
(50,'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?w=800&q=80',2),
(50,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',3),

-- ── HOTEL 51 – Zurich Elite Hotel ────────────────
(51,'https://images.unsplash.com/photo-1515488764276-beab7607c1e6?w=800&q=80',1),
(51,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',2),
(51,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),

-- ── HOTEL 52 – Zurich Budget Hotel ───────────────
(52,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(52,'https://images.unsplash.com/photo-1515488764276-beab7607c1e6?w=800&q=80',2),

-- ── HOTEL 53 – Beijing Imperial Hotel ────────────
(53,'https://images.unsplash.com/photo-1584464491033-06628f3a6b7b?w=800&q=80',1),
(53,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',2),
(53,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),

-- ── HOTEL 54 – Beijing Budget Inn ────────────────
(54,'https://images.unsplash.com/photo-1567861911437-538298e4232c?w=800&q=80',1),
(54,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',2),

-- ── HOTEL 55 – Seoul Sky Hotel ───────────────────
(55,'https://images.unsplash.com/photo-1517154421773-0529f29ea451?w=800&q=80',1),
(55,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',2),
(55,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),

-- ── HOTEL 56 – Seoul Budget Hotel ────────────────
(56,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(56,'https://images.unsplash.com/photo-1517154421773-0529f29ea451?w=800&q=80',2),

-- ── HOTEL 57 – Istanbul Sultan Hotel ─────────────
(57,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=800&q=80',1),
(57,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',2),
(57,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',3),
(57,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',4),

-- ── HOTEL 58 – Istanbul Budget Hotel ─────────────
(58,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(58,'https://images.unsplash.com/photo-1524231757912-21f4fe3a7200?w=800&q=80',2),

-- ── HOTEL 59 – Cape Town Ocean Hotel ─────────────
(59,'https://images.unsplash.com/photo-1580060839134-75a5edca2e99?w=800&q=80',1),
(59,'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800&q=80',2),
(59,'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800&q=80',3),
(59,'https://images.unsplash.com/photo-1582719508461-905c673771fd?w=800&q=80',4),

-- ── HOTEL 60 – Cape Town Budget Hotel ────────────
(60,'https://images.unsplash.com/photo-1445019980597-93fa8acb246c?w=800&q=80',1),
(60,'https://images.unsplash.com/photo-1580060839134-75a5edca2e99?w=800&q=80',2);


-- ════════════════════════════════════════════════
--  VERIFICACIÓN (ejecutar después en pestaña SQL)
-- ════════════════════════════════════════════════
--
-- Ver portadas de todos los hoteles:
-- SELECT id_hotel, nombre, imagen FROM hoteles ORDER BY id_hotel;
--
-- Ver galería (número de fotos por hotel):
-- SELECT id_hotel, COUNT(*) AS num_fotos FROM hotel_imagenes GROUP BY id_hotel ORDER BY id_hotel;
--
-- ============================================================
-- Fin del script
-- ============================================================
