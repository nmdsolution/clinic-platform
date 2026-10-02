-- ============================================================
-- DEMO CICO - OPHTALMOLOGIE
-- Concepts, types de rencontre et services facturables
-- Script idempotent : peut être relancé sans créer de doublons.
-- ============================================================
-- Usage :
-- scp demo-cico/01_ophtalmo_init.sql ubuntu@vps-7de2756e:/tmp/
-- docker exec -i clinic-platform-db-1 mysql -u openmrs -popenmrs openmrs < /tmp/01_ophtalmo_init.sql

DROP PROCEDURE IF EXISTS demo_mk_concept;
DROP PROCEDURE IF EXISTS demo_mk_numeric;
DROP PROCEDURE IF EXISTS demo_mk_answer;
DROP PROCEDURE IF EXISTS demo_mk_service;

DELIMITER //

CREATE PROCEDURE demo_mk_concept(IN p_uuid CHAR(38), IN p_name VARCHAR(255),
                                 IN p_datatype VARCHAR(50), IN p_class VARCHAR(50))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM concept WHERE uuid = p_uuid) THEN
    INSERT INTO concept (datatype_id, class_id, is_set, creator, date_created, retired, uuid)
    VALUES ((SELECT concept_datatype_id FROM concept_datatype WHERE name = p_datatype),
            (SELECT concept_class_id FROM concept_class WHERE name = p_class),
            0, 1, NOW(), 0, p_uuid);
    INSERT INTO concept_name (concept_id, name, locale, locale_preferred, creator,
                              date_created, concept_name_type, voided, uuid)
    VALUES (LAST_INSERT_ID(), p_name, 'fr', 1, 1, NOW(), 'FULLY_SPECIFIED', 0, UUID());
  END IF;
END //

CREATE PROCEDURE demo_mk_numeric(IN p_uuid CHAR(38), IN p_name VARCHAR(255), IN p_units VARCHAR(50),
                                 IN p_low DOUBLE, IN p_high DOUBLE, IN p_decimal TINYINT)
BEGIN
  CALL demo_mk_concept(p_uuid, p_name, 'Numeric', 'Question');
  INSERT IGNORE INTO concept_numeric (concept_id, low_absolute, hi_absolute, units, allow_decimal)
  SELECT concept_id, p_low, p_high, p_units, p_decimal FROM concept WHERE uuid = p_uuid;
END //

CREATE PROCEDURE demo_mk_answer(IN p_question CHAR(38), IN p_answer CHAR(38), IN p_weight DOUBLE)
BEGIN
  IF NOT EXISTS (SELECT 1 FROM concept_answer ca
                 JOIN concept q ON q.concept_id = ca.concept_id
                 JOIN concept a ON a.concept_id = ca.answer_concept
                 WHERE q.uuid = p_question AND a.uuid = p_answer) THEN
    INSERT INTO concept_answer (concept_id, answer_concept, sort_weight, creator, date_created, uuid)
    SELECT q.concept_id, a.concept_id, p_weight, 1, NOW(), UUID()
    FROM concept q, concept a WHERE q.uuid = p_question AND a.uuid = p_answer;
  END IF;
END //

CREATE PROCEDURE demo_mk_service(IN p_name VARCHAR(255), IN p_short VARCHAR(255), IN p_price DECIMAL(20,2))
BEGIN
  IF NOT EXISTS (SELECT 1 FROM cashier_billable_service WHERE name = p_name AND retired = 0) THEN
    INSERT INTO cashier_billable_service (name, short_name, service_status, creator, date_created, retired, uuid)
    VALUES (p_name, p_short, 'ENABLED', 1, NOW(), 0, UUID());
    INSERT INTO cashier_item_price (service_id, price, name, creator, date_created, retired, uuid)
    VALUES (LAST_INSERT_ID(), p_price, 'Standard', 1, NOW(), 0, UUID());
  END IF;
END //

DELIMITER ;

-- ============================================================
-- 1. CONSULTATION OPHTALMOLOGIQUE
-- ============================================================
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000013', 'Motif de consultation ophtalmologique', 'Text', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000001', 'Acuité visuelle sans correction OD', 'Text', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000002', 'Acuité visuelle sans correction OG', 'Text', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000003', 'Acuité visuelle avec correction OD', 'Text', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000004', 'Acuité visuelle avec correction OG', 'Text', 'Question');
CALL demo_mk_numeric('0f7a0000-c1c0-4000-8000-000000000005', 'Tension oculaire OD', 'mmHg', 0, 80, 1);
CALL demo_mk_numeric('0f7a0000-c1c0-4000-8000-000000000006', 'Tension oculaire OG', 'mmHg', 0, 80, 1);
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000007', 'Segment antérieur OD', 'Text', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000008', 'Segment antérieur OG', 'Text', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000009', 'Fond d''oeil OD', 'Text', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000010', 'Fond d''oeil OG', 'Text', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000011', 'Diagnostic ophtalmologique', 'Text', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000012', 'Conduite à tenir ophtalmologique', 'Text', 'Question');

-- ============================================================
-- 2. CHIRURGIE OPHTALMOLOGIQUE (cataracte)
-- ============================================================
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000020', 'Date de l''intervention', 'Date', 'Question');

CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000021', 'Oeil opéré', 'Coded', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000022', 'Oeil droit (OD)', 'N/A', 'Misc');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000023', 'Oeil gauche (OG)', 'N/A', 'Misc');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000024', 'Les deux yeux (ODG)', 'N/A', 'Misc');
CALL demo_mk_answer('0f7a0000-c1c0-4000-8000-000000000021', '0f7a0000-c1c0-4000-8000-000000000022', 1);
CALL demo_mk_answer('0f7a0000-c1c0-4000-8000-000000000021', '0f7a0000-c1c0-4000-8000-000000000023', 2);
CALL demo_mk_answer('0f7a0000-c1c0-4000-8000-000000000021', '0f7a0000-c1c0-4000-8000-000000000024', 3);

CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000025', 'Type d''intervention ophtalmologique', 'Coded', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000026', 'Chirurgie de la cataracte', 'N/A', 'Procedure');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000027', 'Chirurgie du glaucome (trabéculectomie)', 'N/A', 'Procedure');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000028', 'Exérèse de ptérygion', 'N/A', 'Procedure');
CALL demo_mk_answer('0f7a0000-c1c0-4000-8000-000000000025', '0f7a0000-c1c0-4000-8000-000000000026', 1);
CALL demo_mk_answer('0f7a0000-c1c0-4000-8000-000000000025', '0f7a0000-c1c0-4000-8000-000000000027', 2);
CALL demo_mk_answer('0f7a0000-c1c0-4000-8000-000000000025', '0f7a0000-c1c0-4000-8000-000000000028', 3);

CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000029', 'Technique opératoire', 'Coded', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000030', 'Phacoémulsification', 'N/A', 'Procedure');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000031', 'MSICS (petite incision manuelle)', 'N/A', 'Procedure');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000032', 'Extraction extracapsulaire (EEC)', 'N/A', 'Procedure');
CALL demo_mk_answer('0f7a0000-c1c0-4000-8000-000000000029', '0f7a0000-c1c0-4000-8000-000000000030', 1);
CALL demo_mk_answer('0f7a0000-c1c0-4000-8000-000000000029', '0f7a0000-c1c0-4000-8000-000000000031', 2);
CALL demo_mk_answer('0f7a0000-c1c0-4000-8000-000000000029', '0f7a0000-c1c0-4000-8000-000000000032', 3);

CALL demo_mk_numeric('0f7a0000-c1c0-4000-8000-000000000033', 'Puissance de l''implant', 'D', -10, 40, 1);

CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000034', 'Type d''anesthésie', 'Coded', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000035', 'Anesthésie topique', 'N/A', 'Misc');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000036', 'Anesthésie péribulbaire', 'N/A', 'Misc');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000037', 'Anesthésie générale', 'N/A', 'Misc');
CALL demo_mk_answer('0f7a0000-c1c0-4000-8000-000000000034', '0f7a0000-c1c0-4000-8000-000000000035', 1);
CALL demo_mk_answer('0f7a0000-c1c0-4000-8000-000000000034', '0f7a0000-c1c0-4000-8000-000000000036', 2);
CALL demo_mk_answer('0f7a0000-c1c0-4000-8000-000000000034', '0f7a0000-c1c0-4000-8000-000000000037', 3);

CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000038', 'Chirurgien', 'Text', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000039', 'Complications per-opératoires', 'Text', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000040', 'Suivi post-opératoire J1', 'Text', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000041', 'Suivi post-opératoire J7', 'Text', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000042', 'Suivi post-opératoire J30', 'Text', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000043', 'Date du prochain rendez-vous', 'Date', 'Question');

-- ============================================================
-- 3. ORDONNANCE DE LUNETTES
-- ============================================================
CALL demo_mk_numeric('0f7a0000-c1c0-4000-8000-000000000050', 'Lunettes OD sphère', 'D', -25, 25, 1);
CALL demo_mk_numeric('0f7a0000-c1c0-4000-8000-000000000051', 'Lunettes OD cylindre', 'D', -10, 10, 1);
CALL demo_mk_numeric('0f7a0000-c1c0-4000-8000-000000000052', 'Lunettes OD axe', '°', 0, 180, 0);
CALL demo_mk_numeric('0f7a0000-c1c0-4000-8000-000000000053', 'Lunettes OD addition', 'D', 0, 4, 1);
CALL demo_mk_numeric('0f7a0000-c1c0-4000-8000-000000000054', 'Lunettes OG sphère', 'D', -25, 25, 1);
CALL demo_mk_numeric('0f7a0000-c1c0-4000-8000-000000000055', 'Lunettes OG cylindre', 'D', -10, 10, 1);
CALL demo_mk_numeric('0f7a0000-c1c0-4000-8000-000000000056', 'Lunettes OG axe', '°', 0, 180, 0);
CALL demo_mk_numeric('0f7a0000-c1c0-4000-8000-000000000057', 'Lunettes OG addition', 'D', 0, 4, 1);
CALL demo_mk_numeric('0f7a0000-c1c0-4000-8000-000000000058', 'Écart pupillaire', 'mm', 40, 80, 1);

CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000059', 'Type de verres', 'Coded', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000060', 'Verres unifocaux', 'N/A', 'Misc');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000061', 'Verres progressifs', 'N/A', 'Misc');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000062', 'Verres bifocaux', 'N/A', 'Misc');
CALL demo_mk_answer('0f7a0000-c1c0-4000-8000-000000000059', '0f7a0000-c1c0-4000-8000-000000000060', 1);
CALL demo_mk_answer('0f7a0000-c1c0-4000-8000-000000000059', '0f7a0000-c1c0-4000-8000-000000000061', 2);
CALL demo_mk_answer('0f7a0000-c1c0-4000-8000-000000000059', '0f7a0000-c1c0-4000-8000-000000000062', 3);

CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000063', 'Traitement des verres', 'Text', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000064', 'Usage des lunettes', 'Text', 'Question');
CALL demo_mk_concept('0f7a0000-c1c0-4000-8000-000000000065', 'Remarques ordonnance lunettes', 'Text', 'Question');

-- ============================================================
-- 4. TYPES DE RENCONTRE
-- ============================================================
INSERT INTO encounter_type (name, description, creator, date_created, retired, uuid)
SELECT 'Consultation ophtalmologique', 'Examen ophtalmologique : acuité, tension, fond d''oeil', 1, NOW(), 0,
       '0f7a0000-c1c0-4000-8000-0000000000e1'
WHERE NOT EXISTS (SELECT 1 FROM encounter_type WHERE uuid = '0f7a0000-c1c0-4000-8000-0000000000e1');

INSERT INTO encounter_type (name, description, creator, date_created, retired, uuid)
SELECT 'Chirurgie ophtalmologique', 'Compte-rendu opératoire et suivi post-opératoire', 1, NOW(), 0,
       '0f7a0000-c1c0-4000-8000-0000000000e2'
WHERE NOT EXISTS (SELECT 1 FROM encounter_type WHERE uuid = '0f7a0000-c1c0-4000-8000-0000000000e2');

INSERT INTO encounter_type (name, description, creator, date_created, retired, uuid)
SELECT 'Ordonnance de lunettes', 'Prescription de correction optique', 1, NOW(), 0,
       '0f7a0000-c1c0-4000-8000-0000000000e3'
WHERE NOT EXISTS (SELECT 1 FROM encounter_type WHERE uuid = '0f7a0000-c1c0-4000-8000-0000000000e3');

-- ============================================================
-- 5. SERVICES FACTURABLES (prix de démonstration, XAF)
-- ============================================================
CALL demo_mk_service('Consultation ophtalmologique', 'Consult. ophtalmo', 10000.00);
CALL demo_mk_service('Examen du fond d''oeil', 'Fond d''oeil', 5000.00);
CALL demo_mk_service('Chirurgie de la cataracte (un oeil)', 'Cataracte', 200000.00);
CALL demo_mk_service('Monture + verres unifocaux', 'Lunettes unifocales', 35000.00);
CALL demo_mk_service('Monture + verres progressifs', 'Lunettes progressives', 85000.00);

-- ============================================================
-- NETTOYAGE + VERIFICATION
-- ============================================================
DROP PROCEDURE IF EXISTS demo_mk_concept;
DROP PROCEDURE IF EXISTS demo_mk_numeric;
DROP PROCEDURE IF EXISTS demo_mk_answer;
DROP PROCEDURE IF EXISTS demo_mk_service;

SELECT COUNT(*) AS concepts_demo FROM concept WHERE uuid LIKE '0f7a0000-c1c0-4000-8000-%';
SELECT name AS types_rencontre FROM encounter_type WHERE uuid LIKE '0f7a0000-c1c0-4000-8000-%';
SELECT s.name AS service, p.price AS prix
FROM cashier_billable_service s JOIN cashier_item_price p ON p.service_id = s.service_id
WHERE s.name IN ('Consultation ophtalmologique', 'Examen du fond d''oeil', 'Chirurgie de la cataracte (un oeil)',
                 'Monture + verres unifocaux', 'Monture + verres progressifs');
