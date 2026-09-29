-- ============================================================
-- LIAISON ARTICLES STOCK → DICTIONNAIRE MEDICAMENTS OPENMRS
-- Corrige le type "Autre" en "Medicament" pour les items
-- qui ont une correspondance dans la table drug
-- ============================================================

-- Paracetamol cp → Paracétamol 500mg comprimé (drug_id 325)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 325
SET si.drug_id = 325, si.concept_id = d.concept_id
WHERE si.common_name = 'Paracetamol cp' AND si.voided = 0;

-- Ringer lactate → Ringer Lactate (drug_id 280)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 280
SET si.drug_id = 280, si.concept_id = d.concept_id
WHERE si.common_name = 'Ringer lactate' AND si.voided = 0;

-- Tramadol inj → Tramadol Injection vial 100mg (drug_id 300)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 300
SET si.drug_id = 300, si.concept_id = d.concept_id
WHERE si.common_name = 'Tramadol inj' AND si.voided = 0;

-- Ciprofloxacine 500mg → Ciprofloxacine 500mg comprimé (drug_id 330)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 330
SET si.drug_id = 330, si.concept_id = d.concept_id
WHERE si.common_name = 'Ciprofloxacine 500mg' AND si.voided = 0;

-- Ranitidine inj → Ranitidine Injection vial 50mg (drug_id 276)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 276
SET si.drug_id = 276, si.concept_id = d.concept_id
WHERE si.common_name = 'Ranitidine inj' AND si.voided = 0;

-- Omeprazole cp → Oméprazole 20mg comprimé (drug_id 331)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 331
SET si.drug_id = 331, si.concept_id = d.concept_id
WHERE si.common_name = 'Omeprazole cp' AND si.voided = 0;

-- Omeprazole inj → Omeprazole Co 20mg (drug_id 247, meme concept)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 247
SET si.drug_id = 247, si.concept_id = d.concept_id
WHERE si.common_name = 'Omeprazole inj' AND si.voided = 0;

-- Fluconazole cp → Fluconazole Co 150mg (drug_id 148)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 148
SET si.drug_id = 148, si.concept_id = d.concept_id
WHERE si.common_name = 'Fluconazole cp' AND si.voided = 0;

-- Ceftriaxone → Ceftriaxone 1g (drug_id 78)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 78
SET si.drug_id = 78, si.concept_id = d.concept_id
WHERE si.common_name = 'Ceftriaxone' AND si.voided = 0;

-- Dexamethasone inj → Dexamethasone Injection vial 8mg (drug_id 109)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 109
SET si.drug_id = 109, si.concept_id = d.concept_id
WHERE si.common_name = 'Dexamethasone inj' AND si.voided = 0;

-- Diclofenac inj → Diclofénac 75mg/3ml injectable (drug_id 334)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 334
SET si.drug_id = 334, si.concept_id = d.concept_id
WHERE si.common_name = 'Diclofenac inj' AND si.voided = 0;

-- Furosemide inj → Furosemide Injection vial 20mg (drug_id 151)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 151
SET si.drug_id = 151, si.concept_id = d.concept_id
WHERE si.common_name = 'Furosemide inj' AND si.voided = 0;

-- Gentamycine collyre → Gentamicin 0.3% (drug_id 154)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 154
SET si.drug_id = 154, si.concept_id = d.concept_id
WHERE si.common_name = 'Gentamycine collyre' AND si.voided = 0;

-- Metronidazole sirop → Metronidazole Sirop 250mg (drug_id 223)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 223
SET si.drug_id = 223, si.concept_id = d.concept_id
WHERE si.common_name = 'Metronidazole sirop' AND si.voided = 0;

-- Metronidazole 250mg cp → Metronidazole 250mg (drug_id 220)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 220
SET si.drug_id = 220, si.concept_id = d.concept_id
WHERE si.common_name = 'Metronidazole 250mg cp' AND si.voided = 0;

-- Nystatine sirop → Nystatin Sirop 100000UI (drug_id 246)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 246
SET si.drug_id = 246, si.concept_id = d.concept_id
WHERE si.common_name = 'Nystatine sirop' AND si.voided = 0;

-- Nystatine ovule → Nystatin 100000U/g (drug_id 244)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 244
SET si.drug_id = 244, si.concept_id = d.concept_id
WHERE si.common_name = 'Nystatine ovule' AND si.voided = 0;

-- Erythromycine cp → Erythromycin (drug_id 135, meme concept)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 135
SET si.drug_id = 135, si.concept_id = d.concept_id
WHERE si.common_name = 'Erythromycine cp' AND si.voided = 0;

-- Verification : compter les items avec et sans drug_id
SELECT
    SUM(CASE WHEN drug_id IS NOT NULL THEN 1 ELSE 0 END) AS lies_au_dictionnaire,
    SUM(CASE WHEN drug_id IS NULL AND voided = 0 THEN 1 ELSE 0 END) AS sans_correspondance
FROM stockmgmt_stock_item
WHERE voided = 0;
