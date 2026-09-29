-- ============================================================
-- TARIFS LABO - FONDATION MEDICALE FASSE
-- Grille tarifaire examens disponibles (actualisee 12/09/2026)
-- ============================================================
-- Usage :
-- scp grille/tarifs_labo_init.sql ubuntu@vps-7de2756e:/tmp/
-- docker exec -i clinic-platform-db-1 mysql -u openmrs -popenmrs openmrs < /tmp/tarifs_labo_init.sql

SET @u = 1;

-- ============================================================
-- BIOCHIMIE (12 examens)
-- ============================================================

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Glycemie','Glycemie','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Uree','Uree','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Creatinine','Creatinine','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Acide urique','Acide urique','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('ASAT + ALAT (transaminases)','ASAT+ALAT','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),6500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Cholesterol total','Chol. total','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('HDL','HDL','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),3500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('LDL','LDL','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),3500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Triglycerides','TG','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),3500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Bilirubine totale','Bili. totale','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),3500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Bilirubine directe','Bili. directe','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),3500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Bilan lipidique (Chol+HDL+LDL+TG)','Bilan lipidique','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),11000.00,'Standard',@u,NOW(),0,UUID());

-- ============================================================
-- HEMATOLOGIE (5 examens)
-- ============================================================

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Hemoglobine rapide','Hb rapide','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Groupe sanguin','Groupe sanguin','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),4000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Frottis sanguin','Frottis','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Vitesse de sedimentation (VS)','VS','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),1500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('TP / INR','TP/INR','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),4500.00,'Standard',@u,NOW(),0,UUID());

-- ============================================================
-- IMMUNO-SEROLOGIE (8 examens)
-- ============================================================

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('VIH','VIH','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Ag HBs','Ag HBs','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),3000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Ac HCV','Ac HCV','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),3000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('TPHA / VDRL','TPHA/VDRL','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),4000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('CRP','CRP','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),3500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Chlamydia IgG/IgM','Chlamydia','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),5000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Test de grossesse sanguin','Test gross. sang.','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),3500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Test de grossesse urinaire','Test gross. urin.','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),3000.00,'Standard',@u,NOW(),0,UUID());

-- ============================================================
-- PARASITOLOGIE (4 examens)
-- ============================================================

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Goutte epaisse','Goutte epaisse','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('TDR palu','TDR palu','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Coprologie','Coprologie','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Recherche hemoparasites','Hemoparasites','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2500.00,'Standard',@u,NOW(),0,UUID());

-- ============================================================
-- BACTERIOLOGIE (3 examens)
-- ============================================================

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('ECBU simple','ECBU','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),3500.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('PCV simple','PCV','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),4000.00,'Standard',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Bandelette urinaire','Bandelette urin.','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2000.00,'Standard',@u,NOW(),0,UUID());

-- ============================================================
-- FORFAITS LABO (8 forfaits)
-- ============================================================

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Forfait Bilan de base (Hb+Glyc+Creat)','Bilan de base','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),3500.00,'Forfait',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Forfait Fievre & anemie sans CRP (TDR+Hb)','Fievre anemie','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),2500.00,'Forfait',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Forfait Fievre & anemie avec CRP (TDR+Hb+CRP)','Fievre+CRP','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),6000.00,'Forfait',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Forfait Bilan general (Hb+Glyc+Creat+Uree+ALAT+Chol+TG)','Bilan general','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),15000.00,'Forfait',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Forfait Bilan cardiovasculaire (Glyc+Creat+Chol+HDL+LDL+TG)','Bilan cardio','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),14000.00,'Forfait',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Forfait Depistage hepatites B & C (AgHBs+AcHCV)','Hepatites B&C','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),5500.00,'Forfait',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Pack IST de base (VIH+TPHA+AgHBs+AcHCV)','IST de base','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),10000.00,'Forfait',@u,NOW(),0,UUID());

INSERT INTO cashier_billable_service (name,short_name,service_status,creator,date_created,retired,uuid)
VALUES ('Pack IST complet (VIH+TPHA+AgHBs+AcHCV+Chlamydia)','IST complet','ENABLED',@u,NOW(),0,UUID());
INSERT INTO cashier_item_price (service_id,price,name,creator,date_created,retired,uuid)
VALUES (LAST_INSERT_ID(),15000.00,'Forfait',@u,NOW(),0,UUID());

-- ============================================================
-- VERIFICATION
-- ============================================================
SELECT COUNT(*) AS total_services FROM cashier_billable_service WHERE retired=0;
SELECT COUNT(*) AS total_prix FROM cashier_item_price WHERE retired=0;
