-- ============================================================
-- Décision 1 (validée le 27/11/2026) : services au-delà du 50e et mode PayPal
--
-- Le formulaire de visite (esm-billing-app 1.3.1) ne lit que la première page
-- de /billableService. La taille par défaut est 50 et il y a 116 services,
-- donc la consultation ophtalmologique (service 112) n'apparaît pas.
-- On porte la taille par défaut et la taille maximale à 200.
--
-- Préférer l'API REST (le paramètre est relu sans redémarrage) :
--   /tmp/rest.sh POST systemsetting/webservices.rest.maxResultsDefault '{"value":"200"}'
--   /tmp/rest.sh POST systemsetting/webservices.rest.maxResultsAbsolute '{"value":"200"}'
-- Ce script SQL fait la même chose et retire PayPal. Sauvegarde préalable obligatoire.
-- ============================================================
START TRANSACTION;

UPDATE global_property SET property_value = '200'
 WHERE property IN ('webservices.rest.maxResultsDefault', 'webservices.rest.maxResultsAbsolute')
   AND CAST(property_value AS UNSIGNED) < 200;

-- PayPal n'est pas utilisé à FASSE : retiré (pas supprimé), il disparaît des listes.
UPDATE cashier_payment_mode
   SET retired = 1, retired_by = 1, date_retired = NOW(), retire_reason = 'PayPal non utilisé à FASSE'
 WHERE name = 'PayPal' AND IFNULL(retired, 0) = 0;

COMMIT;

SELECT property, property_value FROM global_property WHERE property LIKE 'webservices.rest.maxResults%';
SELECT payment_mode_id, name, retired FROM cashier_payment_mode ORDER BY payment_mode_id;
