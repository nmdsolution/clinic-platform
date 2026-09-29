-- ============================================================
-- TRANSACTIONS STOCK INITIAL - PHARMACIE FASSE
-- Complète l'opération OS-FASSE-2026-001 (stock_operation_id=3)
-- Crée : UOM (Pièce), lots (batch), et transactions de solde
-- ============================================================

-- 1. Créer UOM "Pièce" pour les 47 articles (IDs 13-59)
INSERT INTO stockmgmt_stock_item_packaging_uom
  (stock_item_id, packaging_uom_id, factor, creator, date_created, voided, uuid)
SELECT stock_item_id, 3649, 1.00, 1, NOW(), 0, UUID()
FROM stockmgmt_stock_item
WHERE stock_item_id BETWEEN 13 AND 59 AND voided = 0;

-- 2. Créer un lot "INIT-2026-09" pour chaque article
INSERT INTO stockmgmt_stock_batch
  (stock_item_id, batch_no, creator, date_created, voided, uuid)
SELECT stock_item_id, 'INIT-2026-09', 1, NOW(), 0, UUID()
FROM stockmgmt_stock_item
WHERE stock_item_id BETWEEN 13 AND 59 AND voided = 0;

-- 3. Créer les transactions liées à l'opération Opening Stock (id=3)
INSERT INTO stockmgmt_stock_item_transaction
  (stock_operation_id, stock_operation_item_id, stock_item_id,
   stock_item_packaging_uom_id, quantity, stock_batch_id,
   party_id, creator, date_created, uuid)
SELECT
  oi.stock_operation_id,
  oi.stock_operation_item_id,
  oi.stock_item_id,
  uom.stock_item_packaging_uom_id,
  oi.quantity,
  b.stock_batch_id,
  1,
  1,
  NOW(),
  UUID()
FROM stockmgmt_stock_operation_item oi
JOIN stockmgmt_stock_item_packaging_uom uom
  ON uom.stock_item_id = oi.stock_item_id AND uom.voided = 0
JOIN stockmgmt_stock_batch b
  ON b.stock_item_id = oi.stock_item_id AND b.voided = 0
WHERE oi.stock_operation_id = 3 AND oi.voided = 0;

-- Vérification
SELECT
  si.common_name,
  t.quantity,
  b.batch_no,
  t.party_id
FROM stockmgmt_stock_item_transaction t
JOIN stockmgmt_stock_item si ON si.stock_item_id = t.stock_item_id
JOIN stockmgmt_stock_batch b ON b.stock_batch_id = t.stock_batch_id
WHERE t.stock_operation_id = 3
ORDER BY si.common_name;
