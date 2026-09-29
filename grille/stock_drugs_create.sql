-- ============================================================
-- CREATION DES MEDICAMENTS MANQUANTS DANS LE DICTIONNAIRE
-- + CORRECTION DE L'ERREUR DUPLICATE (voided items)
-- ============================================================
-- class_id=3 (Drug), datatype_id=4 (N/A), locale='fr'

-- ETAPE 1 : Vider drug_id/concept_id des items voided (fix duplicate key)
UPDATE stockmgmt_stock_item SET drug_id = NULL, concept_id = NULL WHERE voided = 1;

-- ETAPE 2 : Relancer les liens existants (18 items)
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 325 SET si.drug_id=325, si.concept_id=d.concept_id WHERE si.common_name='Paracetamol cp' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 280 SET si.drug_id=280, si.concept_id=d.concept_id WHERE si.common_name='Ringer lactate' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 300 SET si.drug_id=300, si.concept_id=d.concept_id WHERE si.common_name='Tramadol inj' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 330 SET si.drug_id=330, si.concept_id=d.concept_id WHERE si.common_name='Ciprofloxacine 500mg' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 276 SET si.drug_id=276, si.concept_id=d.concept_id WHERE si.common_name='Ranitidine inj' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 331 SET si.drug_id=331, si.concept_id=d.concept_id WHERE si.common_name='Omeprazole cp' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 247 SET si.drug_id=247, si.concept_id=d.concept_id WHERE si.common_name='Omeprazole inj' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 148 SET si.drug_id=148, si.concept_id=d.concept_id WHERE si.common_name='Fluconazole cp' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 78  SET si.drug_id=78,  si.concept_id=d.concept_id WHERE si.common_name='Ceftriaxone' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 109 SET si.drug_id=109, si.concept_id=d.concept_id WHERE si.common_name='Dexamethasone inj' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 334 SET si.drug_id=334, si.concept_id=d.concept_id WHERE si.common_name='Diclofenac inj' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 151 SET si.drug_id=151, si.concept_id=d.concept_id WHERE si.common_name='Furosemide inj' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 154 SET si.drug_id=154, si.concept_id=d.concept_id WHERE si.common_name='Gentamycine collyre' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 223 SET si.drug_id=223, si.concept_id=d.concept_id WHERE si.common_name='Metronidazole sirop' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 220 SET si.drug_id=220, si.concept_id=d.concept_id WHERE si.common_name='Metronidazole 250mg cp' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 246 SET si.drug_id=246, si.concept_id=d.concept_id WHERE si.common_name='Nystatine sirop' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 244 SET si.drug_id=244, si.concept_id=d.concept_id WHERE si.common_name='Nystatine ovule' AND si.voided=0;
UPDATE stockmgmt_stock_item si JOIN drug d ON d.drug_id = 135 SET si.drug_id=135, si.concept_id=d.concept_id WHERE si.common_name='Erythromycine cp' AND si.voided=0;

-- ============================================================
-- ETAPE 3 : Creer les concepts + drugs manquants (25 items)
-- ============================================================

-- Helper : chaque bloc = INSERT concept → INSERT concept_name → INSERT drug → UPDATE stock_item

-- 1. Artemether (concept parent pour 3 formes)
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c_artemether = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c_artemether,'Artemether','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());

INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c_artemether,'Artemether 80mg inj',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c_artemether WHERE common_name='Artemether 80mg' AND voided=0;

INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c_artemether,'Artemether cp',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c_artemether WHERE common_name='Artemether cp' AND voided=0;

INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c_artemether,'Artemether sirop',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c_artemether WHERE common_name='Artemether sirop' AND voided=0;

-- 2. Artesunate (2 formes)
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c_artesunate = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c_artesunate,'Artesunate','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());

INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c_artesunate,'Artesunate 120mg inj',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c_artesunate WHERE common_name='Artesunate 120mg' AND voided=0;

INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c_artesunate,'Artesunate 60mg inj',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c_artesunate WHERE common_name='Artesunate 60mg' AND voided=0;

-- 3. Amoxicilline+Clavulanate (3 formes)
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c_amoxiclav = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c_amoxiclav,'Amoxicilline+Clavulanate','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());

INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c_amoxiclav,'Amoxiclav cp',1,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c_amoxiclav WHERE common_name='Amoxiclav cp' AND voided=0;

INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c_amoxiclav,'Amoxiclav inj',1,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c_amoxiclav WHERE common_name='Amoxiclav inj' AND voided=0;

INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c_amoxiclav,'Amoxiclav sirop',1,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c_amoxiclav WHERE common_name='Amoxiclav sirop' AND voided=0;

-- 4. Cefixime (2 formes)
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c_cefixime = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c_cefixime,'Cefixime','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());

INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c_cefixime,'Cefixime cp',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c_cefixime WHERE common_name='Cefixime cp' AND voided=0;

INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c_cefixime,'Cefixime sirop',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c_cefixime WHERE common_name='Cefixime sirop' AND voided=0;

-- 5. Carbocysteine (2 formes)
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c_carbo = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c_carbo,'Carbocysteine','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());

INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c_carbo,'Carbocysteine 2%',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c_carbo WHERE common_name='Carbocysteine 2%' AND voided=0;

INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c_carbo,'Carbocysteine 5%',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c_carbo WHERE common_name='Carbocysteine 5%' AND voided=0;

-- 6. Benzathine Penicilline
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c,'Benzathine Penicilline','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());
INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c,'Benzathine inj',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c WHERE common_name='Benzathine inj' AND voided=0;

-- 7. Phloroglucinol
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c,'Phloroglucinol','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());
INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c,'Phloroglucinol inj',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c WHERE common_name='Phloroglucinol inj' AND voided=0;

-- 8. Betadine (Povidone-iodine)
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c,'Povidone-iodine (Betadine)','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());
INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c,'Betadine',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c WHERE common_name='Betadine' AND voided=0;

-- 9. Serum sale NaCl 0,9%
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c,'Chlorure de sodium 0,9%','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());
INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c,'Serum sale 0,9%',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c WHERE common_name='Serum sale 0,9%' AND voided=0;

-- 10. Vitamine B+C
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c,'Vitamine B+C injectable','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());
INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c,'Vitamine B+C inj',1,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c WHERE common_name='Vitamine B+C inj' AND voided=0;

-- 11. Analgin (Metamizole)
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c,'Metamizole (Analgin)','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());
INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c,'Analgin inj',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c WHERE common_name='Analgin inj' AND voided=0;

-- 12. Paracetamol+Therapie (combinaison)
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c,'Paracetamol+Therapie','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());
INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c,'Paracetamol+Therapie cp',1,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c WHERE common_name='Paracetamol+Therapie cp' AND voided=0;

-- 13. Ampicilline
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c,'Ampicilline','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());
INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c,'Ampicilline 1g inj',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c WHERE common_name='Ampicilline 1g inj' AND voided=0;

-- 14. SAT Serum antitetanique
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c,'Serum antitetanique (SAT)','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());
INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c,'SAT (Serum antitetanique)',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c WHERE common_name='SAT (Serum antitetanique)' AND voided=0;

-- 15. Fer + acide folique
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c,'Fer + acide folique','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());
INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c,'Fer + acide folique',1,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c WHERE common_name='Fer + acide folique' AND voided=0;

-- 16. Gentamycine 80mg inj
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c,'Gentamycine injectable','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());
INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c,'Gentamycine 80mg inj',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c WHERE common_name='Gentamycine 80mg inj' AND voided=0;

-- 17. Glucose 5%
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c,'Glucose 5%','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());
INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c,'Glucose 5%',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c WHERE common_name='Glucose 5%' AND voided=0;

-- 18. Metronidazole-PEPF
INSERT INTO concept (retired,class_id,is_set,creator,date_created,datatype_id,uuid) VALUES (0,3,0,1,NOW(),4,UUID());
SET @c = LAST_INSERT_ID();
INSERT INTO concept_name (concept_id,name,locale,locale_preferred,creator,date_created,concept_name_type,uuid) VALUES (@c,'Metronidazole-PEPF','fr',1,1,NOW(),'FULLY_SPECIFIED',UUID());
INSERT INTO drug (concept_id,name,combination,creator,date_created,retired,uuid) VALUES (@c,'Metronidazole-PEPF',0,1,NOW(),0,UUID());
UPDATE stockmgmt_stock_item SET drug_id=LAST_INSERT_ID(), concept_id=@c WHERE common_name='Metronidazole-PEPF' AND voided=0;

-- ============================================================
-- VERIFICATION FINALE
-- ============================================================
SELECT
    SUM(CASE WHEN drug_id IS NOT NULL AND voided=0 THEN 1 ELSE 0 END) AS items_lies_drug,
    SUM(CASE WHEN drug_id IS NULL AND voided=0 AND is_drug=1 THEN 1 ELSE 0 END) AS medicaments_sans_drug,
    SUM(CASE WHEN voided=0 AND is_drug=0 THEN 1 ELSE 0 END) AS consommables
FROM stockmgmt_stock_item;
