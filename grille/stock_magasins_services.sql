-- ============================================================
-- SERVICES ET MAGASINS DE STOCK - FONDATION MEDICALE FASSE
-- Note de la Dr Taffo du 06/10/2026, partie 5 :
--   1. chaque service = une Location enfant du centre
--   2. un magasin (stock room) par lieu de stockage
-- Script idempotent : peut être relancé sans créer de doublons.
-- ============================================================
-- Etat de départ (vérifié le 12/10/2026) :
--   5  Fondation Médicale Fasse (centre)
--   2  Pharmacie principale   [Main Pharmacy]  -> magasin « Pharmacie », déjà en place
--   3  Magasin principal      [Main Store]
--   63 Laboratoire, 64 Salle de consultation
--
-- Usage :
-- docker exec -i clinic-platform-db-1 mysql -u openmrs -popenmrs openmrs < /opt/clinic-platform/grille/stock_magasins_services.sql

DROP PROCEDURE IF EXISTS fasse_mk_location;
DROP PROCEDURE IF EXISTS fasse_mk_store;

DELIMITER //

-- Crée une Location enfant si elle n'existe pas déjà sous ce parent.
CREATE PROCEDURE fasse_mk_location(IN p_name VARCHAR(255), IN p_desc VARCHAR(255), IN p_parent_id INT)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM location WHERE name = p_name AND parent_location = p_parent_id AND retired = 0) THEN
    INSERT INTO location (name, description, parent_location, creator, date_created, retired, uuid)
    VALUES (p_name, p_desc, p_parent_id, 1, NOW(), 0, UUID());
  END IF;
END //

-- Crée un magasin sous un service : Location + tag « Main Store » + tiers (party) du module de stock.
CREATE PROCEDURE fasse_mk_store(IN p_name VARCHAR(255), IN p_desc VARCHAR(255), IN p_parent_name VARCHAR(255))
BEGIN
  DECLARE v_parent INT;
  DECLARE v_loc INT;
  DECLARE v_tag INT;

  SELECT location_id INTO v_parent FROM location
  WHERE name = p_parent_name AND parent_location = 5 AND retired = 0 LIMIT 1;

  IF v_parent IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Service parent introuvable pour le magasin';
  END IF;

  CALL fasse_mk_location(p_name, p_desc, v_parent);

  SELECT location_id INTO v_loc FROM location
  WHERE name = p_name AND parent_location = v_parent AND retired = 0 LIMIT 1;
  SELECT location_tag_id INTO v_tag FROM location_tag WHERE name = 'Main Store' AND retired = 0 LIMIT 1;

  INSERT INTO location_tag_map (location_id, location_tag_id)
  SELECT v_loc, v_tag FROM DUAL
  WHERE NOT EXISTS (SELECT 1 FROM location_tag_map WHERE location_id = v_loc AND location_tag_id = v_tag);

  INSERT INTO stockmgmt_party (location_id, creator, date_created, voided, uuid)
  SELECT v_loc, 1, NOW(), 0, UUID() FROM DUAL
  WHERE NOT EXISTS (SELECT 1 FROM stockmgmt_party WHERE location_id = v_loc AND voided = 0);
END //

DELIMITER ;

-- ============================================================
-- 1. SERVICES (Locations enfants du centre, id 5)
--    Laboratoire (63) et Pharmacie principale (2) existent déjà.
--    « Salle de consultation » (64) tient lieu de Médecine générale.
-- ============================================================
CALL fasse_mk_location('Accueil et Administration', 'Accueil, caisse et administration', 5);
CALL fasse_mk_location('Ophtalmologie', 'Consultations et soins ophtalmologiques', 5);
CALL fasse_mk_location('Médecine dentaire', 'Cabinet dentaire', 5);
CALL fasse_mk_location('Kinésithérapie', 'Salle de kinésithérapie', 5);
CALL fasse_mk_location('Soins infirmiers', 'Salle de soins et d''observation', 5);

-- ============================================================
-- 2. MAGASINS (un par lieu de stockage)
--    Le magasin « Pharmacie » est la Pharmacie principale (id 2), déjà en place.
-- ============================================================
CALL fasse_mk_store('Magasin Laboratoire', 'Réactifs, tests rapides, bandelettes, tubes, lancettes', 'Laboratoire');
CALL fasse_mk_store('Magasin Optique', 'Montures, verres, lunettes de lecture et de soleil', 'Ophtalmologie');
CALL fasse_mk_store('Magasin Dentaire', 'Consommables dentaires : composites, anesthésiques, gants', 'Médecine dentaire');
CALL fasse_mk_store('Magasin Soins infirmiers', 'Pansements, seringues, perfusions, gants, usage unique', 'Soins infirmiers');

DROP PROCEDURE IF EXISTS fasse_mk_location;
DROP PROCEDURE IF EXISTS fasse_mk_store;

-- ============================================================
-- VERIFICATION
-- ============================================================
SELECT l.location_id, l.name, IFNULL(p.name, '(racine)') AS parent,
       IFNULL(GROUP_CONCAT(DISTINCT t.name SEPARATOR ', '), '') AS tags,
       IF(MAX(sp.party_id) IS NULL, 'non', 'oui') AS tiers_stock
FROM location l
LEFT JOIN location p ON p.location_id = l.parent_location
LEFT JOIN location_tag_map m ON m.location_id = l.location_id
LEFT JOIN location_tag t ON t.location_tag_id = m.location_tag_id
LEFT JOIN stockmgmt_party sp ON sp.location_id = l.location_id AND sp.voided = 0
WHERE l.retired = 0
GROUP BY l.location_id
ORDER BY IFNULL(p.location_id, 0), l.location_id;
