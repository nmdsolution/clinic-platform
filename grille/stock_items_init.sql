-- ============================================================
-- ARTICLES DE STOCK - FONDATION MEDICALE FASSE
-- ============================================================
-- Vide les items existants, insere les 47 medicaments de la grille
-- Usage :
-- wget https://raw.githubusercontent.com/nmdsolution/clinic-platform/develop/grille/stock_items_init.sql -O /tmp/stock_items_init.sql
-- docker exec -i clinic-platform-db-1 mysql -u openmrs -popenmrs openmrs < /tmp/stock_items_init.sql

-- 1. Vider les items existants
UPDATE stockmgmt_stock_item
SET voided = 1, voided_by = 1, date_voided = NOW(), void_reason = 'Remplace par articles FASSE'
WHERE voided = 0;

-- 2. Inserer les 47 articles de la grille FASSE
--    is_drug=1 : medicaments  |  is_drug=0 : consommables/fournitures
--    has_expiration=1 : tous les articles ont une date de peremption

INSERT INTO stockmgmt_stock_item (common_name, is_drug, has_expiration, creator, date_created, voided, uuid) VALUES

-- ========================
-- FEUILLE 1 (23 articles)
-- ========================
('Paracetamol cp',            1, 1, 1, NOW(), 0, UUID()),
('Benzathine inj',            1, 1, 1, NOW(), 0, UUID()),
('Phloroglucinol inj',        1, 1, 1, NOW(), 0, UUID()),
('Betadine',                  1, 1, 1, NOW(), 0, UUID()),
('Ringer lactate',            1, 1, 1, NOW(), 0, UUID()),
('Serum sale 0,9%',           1, 1, 1, NOW(), 0, UUID()),
('Sparadrap (feuille)',        0, 1, 1, NOW(), 0, UUID()),
('Tramadol inj',              1, 1, 1, NOW(), 0, UUID()),
('Vitamine B+C inj',          1, 1, 1, NOW(), 0, UUID()),
('Analgin inj',               1, 1, 1, NOW(), 0, UUID()),
('Artemether 80mg',           1, 1, 1, NOW(), 0, UUID()),
('Artesunate 120mg',          1, 1, 1, NOW(), 0, UUID()),
('Artemether cp',             1, 1, 1, NOW(), 0, UUID()),
('Seringue 10cc',             0, 1, 1, NOW(), 0, UUID()),
('Amoxiclav cp',              1, 1, 1, NOW(), 0, UUID()),
('Cefixime cp',               1, 1, 1, NOW(), 0, UUID()),
('Ciprofloxacine 500mg',      1, 1, 1, NOW(), 0, UUID()),
('Ranitidine inj',            1, 1, 1, NOW(), 0, UUID()),
('Omeprazole cp',             1, 1, 1, NOW(), 0, UUID()),
('Paracetamol+Therapie cp',   1, 1, 1, NOW(), 0, UUID()),
('Cefixime sirop',            1, 1, 1, NOW(), 0, UUID()),
('Fluconazole cp',            1, 1, 1, NOW(), 0, UUID()),
('Nystatine ovule',           1, 1, 1, NOW(), 0, UUID()),

-- ========================
-- FEUILLE 2 (24 articles)
-- ========================
('Epicraniens',               0, 1, 1, NOW(), 0, UUID()),
('Amoxiclav inj',             1, 1, 1, NOW(), 0, UUID()),
('Amoxiclav sirop',           1, 1, 1, NOW(), 0, UUID()),
('Ampicilline 1g inj',        1, 1, 1, NOW(), 0, UUID()),
('SAT (Serum antitetanique)', 1, 1, 1, NOW(), 0, UUID()),
('Artesunate 60mg',           1, 1, 1, NOW(), 0, UUID()),
('Artemether sirop',          1, 1, 1, NOW(), 0, UUID()),
('Carbocysteine 2%',          1, 1, 1, NOW(), 0, UUID()),
('Carbocysteine 5%',          1, 1, 1, NOW(), 0, UUID()),
('Catheter (bleu/jaune)',      0, 1, 1, NOW(), 0, UUID()),
('Ceftriaxone',               1, 1, 1, NOW(), 0, UUID()),
('Dexamethasone inj',         1, 1, 1, NOW(), 0, UUID()),
('Diclofenac inj',            1, 1, 1, NOW(), 0, UUID()),
('Erythromycine cp',          1, 1, 1, NOW(), 0, UUID()),
('Fer + acide folique',       1, 1, 1, NOW(), 0, UUID()),
('Furosemide inj',            1, 1, 1, NOW(), 0, UUID()),
('Gentamycine collyre',       1, 1, 1, NOW(), 0, UUID()),
('Gentamycine 80mg inj',      1, 1, 1, NOW(), 0, UUID()),
('Glucose 5%',                1, 1, 1, NOW(), 0, UUID()),
('Metronidazole sirop',       1, 1, 1, NOW(), 0, UUID()),
('Metronidazole 250mg cp',    1, 1, 1, NOW(), 0, UUID()),
('Metronidazole-PEPF',        1, 1, 1, NOW(), 0, UUID()),
('Nystatine sirop',           1, 1, 1, NOW(), 0, UUID()),
('Omeprazole inj',            1, 1, 1, NOW(), 0, UUID());

-- Verification
SELECT
    SUM(CASE WHEN voided=0 THEN 1 ELSE 0 END) AS articles_actifs,
    SUM(CASE WHEN voided=1 THEN 1 ELSE 0 END) AS articles_voided,
    SUM(CASE WHEN voided=0 AND is_drug=1 THEN 1 ELSE 0 END) AS medicaments,
    SUM(CASE WHEN voided=0 AND is_drug=0 THEN 1 ELSE 0 END) AS consommables
FROM stockmgmt_stock_item;
