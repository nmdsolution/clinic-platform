-- ============================================================
-- CONFIGURATION DES EMPLACEMENTS - FONDATION FASSE
-- ============================================================
-- Hierarchie :
-- Hopital FASSE (parent)
--   Fondation Medicale Fasse (clinique)
--     Pharmacie principale (dispensation)
--     Magasin principal    (stockage)
--     Laboratoire          (analyses)
--     Salle de consultation

-- 1. Creer Hopital FASSE (top level)
INSERT INTO location (name, description, retired, creator, date_created, uuid)
VALUES ('Hopital FASSE', 'Structure hospitaliere Fondation Avenir Sante Solidarite Education', 0, 1, NOW(), UUID());

SET @hopital_id = LAST_INSERT_ID();

-- 2. Rattacher Fondation Medicale Fasse a Hopital FASSE
UPDATE location SET parent_location = @hopital_id WHERE location_id = 5;

-- 3. Rattacher Pharmacie principale et Magasin principal a Fondation Medicale Fasse
UPDATE location SET parent_location = 5 WHERE location_id IN (2, 3);

-- 4. Creer Laboratoire (enfant de Fondation Medicale Fasse)
INSERT INTO location (name, description, retired, creator, date_created, parent_location, uuid)
VALUES ('Laboratoire', 'Laboratoire d analyses medicales', 0, 1, NOW(), 5, UUID());

-- 5. Creer Salle de consultation (enfant de Fondation Medicale Fasse)
INSERT INTO location (name, description, retired, creator, date_created, parent_location, uuid)
VALUES ('Salle de consultation', 'Salle de consultation medicale', 0, 1, NOW(), 5, UUID());

-- 6. Retirer tous les emplacements inutiles
UPDATE location
SET retired = 1,
    retired_by = 1,
    date_retired = NOW(),
    retire_reason = 'Non utilise - clinique FASSE'
WHERE location_id IN (
    4,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,
    26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,
    46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61
);

-- Verification : afficher la hierarchie finale
SELECT
    l.location_id,
    l.name,
    IFNULL(p.name, '(racine)') AS parent
FROM location l
LEFT JOIN location p ON l.parent_location = p.location_id
WHERE l.retired = 0
ORDER BY p.name, l.location_id;
