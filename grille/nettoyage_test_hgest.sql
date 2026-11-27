-- ============================================================
-- Décision 2 (validée le 27/11/2026) : annulation du test logiciel
-- Patient TEST HGEST, dossier 1000ECT (patient_id 427).
--
-- Rien n'est supprimé : tout est annulé (voided) avec le motif ci-dessous et
-- reste récupérable. Les tableaux de bord filtrent b.voided = 0 et
-- bp.voided = 0 : les recettes reviennent au réel.
--
-- Ordre d'application :
--   0. Sauvegarde : mysqldump complet dans ~/backups/avant_nettoyage_test_<date>.sql.gz
--   1. Vérifier que le rapport « Facturation par période » ignore aussi les factures
--      et paiements annulés (sinon le corriger d'abord).
--   2. Stock : remettre les 3 Fioles de Ceftriaxone (lot INIT-2026-09, Pharmacie
--      principale) par une opération « Ajustement » avec le motif ci-dessous, dans
--      Gestion des stocks. Le solde du lot repasse de 22 à 25 et l'historique garde
--      la sortie et la correction.
--   3. Ce script (facturation).
--   4. Partie clinique par l'API REST, qui annule proprement les objets liés :
--        DELETE order/<uuid>?reason=...        (commandes 385 à 388)
--        DELETE medicationdispense/<uuid>      (délivrance 201)
--        DELETE encounter/<uuid>?reason=...    (1508, 1511, 1512, 1513 : annule aussi les obs)
--        DELETE visit/<uuid>?reason=...        (367)
--        DELETE patient/ba4f982c-1acc-438c-ac26-b6abb679202a?reason=...
--   5. Relancer la requête d'inventaire : tout doit être à 0.
-- ============================================================
SET @motif = 'Test logiciel HGEST 26/11/2026 - annulé';
SET @patient = 427;

START TRANSACTION;

-- Paiement de 2 000 FCFA (facture 0021-6)
UPDATE cashier_bill_payment bp JOIN cashier_bill b ON b.bill_id = bp.bill_id
   SET bp.voided = 1, bp.voided_by = 1, bp.date_voided = NOW(), bp.void_reason = @motif
 WHERE b.patient_id = @patient AND bp.voided = 0;

-- Lignes de facture
UPDATE cashier_bill_line_item li JOIN cashier_bill b ON b.bill_id = li.bill_id
   SET li.voided = 1, li.voided_by = 1, li.date_voided = NOW(), li.void_reason = @motif
 WHERE b.patient_id = @patient AND li.voided = 0;

-- Factures 0021-6, 0022-4, 0023-2, 0024-0
UPDATE cashier_bill
   SET voided = 1, voided_by = 1, date_voided = NOW(), void_reason = @motif
 WHERE patient_id = @patient AND voided = 0;

COMMIT;

-- Contrôle
SELECT receipt_number, status, voided, void_reason FROM cashier_bill WHERE patient_id = @patient;
SELECT bp.bill_payment_id, bp.amount, bp.voided FROM cashier_bill_payment bp
  JOIN cashier_bill b ON b.bill_id = bp.bill_id WHERE b.patient_id = @patient;
