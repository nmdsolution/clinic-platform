-- ============================================================
-- HGest - Phase 0 lot 2 : métadonnées patient adaptées au Cameroun
-- Idempotent, sans suppression : les types inutiles sont RETIRÉS (retired=1,
-- réversible), pas effacés. Vérifié avant écriture : SSN, Race, Legacy ID,
-- Old Identification Number, Health District, Health Center, Citizenship,
-- Birthplace, Mother's Name et Civil Status n'ont AUCUNE valeur saisie.
-- Conservés tels quels : demo_patient (50 patients de démo) et
-- « Unknown patient » (6 patients) - utilisés par O3.
--
-- Retour arrière : UPDATE ... SET retired=0 sur les lignes retirées ; les types
-- créés ici (uuid 0f7a0000-c1c0-4000-8000-0000000000a*) peuvent être retirés de même.
-- ============================================================
SET NAMES utf8mb4;
SET @u = 1; -- admin

-- 1) Identifiants : retirer ceux qui ne servent pas
UPDATE patient_identifier_type
   SET retired = 1, retired_by = @u, date_retired = NOW(),
       retire_reason = 'Non utilisé au Cameroun (HGest phase 0)'
 WHERE uuid IN ('a71403f3-8584-4289-ab41-2b4e5570bd45',   -- SSN
                '22348099-3873-459e-a32e-d93b17eda533',   -- Legacy ID
                '8d79403a-c2cc-11de-8d13-0010c6dffd0f')   -- Old Identification Number
   AND retired = 0;

-- CNI : l'identifiant « ID Card » devient la CNI (facultative)
UPDATE patient_identifier_type SET name = 'CNI (Carte nationale d''identité)',
       description = 'Numéro de la carte nationale d''identité (facultatif)'
 WHERE uuid = 'b4143563-16cd-4439-b288-f83d61670fc8' AND name = 'ID Card';

-- 2) Attributs de personne : retirer ceux qui ne servent pas
UPDATE person_attribute_type
   SET retired = 1, retired_by = @u, date_retired = NOW(),
       retire_reason = 'Non utilisé (HGest phase 0)'
 WHERE uuid IN ('8d871386-c2cc-11de-8d13-0010c6dffd0f',   -- Race
                '8d872150-c2cc-11de-8d13-0010c6dffd0f',   -- Health District
                '8d87236c-c2cc-11de-8d13-0010c6dffd0f')   -- Health Center
   AND retired = 0;

-- Traduction des attributs conservés
UPDATE person_attribute_type SET name = 'Lieu de naissance'     WHERE uuid = '8d8718c2-c2cc-11de-8d13-0010c6dffd0f' AND name = 'Birthplace';
UPDATE person_attribute_type SET name = 'Nationalité'           WHERE uuid = '8d871afc-c2cc-11de-8d13-0010c6dffd0f' AND name = 'Citizenship';
UPDATE person_attribute_type SET name = 'Nom de la mère'        WHERE uuid = '8d871d18-c2cc-11de-8d13-0010c6dffd0f' AND name = 'Mother''s Name';
UPDATE person_attribute_type SET name = 'Situation matrimoniale' WHERE uuid = '8d871f2a-c2cc-11de-8d13-0010c6dffd0f' AND name = 'Civil Status';
UPDATE person_attribute_type SET name = 'E-mail'                WHERE uuid = '9d861bbf-b042-11f1-8768-dae2d5843b84' AND name = 'email';

-- 3) Nouveaux attributs : profession et personne à prévenir
INSERT INTO person_attribute_type (name, description, format, searchable, creator, date_created, retired, sort_weight, uuid)
SELECT 'Profession', 'Profession du patient', 'java.lang.String', 0, @u, NOW(), 0, 20, '0f7a0000-c1c0-4000-8000-0000000000a1'
 WHERE NOT EXISTS (SELECT 1 FROM person_attribute_type WHERE uuid = '0f7a0000-c1c0-4000-8000-0000000000a1');
INSERT INTO person_attribute_type (name, description, format, searchable, creator, date_created, retired, sort_weight, uuid)
SELECT 'Personne à prévenir - nom', 'Nom de la personne à prévenir en cas de besoin', 'java.lang.String', 0, @u, NOW(), 0, 21, '0f7a0000-c1c0-4000-8000-0000000000a2'
 WHERE NOT EXISTS (SELECT 1 FROM person_attribute_type WHERE uuid = '0f7a0000-c1c0-4000-8000-0000000000a2');
INSERT INTO person_attribute_type (name, description, format, searchable, creator, date_created, retired, sort_weight, uuid)
SELECT 'Personne à prévenir - téléphone', 'Téléphone de la personne à prévenir (+237 ...)', 'java.lang.String', 0, @u, NOW(), 0, 22, '0f7a0000-c1c0-4000-8000-0000000000a3'
 WHERE NOT EXISTS (SELECT 1 FROM person_attribute_type WHERE uuid = '0f7a0000-c1c0-4000-8000-0000000000a3');
INSERT INTO person_attribute_type (name, description, format, searchable, creator, date_created, retired, sort_weight, uuid)
SELECT 'Personne à prévenir - lien', 'Lien avec le patient (époux/épouse, parent, enfant, ami...)', 'java.lang.String', 0, @u, NOW(), 0, 23, '0f7a0000-c1c0-4000-8000-0000000000a4'
 WHERE NOT EXISTS (SELECT 1 FROM person_attribute_type WHERE uuid = '0f7a0000-c1c0-4000-8000-0000000000a4');

-- 4) Libellés d'adresse en français (quartier, ville, région...) : les champs de l'adresse
--    affichent le code de message ; sans traduction connue, OpenMRS affiche le texte tel quel.
UPDATE global_property SET property_value =
  REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(property_value,
    'value="Location.address1"',     'value="Quartier"'),
    'value="Location.address2"',     'value="Point de repère"'),
    'value="Location.cityVillage"',  'value="Ville"'),
    'value="Location.stateProvince"','value="Région"'),
    'value="Location.country"',      'value="Pays"'),
    'value="Location.postalCode"',   'value="Boîte postale"')
 WHERE property = 'layout.address.format';
