-- ============================================================
-- STOCK INITIAL - PHARMACIE FASSE
-- Quantites d'ouverture - Septembre 2026
-- Source : proposition_du_tableau_des_prix_de_vente.docx
-- ============================================================

-- 1. Creer l'operation Opening Stock
INSERT INTO stockmgmt_stock_operation (
    operation_type_id,
    status,
    operation_date,
    operation_number,
    remarks,
    at_location_id,
    destination_id,
    creator,
    date_created,
    voided,
    uuid
) VALUES (
    9,
    'COMPLETED',
    NOW(),
    'OS-FASSE-2026-001',
    'Stock initial Pharmacie FASSE - Septembre 2026',
    2,
    1,
    1,
    NOW(),
    0,
    UUID()
);

SET @op_id = LAST_INSERT_ID();

-- 2. Inserer les 47 lignes de stock
INSERT INTO stockmgmt_stock_operation_item (
    stock_operation_id, stock_item_id, quantity, creator, date_created, voided, uuid
) VALUES

-- FEUILLE 1 (23 articles)
(@op_id, 13,  20.00, 1, NOW(), 0, UUID()),  -- Paracetamol cp
(@op_id, 14,  10.00, 1, NOW(), 0, UUID()),  -- Benzathine inj
(@op_id, 15,  18.00, 1, NOW(), 0, UUID()),  -- Phloroglucinol inj
(@op_id, 16,   2.00, 1, NOW(), 0, UUID()),  -- Betadine
(@op_id, 17,  10.00, 1, NOW(), 0, UUID()),  -- Ringer lactate
(@op_id, 18,  10.00, 1, NOW(), 0, UUID()),  -- Serum sale 0,9%
(@op_id, 19,   1.00, 1, NOW(), 0, UUID()),  -- Sparadrap (feuille)
(@op_id, 20,  10.00, 1, NOW(), 0, UUID()),  -- Tramadol inj
(@op_id, 21,  20.00, 1, NOW(), 0, UUID()),  -- Vitamine B+C inj
(@op_id, 22,  10.00, 1, NOW(), 0, UUID()),  -- Analgin inj
(@op_id, 23,  18.00, 1, NOW(), 0, UUID()),  -- Artemether 80mg
(@op_id, 24,  20.00, 1, NOW(), 0, UUID()),  -- Artesunate 120mg
(@op_id, 25,  10.00, 1, NOW(), 0, UUID()),  -- Artemether cp
(@op_id, 26, 100.00, 1, NOW(), 0, UUID()),  -- Seringue 10cc
(@op_id, 27,   5.00, 1, NOW(), 0, UUID()),  -- Amoxiclav cp
(@op_id, 28,   3.00, 1, NOW(), 0, UUID()),  -- Cefixime cp
(@op_id, 29,   3.00, 1, NOW(), 0, UUID()),  -- Ciprofloxacine 500mg
(@op_id, 30,  10.00, 1, NOW(), 0, UUID()),  -- Ranitidine inj
(@op_id, 31,   3.00, 1, NOW(), 0, UUID()),  -- Omeprazole cp
(@op_id, 32,   2.00, 1, NOW(), 0, UUID()),  -- Paracetamol+Therapie cp
(@op_id, 33,   5.00, 1, NOW(), 0, UUID()),  -- Cefixime sirop
(@op_id, 34,   5.00, 1, NOW(), 0, UUID()),  -- Fluconazole cp
(@op_id, 35,   3.00, 1, NOW(), 0, UUID()),  -- Nystatine ovule

-- FEUILLE 2 (24 articles)
(@op_id, 36,  50.00, 1, NOW(), 0, UUID()),  -- Epicraniens
(@op_id, 37,  10.00, 1, NOW(), 0, UUID()),  -- Amoxiclav inj
(@op_id, 38,  10.00, 1, NOW(), 0, UUID()),  -- Amoxiclav sirop
(@op_id, 39,  20.00, 1, NOW(), 0, UUID()),  -- Ampicilline 1g inj
(@op_id, 40,   5.00, 1, NOW(), 0, UUID()),  -- SAT (Serum antitetanique)
(@op_id, 41,  20.00, 1, NOW(), 0, UUID()),  -- Artesunate 60mg
(@op_id, 42,  10.00, 1, NOW(), 0, UUID()),  -- Artemether sirop
(@op_id, 43,  10.00, 1, NOW(), 0, UUID()),  -- Carbocysteine 2%
(@op_id, 44,  10.00, 1, NOW(), 0, UUID()),  -- Carbocysteine 5%
(@op_id, 45,  50.00, 1, NOW(), 0, UUID()),  -- Catheter (bleu/jaune)
(@op_id, 46,  25.00, 1, NOW(), 0, UUID()),  -- Ceftriaxone
(@op_id, 47,  20.00, 1, NOW(), 0, UUID()),  -- Dexamethasone inj
(@op_id, 48,  20.00, 1, NOW(), 0, UUID()),  -- Diclofenac inj
(@op_id, 49,  10.00, 1, NOW(), 0, UUID()),  -- Erythromycine cp
(@op_id, 50,  50.00, 1, NOW(), 0, UUID()),  -- Fer + acide folique
(@op_id, 51,   5.00, 1, NOW(), 0, UUID()),  -- Furosemide inj
(@op_id, 52,  10.00, 1, NOW(), 0, UUID()),  -- Gentamycine collyre
(@op_id, 53,  20.00, 1, NOW(), 0, UUID()),  -- Gentamycine 80mg inj
(@op_id, 54,  20.00, 1, NOW(), 0, UUID()),  -- Glucose 5%
(@op_id, 55,  15.00, 1, NOW(), 0, UUID()),  -- Metronidazole sirop
(@op_id, 56,  50.00, 1, NOW(), 0, UUID()),  -- Metronidazole 250mg cp
(@op_id, 57,  10.00, 1, NOW(), 0, UUID()),  -- Metronidazole-PEPF
(@op_id, 58,  15.00, 1, NOW(), 0, UUID()),  -- Nystatine sirop
(@op_id, 59,  10.00, 1, NOW(), 0, UUID());  -- Omeprazole inj

-- Verification
SELECT
    o.stock_operation_id,
    o.operation_number,
    o.status,
    COUNT(i.stock_operation_item_id) AS nb_articles,
    SUM(i.quantity) AS quantite_totale
FROM stockmgmt_stock_operation o
JOIN stockmgmt_stock_operation_item i ON i.stock_operation_id = o.stock_operation_id
WHERE o.stock_operation_id = @op_id
GROUP BY o.stock_operation_id, o.operation_number, o.status;
