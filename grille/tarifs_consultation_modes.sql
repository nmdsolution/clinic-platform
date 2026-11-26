-- ============================================================
-- Tarifs sélectionnables à l'ouverture de visite (idempotent)
--
-- Le formulaire de visite (esm-billing-app) n'affiche que les services dont un
-- prix est lié au mode de paiement choisi. Les prix « Standard » n'en avaient
-- aucun : seul « OPD consultation (Cash: 2000) » apparaissait.
-- Pour chaque acte de consultation, on rattache le prix Standard à Espèces et
-- on ajoute le même montant pour Orange Money et MTN Mobile Money.
-- ============================================================
START TRANSACTION;

-- Actes de consultation : services 5 à 19 (consultations, CPN, planning, urgences,
-- téléconsultation, visite à domicile, consultation sociale, carnet) et 112 (ophtalmologie).
DROP TEMPORARY TABLE IF EXISTS tmp_actes;
CREATE TEMPORARY TABLE tmp_actes AS
SELECT s.service_id FROM cashier_billable_service s
 WHERE (s.service_id BETWEEN 5 AND 19 OR s.service_id = 112) AND IFNULL(s.retired, 0) = 0;

-- 1. Prix Standard -> Espèces (mode 1)
UPDATE cashier_item_price p JOIN tmp_actes a ON a.service_id = p.service_id
   SET p.payment_mode = 1, p.name = 'Espèces', p.changed_by = 1, p.date_changed = NOW()
 WHERE IFNULL(p.retired, 0) = 0 AND p.payment_mode IS NULL AND p.name = 'Standard';

-- 2. Même montant pour Orange Money (4) et MTN Mobile Money (5)
INSERT INTO cashier_item_price (item_id, service_id, price, payment_mode, name, creator, date_created, retired, uuid)
SELECT NULL, p.service_id, p.price, m.mode, m.nom, 1, NOW(), 0, UUID()
  FROM cashier_item_price p
  JOIN tmp_actes a ON a.service_id = p.service_id
  JOIN (SELECT 4 mode, 'Orange Money' nom UNION ALL SELECT 5, 'MTN Mobile Money') m
 WHERE IFNULL(p.retired, 0) = 0 AND p.payment_mode = 1
   AND NOT EXISTS (SELECT 1 FROM cashier_item_price x
                    WHERE x.service_id = p.service_id AND x.payment_mode = m.mode AND IFNULL(x.retired, 0) = 0);

-- 3. OPD consultation (service 4) : « Cash » -> « Espèces », PayPal retiré, mêmes modes mobiles
UPDATE cashier_item_price SET name = 'Espèces', changed_by = 1, date_changed = NOW()
 WHERE service_id = 4 AND name = 'Cash' AND IFNULL(retired, 0) = 0;
UPDATE cashier_item_price SET retired = 1, retired_by = 1, date_retired = NOW(), retire_reason = 'PayPal non utilisé à FASSE'
 WHERE service_id = 4 AND payment_mode = 3 AND IFNULL(retired, 0) = 0;
INSERT INTO cashier_item_price (item_id, service_id, price, payment_mode, name, creator, date_created, retired, uuid)
SELECT NULL, 4, p.price, m.mode, m.nom, 1, NOW(), 0, UUID()
  FROM cashier_item_price p
  JOIN (SELECT 4 mode, 'Orange Money' nom UNION ALL SELECT 5, 'MTN Mobile Money') m
 WHERE p.service_id = 4 AND p.payment_mode = 1 AND IFNULL(p.retired, 0) = 0
   AND NOT EXISTS (SELECT 1 FROM cashier_item_price x
                    WHERE x.service_id = 4 AND x.payment_mode = m.mode AND IFNULL(x.retired, 0) = 0);

-- 4. Libellés restés en anglais qui viennent des données (pas du code) :
--    attributs de visite (« Punctuality », « Insurance Policy Number »…) et types de commande
--    (« test order »). Renommés par UUID ; les modules les retrouvent par UUID, pas par nom.
UPDATE visit_attribute_type SET name = 'Ponctualité', changed_by = 1, date_changed = NOW()
 WHERE uuid = '57ea0cbb-064f-4d09-8cf4-e8228700491c' AND name = 'Punctuality';
UPDATE visit_attribute_type SET name = 'N° de police d''assurance', changed_by = 1, date_changed = NOW()
 WHERE uuid = 'aac48226-d143-4274-80e0-264db4e368ee' AND name = 'Insurance Policy Number';
UPDATE visit_attribute_type SET name = 'Régime d''assurance', changed_by = 1, date_changed = NOW()
 WHERE uuid = '3a988e33-a6c0-4b76-b924-01abb998944b' AND name = 'Insurance Scheme';
UPDATE visit_attribute_type SET name = 'Mode de paiement', changed_by = 1, date_changed = NOW()
 WHERE uuid = '8553afa0-bdb9-4d3c-8a98-05fa9350aa85' AND name = 'Payment Method';
UPDATE visit_attribute_type SET name = 'Type de patient', changed_by = 1, date_changed = NOW()
 WHERE uuid = 'fbc0702d-b4c9-4968-be63-af8ad3ad6239' AND name = 'Patient Type';
UPDATE visit_attribute_type SET name = 'N° de passage dans la file', changed_by = 1, date_changed = NOW()
 WHERE uuid = 'c0c579b0-8e59-401d-8a4a-976a0b183519' AND name = 'Visit Queue Number';
UPDATE order_type SET name = 'Demande d''examen', changed_by = 1, date_changed = NOW()
 WHERE order_type_id = 3 AND name = 'Test Order';
UPDATE order_type SET name = 'Prescription de médicament', changed_by = 1, date_changed = NOW()
 WHERE order_type_id = 2 AND name = 'Drug Order';

COMMIT;

-- Vérification
SELECT s.service_id, s.name, GROUP_CONCAT(CONCAT(p.name, ' ', FORMAT(p.price, 0)) ORDER BY p.payment_mode SEPARATOR ' | ') prix
  FROM cashier_billable_service s JOIN cashier_item_price p ON p.service_id = s.service_id AND IFNULL(p.retired, 0) = 0
 WHERE s.service_id BETWEEN 4 AND 19 OR s.service_id = 112
 GROUP BY s.service_id, s.name ORDER BY s.service_id;
