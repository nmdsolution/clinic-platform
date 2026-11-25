-- ============================================================
-- HGest - Phase 0 lot 3 : régularisation des visites jamais clôturées
-- Idempotent, sans suppression.
--
-- 1) Crée le type de visite « Hospitalisation » (exclu de la clôture automatique)
--    et y rattache la visite 294 (patient admis le 09/10/2026, toujours hospitalisé).
-- 2) Clôture une seule fois les visites ouvertes depuis plus de 24 h, hors hospitalisation.
--    Date de fin = la plus tardive entre la fin du jour de début (23:59:59) et la
--    dernière rencontre de la visite.
--
-- Avant exécution : sauvegarde complète + export de la liste
--   (~/sauvegardes/visites_a_cloturer_AAAAMMJJ.tsv sur le serveur).
-- Retour arrière : UPDATE visit SET date_stopped = NULL
--   WHERE visit_id IN (<ids de l'export>);
-- ============================================================
SET NAMES utf8mb4;
SET @u = 1; -- admin

-- 1) Type de visite Hospitalisation
INSERT INTO visit_type (name, description, creator, date_created, retired, uuid)
SELECT 'Hospitalisation', 'Séjour hospitalier : jamais clôturé automatiquement, uniquement à la sortie du patient',
       @u, NOW(), 0, '0f7a0000-c1c0-4000-8000-0000000000c1'
 WHERE NOT EXISTS (SELECT 1 FROM visit_type WHERE uuid = '0f7a0000-c1c0-4000-8000-0000000000c1');

SET @hospit = (SELECT visit_type_id FROM visit_type WHERE uuid = '0f7a0000-c1c0-4000-8000-0000000000c1');

UPDATE visit SET visit_type_id = @hospit, changed_by = @u, date_changed = NOW()
 WHERE visit_id = 294 AND date_stopped IS NULL AND visit_type_id <> @hospit;

-- 2) Clôture des visites ouvertes depuis plus de 24 h (hors Hospitalisation)
UPDATE visit v
  LEFT JOIN (SELECT visit_id, MAX(encounter_datetime) derniere
               FROM encounter WHERE voided = 0 AND visit_id IS NOT NULL
              GROUP BY visit_id) e ON e.visit_id = v.visit_id
   SET v.date_stopped = GREATEST(TIMESTAMP(DATE(v.date_started), '23:59:59'),
                                 COALESCE(e.derniere, v.date_started)),
       v.changed_by = @u, v.date_changed = NOW()
 WHERE v.date_stopped IS NULL
   AND v.voided = 0
   AND v.visit_type_id <> @hospit
   AND v.date_started < NOW() - INTERVAL 1 DAY;
