-- ============================================================
-- Médicaments : vraies formes/unités, stock aligné, prix de vente
-- Idempotent. Appliqué en production le 26/11/2026 après sauvegarde
-- (~/backups/avant_unites_prix_20261126_2027.sql.gz).
--
-- 1. La forme d'un médicament sert d'unité de dose et de quantité par défaut
--    dans le panier de commandes : elle doit appartenir au jeu des unités de
--    dosage (162384), sinon « DrugOrder.error.notAmongAllowedConcepts ».
-- 2. L'unité de conditionnement du stock (« Piece ») est remplacée par la forme.
-- 3. billing 2.3 prend le prix d'un médicament dans cashier_item_price.item_id
--    (article de stock) ; sinon il facture le prix d'achat (vide = 0 FCFA).
-- ============================================================
START TRANSACTION;

SET @dosage_set = (SELECT concept_id FROM concept WHERE uuid = '162384AAAAAAAAAAAAAAAAAAAAAAAAAAAAAA');

-- ---------- 1a. Unités manquantes dans le jeu de dosage ----------
-- Flacon (853, « Bottle »), Poche (869, « Bag »), Sachet (926, « Packets »)
UPDATE concept_name SET name = 'Flacon'
 WHERE concept_id = 853 AND locale = 'fr' AND voided = 0 AND name = 'Bouteille';
INSERT INTO concept_name (concept_id, name, locale, locale_preferred, creator, date_created, concept_name_type, voided, uuid)
SELECT 869, 'Poche', 'fr', 1, 1, NOW(), 'FULLY_SPECIFIED', 0, '0f7a0000-c1c0-4000-8000-0000000000d2'
 WHERE NOT EXISTS (SELECT 1 FROM concept_name WHERE concept_id = 869 AND locale = 'fr' AND voided = 0);
UPDATE concept_name SET name = 'Sachet'
 WHERE concept_id = 926 AND locale = 'fr' AND voided = 0 AND name = 'Sachets';

-- Ovule (nouveau concept, classe « Units of Measure »)
INSERT INTO concept (retired, datatype_id, class_id, is_set, creator, date_created, uuid)
SELECT 0, 4, 18, 0, 1, NOW(), '0f7a0000-c1c0-4000-8000-0000000000d1'
 WHERE NOT EXISTS (SELECT 1 FROM concept WHERE uuid = '0f7a0000-c1c0-4000-8000-0000000000d1');
SET @ovule = (SELECT concept_id FROM concept WHERE uuid = '0f7a0000-c1c0-4000-8000-0000000000d1');
INSERT INTO concept_name (concept_id, name, locale, locale_preferred, creator, date_created, concept_name_type, voided, uuid)
SELECT @ovule, 'Ovule', 'fr', 1, 1, NOW(), 'FULLY_SPECIFIED', 0, '0f7a0000-c1c0-4000-8000-0000000000d3'
 WHERE NOT EXISTS (SELECT 1 FROM concept_name WHERE uuid = '0f7a0000-c1c0-4000-8000-0000000000d3');
INSERT INTO concept_name (concept_id, name, locale, locale_preferred, creator, date_created, concept_name_type, voided, uuid)
SELECT @ovule, 'Vaginal tablet', 'en', 1, 1, NOW(), 'FULLY_SPECIFIED', 0, '0f7a0000-c1c0-4000-8000-0000000000d4'
 WHERE NOT EXISTS (SELECT 1 FROM concept_name WHERE uuid = '0f7a0000-c1c0-4000-8000-0000000000d4');

INSERT INTO concept_set (concept_id, concept_set, sort_weight, creator, date_created, uuid)
SELECT u.cid, @dosage_set, u.w, 1, NOW(), UUID()
  FROM (SELECT 853 cid, 41 w UNION ALL SELECT 869, 42 UNION ALL SELECT 926, 43 UNION ALL SELECT @ovule, 44) u
 WHERE NOT EXISTS (SELECT 1 FROM concept_set cs WHERE cs.concept_set = @dosage_set AND cs.concept_id = u.cid);

-- ---------- 1b. Articles de stock reliés au mauvais médicament ----------
-- Omeprazole inj (stock 59) était relié à « Omeprazole Co 20mg » (comprimé)
INSERT INTO drug (concept_id, name, combination, dosage_form, creator, date_created, retired, uuid)
SELECT d.concept_id, 'Oméprazole 40mg injectable', 0, 882, 1, NOW(), 0, '0f7a0000-c1c0-4000-8000-0000000000e1'
  FROM drug d WHERE d.drug_id = 247
   AND NOT EXISTS (SELECT 1 FROM drug WHERE uuid = '0f7a0000-c1c0-4000-8000-0000000000e1');
-- Erythromycine cp (stock 49) était relié à « Erythromycin 125mg/5ml » (sirop)
INSERT INTO drug (concept_id, name, combination, dosage_form, creator, date_created, retired, uuid)
SELECT d.concept_id, 'Érythromycine comprimé', 0, 927, 1, NOW(), 0, '0f7a0000-c1c0-4000-8000-0000000000e2'
  FROM drug d WHERE d.drug_id = 135
   AND NOT EXISTS (SELECT 1 FROM drug WHERE uuid = '0f7a0000-c1c0-4000-8000-0000000000e2');
-- Nystatine ovule (stock 35) était relié à « Nystatin 100000U/g » (pommade)
INSERT INTO drug (concept_id, name, combination, dosage_form, creator, date_created, retired, uuid)
SELECT d.concept_id, 'Nystatine 100 000 UI ovule', 0, @ovule, 1, NOW(), 0, '0f7a0000-c1c0-4000-8000-0000000000e3'
  FROM drug d WHERE d.drug_id = 244
   AND NOT EXISTS (SELECT 1 FROM drug WHERE uuid = '0f7a0000-c1c0-4000-8000-0000000000e3');

UPDATE stockmgmt_stock_item si JOIN drug d ON d.uuid = '0f7a0000-c1c0-4000-8000-0000000000e1'
   SET si.drug_id = d.drug_id, si.concept_id = d.concept_id WHERE si.stock_item_id = 59;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.uuid = '0f7a0000-c1c0-4000-8000-0000000000e2'
   SET si.drug_id = d.drug_id, si.concept_id = d.concept_id WHERE si.stock_item_id = 49;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.uuid = '0f7a0000-c1c0-4000-8000-0000000000e3'
   SET si.drug_id = d.drug_id, si.concept_id = d.concept_id WHERE si.stock_item_id = 35;

-- ---------- 1c. Formes des médicaments ----------
-- Comprimé (927)
UPDATE drug SET dosage_form = 927, changed_by = 1, date_changed = NOW()
 WHERE drug_id IN (340, 336, 343, 353, 356, 324, 328, 330, 333, 327, 329, 331, 325) AND IFNULL(dosage_form, 0) <> 927;
-- Ampoule (912)
UPDATE drug SET dosage_form = 912, changed_by = 1, date_changed = NOW()
 WHERE drug_id IN (352, 335, 109, 151, 357, 348, 276, 300, 351, 355, 334) AND IFNULL(dosage_form, 0) <> 912;
-- Fiole, poudre à reconstituer (882)
UPDATE drug SET dosage_form = 882, changed_by = 1, date_changed = NOW()
 WHERE drug_id IN (78, 354, 341, 339, 338, 347) AND IFNULL(dosage_form, 0) <> 882;
-- La voie de Ceftriaxone était saisie comme forme : on la garde comme voie
UPDATE drug SET route = 922 WHERE drug_id = 78 AND route IS NULL;
-- Flacon (853) : sirops, Bétadine, collyre
UPDATE drug SET dosage_form = 853, changed_by = 1, date_changed = NOW()
 WHERE drug_id IN (342, 337, 344, 223, 246, 345, 346, 135, 326, 349, 154) AND IFNULL(dosage_form, 0) <> 853;
-- Poche (869) : solutés de perfusion
UPDATE drug SET dosage_form = 869, changed_by = 1, date_changed = NOW()
 WHERE drug_id IN (280, 350, 358, 359) AND IFNULL(dosage_form, 0) <> 869;
-- Sachet (926) : SRO
UPDATE drug SET dosage_form = 926, changed_by = 1, date_changed = NOW()
 WHERE drug_id = 332 AND IFNULL(dosage_form, 0) <> 926;
-- Tube (884) : Nystatin 100000U/g (pommade), n'est plus relié au stock
UPDATE drug SET dosage_form = 884, changed_by = 1, date_changed = NOW()
 WHERE drug_id = 244 AND dosage_form IS NULL;

-- ---------- 2. Unités du stock alignées sur la forme ----------
-- Unité de conditionnement « Piece » (3649, facteur 1) -> forme du médicament.
-- Les quantités ne changent pas (facteur 1).
UPDATE stockmgmt_stock_item_packaging_uom p
  JOIN stockmgmt_stock_item si ON si.stock_item_id = p.stock_item_id AND si.voided = 0
  JOIN drug d ON d.drug_id = si.drug_id
   SET p.packaging_uom_id = d.dosage_form, p.changed_by = 1, p.date_changed = NOW()
 WHERE p.voided = 0 AND p.packaging_uom_id = 3649 AND p.factor = 1
   AND d.dosage_form IS NOT NULL AND si.stock_item_id BETWEEN 13 AND 59;

UPDATE stockmgmt_stock_item si
  JOIN drug d ON d.drug_id = si.drug_id
  JOIN stockmgmt_stock_item_packaging_uom p ON p.stock_item_id = si.stock_item_id AND p.voided = 0
                                           AND p.packaging_uom_id = d.dosage_form AND p.factor = 1
   SET si.dispensing_unit_id = d.dosage_form,
       si.dispensing_unit_packaging_uom_id = p.stock_item_packaging_uom_id,
       si.default_stock_operations_uom_id = IFNULL(si.default_stock_operations_uom_id, p.stock_item_packaging_uom_id),
       si.changed_by = 1, si.date_changed = NOW()
 WHERE si.voided = 0 AND si.stock_item_id BETWEEN 13 AND 59;

-- ---------- 3. Prix de vente des articles de stock ----------
-- Repris du service facturable de même nom (grille tarifaire FASSE).
INSERT INTO cashier_item_price (item_id, service_id, price, payment_mode, name, creator, date_created, retired, uuid)
SELECT si.stock_item_id, NULL, p.price, NULL, 'Prix de vente', 1, NOW(), 0, UUID()
  FROM stockmgmt_stock_item si
  JOIN cashier_billable_service s ON s.name = si.common_name AND IFNULL(s.retired, 0) = 0
  JOIN cashier_item_price p ON p.service_id = s.service_id AND IFNULL(p.retired, 0) = 0
 WHERE si.voided = 0 AND si.stock_item_id BETWEEN 13 AND 59
   AND NOT EXISTS (SELECT 1 FROM cashier_item_price x WHERE x.item_id = si.stock_item_id AND IFNULL(x.retired, 0) = 0);

COMMIT;

-- ---------- Vérification ----------
SELECT si.stock_item_id, si.common_name, d.name medicament,
       (SELECT name FROM concept_name WHERE concept_id = d.dosage_form AND locale = 'fr' AND voided = 0 ORDER BY locale_preferred DESC LIMIT 1) forme,
       EXISTS (SELECT 1 FROM concept_set cs WHERE cs.concept_set = @dosage_set AND cs.concept_id = d.dosage_form) forme_autorisee,
       (SELECT name FROM concept_name WHERE concept_id = p.packaging_uom_id AND voided = 0 ORDER BY locale = 'fr' DESC, locale_preferred DESC LIMIT 1) unite_stock,
       (SELECT price FROM cashier_item_price x WHERE x.item_id = si.stock_item_id AND IFNULL(x.retired, 0) = 0 LIMIT 1) prix
  FROM stockmgmt_stock_item si
  LEFT JOIN drug d ON d.drug_id = si.drug_id
  LEFT JOIN stockmgmt_stock_item_packaging_uom p ON p.stock_item_id = si.stock_item_id AND p.voided = 0
 WHERE si.voided = 0 AND si.stock_item_id BETWEEN 13 AND 59
 ORDER BY si.stock_item_id;
