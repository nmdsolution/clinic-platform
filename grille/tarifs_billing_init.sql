-- ============================================================
-- TARIFS DE FACTURATION - FONDATION MEDICALE FASSE
-- Script d'initialisation des services facturables
-- ============================================================
-- Usage :
-- scp grille/tarifs_billing_init.sql ubuntu@vps-7de2756e:/tmp/
-- ssh ubuntu@vps-7de2756e
-- docker exec -i clinic-platform-db-1 mysql -u openmrs -popenmrs openmrs < /tmp/tarifs_billing_init.sql

SET @u = 1; -- ID utilisateur admin OpenMRS

-- ============================================================
-- CONSULTATIONS (15 actes)
-- ============================================================

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Consultation medecine generale','Consult. generale','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),5000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Consultation de suivi','Suivi','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),4000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Consultation pediatrique','Pediatrie','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),5000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Consultation gynecologique','Gyneco','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),5000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Consultation specialisee','Consult. spe.','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),5000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Consultation specialisee senior','Consult. senior','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),10000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Consultation prenatale (CPN)','CPN','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),5000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Consultation postnatale','Postnatale','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),5000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Planning familial','Planning','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Consultation urgence','Urgence','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),5000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Urgence nuit/dimanche/jour ferie','Urgence nuit','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),5000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Teleconsultation','Teleconsult.','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),5000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Visite a domicile','Visite domicile','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),5000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Consultation sociale','Sociale','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Carnet de sante','Carnet sante','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1000.00,'Standard',@u,NOW(),0,UUID());

-- ============================================================
-- EXPLORATIONS FONCTIONNELLES (5 actes)
-- ============================================================

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('ECG 12 derivations','ECG','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),20000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Holter ECG 24h','Holter ECG','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),70000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Holter tensionnel/MAPA 24h','MAPA','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),60000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Spirometrie/EFR','EFR','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),20000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Polygraphie ventilatoire nocturne','Polygraphie','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),60000.00,'Standard',@u,NOW(),0,UUID());

-- ============================================================
-- PHARMACIE - Feuille 1 (23 medicaments)
-- ============================================================

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Paracetamol cp','Para cp','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),100.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Benzathine inj','Benzathine','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Phloroglucinol inj','Phloroglucinol','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Betadine','Betadine','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Ringer lactate','Ringer','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Serum sale 0,9%','Serum sale','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Sparadrap (feuille)','Sparadrap','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Tramadol inj','Tramadol','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Vitamine B+C inj','Vit B+C inj','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Analgin inj','Analgin','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Artemether 80mg','Artemether 80','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Artesunate 120mg','Artesun 120','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Artemether cp','Artemether cp','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Seringue 10cc','Seringue 10cc','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),100.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Amoxiclav cp','Amoxiclav cp','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),4200.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Cefixime cp','Cefixim cp','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2100.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Ciprofloxacine 500mg','Cipro 500mg','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Ranitidine inj','Ranitidine','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Omeprazole cp','Omeprazole cp','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Paracetamol+Therapie cp','Para+thera','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2900.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Cefixime sirop','Cefixim sirop','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Fluconazole cp','Fluconazole','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Nystatine ovule','Nystatine ovule','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1600.00,'Standard',@u,NOW(),0,UUID());

-- ============================================================
-- PHARMACIE - Feuille 2 (24 medicaments)
-- ============================================================

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Epicraniens','Epicraniens','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),100.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Amoxiclav inj','Amoxiclav inj','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1850.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Amoxiclav sirop','Amoxiclav sir.','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2640.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Ampicilline 1g inj','Amp 1g inj','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('SAT (Serum antitetanique)','SAT','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Artesunate 60mg','Artesunate 60','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1350.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Artemether sirop','Artemether sir.','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1600.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Carbocysteine 2%','Carbocyst. 2%','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Carbocysteine 5%','Carbocyst. 5%','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1600.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Catheter (bleu/jaune)','Catheter','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Ceftriaxone','Ceftriaxone','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Dexamethasone inj','Dexa inj','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Diclofenac inj','Diclo inj','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Erythromycine cp','Erythromycine','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Fer + acide folique','Fer+Folate','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),300.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Furosemide inj','Furosemide','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Gentamycine collyre','Genta collyre','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Gentamycine 80mg inj','Genta 80mg','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Glucose 5%','Glucose 5%','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),900.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Metronidazole sirop','Metro sirop','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Metronidazole 250mg cp','Metro 250mg','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),300.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Metronidazole-PEPF','Metro-PEPF','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Nystatine sirop','Nystatine sir.','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Omeprazole inj','Omeprazole inj','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1500.00,'Standard',@u,NOW(),0,UUID());

-- ============================================================
-- VERIFICATION
-- ============================================================
SELECT COUNT(*) AS total_services FROM cashier_billable_service WHERE retired=0;
SELECT COUNT(*) AS total_prix FROM cashier_item_price WHERE retired=0;
