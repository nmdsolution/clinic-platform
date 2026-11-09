-- ============================================================
-- EXAMENS DE LABORATOIRE PRESCRIPTIBLES - FONDATION MEDICALE FASSE
-- Relie chaque service facturable du labo (tarifs_labo_init.sql) au
-- concept que le medecin prescrit, pour que le tarif soit ajoute
-- automatiquement a la facture lors de la prescription.
-- ============================================================
-- Prerequis : tarifs_labo_init.sql deja execute, et le backend
-- redemarre avec concepts/laboratory_orderables_fasse.csv (Initializer).
-- Usage :
-- scp grille/labo_examens_prescriptibles.sql ubuntu@vps-7de2756e:/tmp/
-- docker exec -i clinic-platform-db-1 mysql -u openmrs -popenmrs openmrs < /tmp/labo_examens_prescriptibles.sql
-- Le script est rejouable sans effet de bord.

UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'f05f813d-6a57-47ce-92da-40fb565c8992') WHERE name = 'Glycemie' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'e8887b1c-ebe3-4cad-b8d5-c22df3db954e') WHERE name = 'Uree' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '1404cca8-7fe1-48a7-aa2d-f4cbd036a049') WHERE name = 'Creatinine' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'e9c0da5a-5b4d-561c-a742-bccac109ab83') WHERE name = 'Acide urique' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '02903a6c-580d-51f9-8242-5c1cc5e6dc9f') WHERE name = 'ASAT + ALAT (transaminases)' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'cd272b11-1cbe-5007-959c-e2598041e69a') WHERE name = 'Cholesterol total' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'e9584591-7403-5ff6-aae2-39d75f5ffee2') WHERE name = 'HDL' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '989da1de-afd9-57dc-b1db-fda3a5d051e0') WHERE name = 'LDL' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '0054bc1c-3342-541a-9ca9-6fb6c689e81e') WHERE name = 'Triglycerides' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '4d75bf69-f1ff-58d2-bd48-3991319f3fca') WHERE name = 'Bilirubine totale' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'aba1312f-28fa-5cc5-8dfc-a112f1494599') WHERE name = 'Bilirubine directe' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '9510314a-d70a-5ba6-bbba-a72515fd6533') WHERE name = 'Bilan lipidique (Chol+HDL+LDL+TG)' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '7deb3c85-f51c-5267-98bc-38af1bda15f6') WHERE name = 'Hemoglobine rapide' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '83dae2a9-c6f1-5599-aa59-7fe6080bec6e') WHERE name = 'Groupe sanguin' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '59872d4f-628c-5888-9720-3c9809dafda0') WHERE name = 'Frottis sanguin' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '1b62ee4e-2f7b-51ad-9d51-fc4524fe4cbe') WHERE name = 'Vitesse de sedimentation (VS)' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'd9a2403a-6992-55c8-a3bd-09157076a7ec') WHERE name = 'TP / INR' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '7481ae23-4839-5cf6-84cc-ca57a7e7b632') WHERE name = 'VIH' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '5011e915-88e9-5d51-a281-242b240d5703') WHERE name = 'Ag HBs' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'f609367b-a6d4-5d12-acde-e086b8f5b37f') WHERE name = 'Ac HCV' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '12e4cd41-d023-5160-af9f-9539debbb938') WHERE name = 'TPHA / VDRL' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'df44da8b-b18c-4a9d-ac4b-435552de01c5') WHERE name = 'CRP' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'd148f449-85ce-5cea-affe-16cc69a02411') WHERE name = 'Chlamydia IgG/IgM' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '5c54f307-25ef-5f3d-b85e-8ffa01f05eac') WHERE name = 'Test de grossesse sanguin' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'dbebc9de-c795-5efd-ad2e-1df7b6738405') WHERE name = 'Test de grossesse urinaire' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'e01d1d28-a7d0-5eef-8433-03c165c5b8e4') WHERE name = 'Goutte epaisse' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '656466a7-1f34-55ee-a5aa-8fb3b14c8b38') WHERE name = 'TDR palu' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'a8d50ce9-7f71-5f43-bc1b-fe47a1759b51') WHERE name = 'Coprologie' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'f0ab6288-9a6e-5a2b-ab95-b9f753505781') WHERE name = 'Recherche hemoparasites' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'd00c3e4d-9281-5b6c-9011-2ddb49d530ed') WHERE name = 'ECBU simple' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '12da20c9-a813-5737-9433-9ed1f6310878') WHERE name = 'PCV simple' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '8dd86621-504f-572b-827d-151ea8ebd6a2') WHERE name = 'Bandelette urinaire' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'ed5da797-4c12-5594-a6c7-2caa052a15ed') WHERE name = 'Forfait Bilan de base (Hb+Glyc+Creat)' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'ccc2ccdf-5848-5440-b3cb-8806c375f8e2') WHERE name = 'Forfait Fievre & anemie sans CRP (TDR+Hb)' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '07cd5106-f3e2-578e-8e0a-800eb0e08743') WHERE name = 'Forfait Fievre & anemie avec CRP (TDR+Hb+CRP)' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '9fa8bce8-67ca-52a7-8ed5-4b85dae407be') WHERE name = 'Forfait Bilan general (Hb+Glyc+Creat+Uree+ALAT+Chol+TG)' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = 'c80f482e-54c4-59b7-8fee-617187a4b23a') WHERE name = 'Forfait Bilan cardiovasculaire (Glyc+Creat+Chol+HDL+LDL+TG)' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '7fd918d9-5d16-51e0-9fcc-3e5267b444e6') WHERE name = 'Forfait Depistage hepatites B & C (AgHBs+AcHCV)' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '2c6d921e-eb43-5404-8795-e92341f01400') WHERE name = 'Pack IST de base (VIH+TPHA+AgHBs+AcHCV)' AND retired = 0;
UPDATE cashier_billable_service SET concept_id = (SELECT concept_id FROM concept WHERE uuid = '5daa14ba-c70d-5ce1-8fd5-bf40198fc9c5') WHERE name = 'Pack IST complet (VIH+TPHA+AgHBs+AcHCV+Chlamydia)' AND retired = 0;

-- ============================================================
-- VERIFICATION : doit renvoyer 40 lignes liees et 0 ligne sans concept
-- ============================================================
SELECT s.name AS service, c.uuid AS concept_uuid, p.price
FROM cashier_billable_service s
LEFT JOIN concept c ON c.concept_id = s.concept_id
LEFT JOIN cashier_item_price p ON p.service_id = s.service_id AND p.retired = 0
WHERE s.retired = 0 AND s.name IN (
  'Glycemie',
  'Uree',
  'Creatinine',
  'Acide urique',
  'ASAT + ALAT (transaminases)',
  'Cholesterol total',
  'HDL',
  'LDL',
  'Triglycerides',
  'Bilirubine totale',
  'Bilirubine directe',
  'Bilan lipidique (Chol+HDL+LDL+TG)',
  'Hemoglobine rapide',
  'Groupe sanguin',
  'Frottis sanguin',
  'Vitesse de sedimentation (VS)',
  'TP / INR',
  'VIH',
  'Ag HBs',
  'Ac HCV',
  'TPHA / VDRL',
  'CRP',
  'Chlamydia IgG/IgM',
  'Test de grossesse sanguin',
  'Test de grossesse urinaire',
  'Goutte epaisse',
  'TDR palu',
  'Coprologie',
  'Recherche hemoparasites',
  'ECBU simple',
  'PCV simple',
  'Bandelette urinaire',
  'Forfait Bilan de base (Hb+Glyc+Creat)',
  'Forfait Fievre & anemie sans CRP (TDR+Hb)',
  'Forfait Fievre & anemie avec CRP (TDR+Hb+CRP)',
  'Forfait Bilan general (Hb+Glyc+Creat+Uree+ALAT+Chol+TG)',
  'Forfait Bilan cardiovasculaire (Glyc+Creat+Chol+HDL+LDL+TG)',
  'Forfait Depistage hepatites B & C (AgHBs+AcHCV)',
  'Pack IST de base (VIH+TPHA+AgHBs+AcHCV)',
  'Pack IST complet (VIH+TPHA+AgHBs+AcHCV+Chlamydia)'
) ORDER BY s.name;
