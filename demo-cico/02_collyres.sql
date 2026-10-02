-- ============================================================
-- DEMO CICO - Médicaments ophtalmologiques (dictionnaire de prescription)
-- Script idempotent : peut être relancé sans créer de doublons.
-- ============================================================
-- Usage :
-- docker exec -i clinic-platform-db-1 mysql -u openmrs -popenmrs openmrs < /opt/clinic-platform/demo-cico/02_collyres.sql

DROP PROCEDURE IF EXISTS demo_mk_drug;

DELIMITER //

CREATE PROCEDURE demo_mk_drug(IN p_concept_uuid CHAR(38), IN p_concept_name VARCHAR(255), IN p_drug_name VARCHAR(255))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM concept WHERE uuid = p_concept_uuid) THEN
    INSERT INTO concept (datatype_id, class_id, is_set, creator, date_created, retired, uuid)
    VALUES (4, 3, 0, 1, NOW(), 0, p_concept_uuid);
    INSERT INTO concept_name (concept_id, name, locale, locale_preferred, creator,
                              date_created, concept_name_type, voided, uuid)
    VALUES (LAST_INSERT_ID(), p_concept_name, 'fr', 1, 1, NOW(), 'FULLY_SPECIFIED', 0, UUID());
  END IF;
  IF NOT EXISTS (SELECT 1 FROM drug WHERE name = p_drug_name AND retired = 0) THEN
    INSERT INTO drug (concept_id, name, creator, date_created, retired, uuid)
    SELECT concept_id, p_drug_name, 1, NOW(), 0, UUID() FROM concept WHERE uuid = p_concept_uuid;
  END IF;
END //

DELIMITER ;

CALL demo_mk_drug('0f7a0000-c1c0-4000-8000-000000000101', 'Tobramycine + dexaméthasone',  'Collyre tobramycine + dexaméthasone 0,3%/0,1%');
CALL demo_mk_drug('0f7a0000-c1c0-4000-8000-000000000102', 'Ciprofloxacine collyre',       'Collyre ciprofloxacine 0,3%');
CALL demo_mk_drug('0f7a0000-c1c0-4000-8000-000000000103', 'Timolol collyre',              'Collyre timolol 0,5%');
CALL demo_mk_drug('0f7a0000-c1c0-4000-8000-000000000104', 'Acide hyaluronique collyre',   'Larmes artificielles (acide hyaluronique 0,2%)');
CALL demo_mk_drug('0f7a0000-c1c0-4000-8000-000000000105', 'Atropine collyre',             'Collyre atropine 1%');
CALL demo_mk_drug('0f7a0000-c1c0-4000-8000-000000000106', 'Dorzolamide collyre',          'Collyre dorzolamide 2%');
CALL demo_mk_drug('0f7a0000-c1c0-4000-8000-000000000107', 'Diclofénac collyre',           'Collyre diclofénac 0,1%');

DROP PROCEDURE IF EXISTS demo_mk_drug;

SELECT name AS medicaments_ophtalmo FROM drug WHERE name LIKE 'Collyre%' OR name LIKE 'Larmes%' ORDER BY name;
