-- ============================================================
-- HGest - Phase 0 : traduction française des données de référence
-- Renomme (par UUID) les libellés restés en anglais.
-- Idempotent : peut être rejoué sans effet de bord ; ne supprime rien.
-- Aucun script ni dataset du dépôt ne dépend de ces anciens noms
-- (vérifié par recherche dans grille/, backend/, frontend/, gateway/).
--
-- Usage (après sauvegarde de la base) :
--   scp grille/traduction_fr_donnees.sql ubuntu@<serveur>:/tmp/
--   docker exec -i clinic-platform-db-1 mysql -u openmrs -p openmrs < /tmp/traduction_fr_donnees.sql
-- ============================================================
SET NAMES utf8mb4;

-- Services de rendez-vous
UPDATE appointment_service SET name = 'Médecine générale'
 WHERE uuid = '7ba3aa21-cc56-47ca-bb4d-a60549f666c0' AND name = 'General Medicine service';
UPDATE appointment_service SET name = 'Consultation externe'
 WHERE uuid = '1ef43565-9c96-4f58-bfd2-c864c7cedac1' AND name = 'Outpatient Department';
UPDATE appointment_service SET name = 'Rééducation'
 WHERE uuid = '4ec5c4fe-cfe0-48ff-9e4d-2f201078feae' AND name = 'Rehabilitation service';

-- Files d'attente
UPDATE queue SET name = 'Triage consultation externe'
 WHERE uuid = 'd692a223-e140-11ee-bad2-0242ac120002' AND name = 'Outpatient Triage';
UPDATE queue SET name = 'Consultation externe'
 WHERE uuid = '13b656d3-e141-11ee-bad2-0242ac120002' AND name = 'Outpatient Consultation';

-- Points de caisse
UPDATE cashier_cash_point SET name = 'Caisse consultation externe'
 WHERE uuid = '54065383-b4d4-42d2-af4d-d250a1fd2590' AND name = 'OPD Cash Point';
UPDATE cashier_cash_point SET name = 'Caisse hospitalisation'
 WHERE uuid = 'ba685651-ed3b-4e63-9b35-78893060758a' AND name = 'IPD Cash Point';
UPDATE cashier_cash_point SET name = 'Caisse activités communautaires'
 WHERE uuid = '1ce1b7d4-c865-4178-82b0-5932e51503d6' AND name = 'Community Outreach';

-- Modes de paiement
UPDATE cashier_payment_mode SET name = 'Espèces'
 WHERE uuid = '526bf278-ba81-4436-b867-c2f6641d060a' AND name = 'Cash';
UPDATE cashier_payment_mode SET name = 'Virement bancaire'
 WHERE uuid = '2b1b9aae-5d35-43dd-9214-3fd370fd7737' AND name = 'Bank transfer';
UPDATE cashier_payment_mode SET name = 'PayPal'
 WHERE uuid = 'e168c141-f5fd-4eec-bd3e-633bed1c9606' AND name = 'Paypal';
UPDATE cashier_payment_mode SET name = 'Orange Money'
 WHERE uuid = '46c514e9-2ff0-484c-827f-6e611b0aceb5' AND name = 'orange money';
UPDATE cashier_payment_mode SET name = 'MTN Mobile Money'
 WHERE uuid = '7a4c4b5e-85b9-4cb3-8cac-ce5a737cfcc7' AND name = 'mtn money';

-- Programmes
UPDATE program SET name = 'Soins et traitement du VIH'
 WHERE uuid = '64f950e6-1b07-4ac0-8e7e-f3e148f3463f' AND name = 'HIV Care and Treatment';
UPDATE program SET name = 'PTME (prévention de la transmission mère-enfant)'
 WHERE uuid = 'd1b6cd43-8ac7-4cdd-8fb4-fe51635c82b4' AND name = 'PMTCT';
UPDATE program SET name = 'Prévention du VIH (PEP/PrEP)'
 WHERE uuid = 'ac1bbc45-8c35-49ff-a574-9553ff789527' AND name = 'HIV Preventative Services (PEP/PrEP)';
UPDATE program SET name = 'Éducation au diabète (externe)'
 WHERE uuid = '7a72a724-8994-4d33-962e-f65d8ca4ae67' AND name = 'Outpatient Diabetes Education Program';

-- Lieu technique
UPDATE location SET name = 'Lieu inconnu'
 WHERE uuid = '8d6c993e-c2cc-11de-8d13-0010c6dffd0f' AND name = 'Unknown Location';

-- Non traités ici (volontairement) :
--  * Types de rencontre (Check In, Discharge, Lab Results...) : référencés par certains modules,
--    à traiter après vérification module par module.
--  * Types d'identifiant / attributs (SSN, Race, demo_patient...) : lot « métadonnées patient ».
