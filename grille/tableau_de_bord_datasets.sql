-- ============================================================
-- TABLEAU DE BORD FASSE : datasets SQL lus par le module @face/esm-tableau-de-bord-app
-- via GET /ws/rest/v1/reportingrest/dataSet/<uuid>?startDate=...&endDate=...
-- Ce ne sont que des DataSetDefinition (aucun rapport n'apparaît dans le menu Rapports).
-- Lignes copiées du dataset « Liste des patients » (serialized_object 12) pour avoir
-- les mêmes type / subtype / serialization_class que ceux écrits par l'interface.
-- Script idempotent : une définition existante est mise à jour, pas dupliquée.
-- ============================================================
-- Usage :
-- docker exec -i clinic-platform-db-1 mysql -u openmrs -popenmrs openmrs < /opt/clinic-platform/grille/tableau_de_bord_datasets.sql

SET NAMES utf8mb4;

-- Tableau de bord - Patients
INSERT INTO serialized_object (name, description, type, subtype, serialization_class,
                               serialized_data, date_created, creator, retired, uuid)
SELECT 'Tableau de bord - Patients', 'Tous les patients (hors démonstration), avec leur UUID', type, subtype, serialization_class, '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b001" retired="false">
  <name>Tableau de bord - Patients</name>
  <description>Tous les patients (hors démonstration), avec leur UUID</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5"/>
  <sqlQuery>SELECT p.uuid AS uuid,
       pi.identifier AS dossier,
       pn.family_name AS nom,
       pn.given_name AS prenom,
       p.gender AS sexe,
       TIMESTAMPDIFF(YEAR, p.birthdate, CURDATE()) AS age,
       tel.value AS telephone,
       DATE_FORMAT(pt.date_created, &apos;%Y-%m-%d&apos;) AS enregistre,
       (SELECT DATE_FORMAT(MAX(v.date_started), &apos;%Y-%m-%d&apos;) FROM visit v
         WHERE v.patient_id = pt.patient_id AND v.voided = 0) AS derniere_visite
FROM patient pt
JOIN person p ON p.person_id = pt.patient_id AND p.voided = 0
LEFT JOIN person_name pn ON pn.person_id = p.person_id AND pn.preferred = 1 AND pn.voided = 0
LEFT JOIN patient_identifier pi ON pi.patient_id = pt.patient_id AND pi.preferred = 1 AND pi.voided = 0
LEFT JOIN person_attribute tel ON tel.person_id = p.person_id AND tel.voided = 0
     AND tel.person_attribute_type_id = (SELECT person_attribute_type_id FROM person_attribute_type
                                         WHERE name = &apos;Téléphone&apos; LIMIT 1)
WHERE pt.voided = 0
  AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = p.person_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)
ORDER BY pn.family_name, pn.given_name</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', NOW(), creator, 0, '0f7a0000-c1c0-4000-8000-00000000b001'
FROM serialized_object
WHERE serialized_object_id = 12
  AND NOT EXISTS (SELECT 1 FROM serialized_object WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b001');
UPDATE serialized_object SET serialized_data = '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b001" retired="false">
  <name>Tableau de bord - Patients</name>
  <description>Tous les patients (hors démonstration), avec leur UUID</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5"/>
  <sqlQuery>SELECT p.uuid AS uuid,
       pi.identifier AS dossier,
       pn.family_name AS nom,
       pn.given_name AS prenom,
       p.gender AS sexe,
       TIMESTAMPDIFF(YEAR, p.birthdate, CURDATE()) AS age,
       tel.value AS telephone,
       DATE_FORMAT(pt.date_created, &apos;%Y-%m-%d&apos;) AS enregistre,
       (SELECT DATE_FORMAT(MAX(v.date_started), &apos;%Y-%m-%d&apos;) FROM visit v
         WHERE v.patient_id = pt.patient_id AND v.voided = 0) AS derniere_visite
FROM patient pt
JOIN person p ON p.person_id = pt.patient_id AND p.voided = 0
LEFT JOIN person_name pn ON pn.person_id = p.person_id AND pn.preferred = 1 AND pn.voided = 0
LEFT JOIN patient_identifier pi ON pi.patient_id = pt.patient_id AND pi.preferred = 1 AND pi.voided = 0
LEFT JOIN person_attribute tel ON tel.person_id = p.person_id AND tel.voided = 0
     AND tel.person_attribute_type_id = (SELECT person_attribute_type_id FROM person_attribute_type
                                         WHERE name = &apos;Téléphone&apos; LIMIT 1)
WHERE pt.voided = 0
  AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = p.person_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)
ORDER BY pn.family_name, pn.given_name</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', date_changed = NOW()
WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b001';

-- Tableau de bord - Consultations par jour
INSERT INTO serialized_object (name, description, type, subtype, serialization_class,
                               serialized_data, date_created, creator, retired, uuid)
SELECT 'Tableau de bord - Consultations par jour', 'Nombre de visites par jour sur une période', type, subtype, serialization_class, '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b002" retired="false">
  <name>Tableau de bord - Consultations par jour</name>
  <description>Nombre de visites par jour sur une période</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5">
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>startDate</name><label>Date début</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>endDate</name><label>Date fin</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
  </parameters>
  <sqlQuery>SELECT DATE_FORMAT(v.date_started, &apos;%Y-%m-%d&apos;) AS jour,
       COUNT(*) AS visites,
       COUNT(DISTINCT v.patient_id) AS patients
FROM visit v
JOIN patient pt ON pt.patient_id = v.patient_id AND pt.voided = 0
WHERE v.voided = 0
  AND v.date_started &gt;= DATE(:startDate)
  AND v.date_started &lt; DATE(:endDate) + INTERVAL 1 DAY
  AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = v.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)
GROUP BY DATE_FORMAT(v.date_started, &apos;%Y-%m-%d&apos;)
ORDER BY jour</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', NOW(), creator, 0, '0f7a0000-c1c0-4000-8000-00000000b002'
FROM serialized_object
WHERE serialized_object_id = 12
  AND NOT EXISTS (SELECT 1 FROM serialized_object WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b002');
UPDATE serialized_object SET serialized_data = '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b002" retired="false">
  <name>Tableau de bord - Consultations par jour</name>
  <description>Nombre de visites par jour sur une période</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5">
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>startDate</name><label>Date début</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>endDate</name><label>Date fin</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
  </parameters>
  <sqlQuery>SELECT DATE_FORMAT(v.date_started, &apos;%Y-%m-%d&apos;) AS jour,
       COUNT(*) AS visites,
       COUNT(DISTINCT v.patient_id) AS patients
FROM visit v
JOIN patient pt ON pt.patient_id = v.patient_id AND pt.voided = 0
WHERE v.voided = 0
  AND v.date_started &gt;= DATE(:startDate)
  AND v.date_started &lt; DATE(:endDate) + INTERVAL 1 DAY
  AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = v.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)
GROUP BY DATE_FORMAT(v.date_started, &apos;%Y-%m-%d&apos;)
ORDER BY jour</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', date_changed = NOW()
WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b002';

-- Tableau de bord - Consultations détail
INSERT INTO serialized_object (name, description, type, subtype, serialization_class,
                               serialized_data, date_created, creator, retired, uuid)
SELECT 'Tableau de bord - Consultations détail', 'Visites d''une période, avec UUID patient', type, subtype, serialization_class, '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b003" retired="false">
  <name>Tableau de bord - Consultations détail</name>
  <description>Visites d''une période, avec UUID patient</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5">
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>startDate</name><label>Date début</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>endDate</name><label>Date fin</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
  </parameters>
  <sqlQuery>SELECT p.uuid AS uuid,
       TIME_FORMAT(v.date_started, &apos;%H:%i&apos;) AS heure,
       pi.identifier AS dossier,
       CONCAT(pn.family_name, &apos; &apos;, pn.given_name) AS patient,
       p.gender AS sexe,
       TIMESTAMPDIFF(YEAR, p.birthdate, v.date_started) AS age,
       vt.name AS type_visite,
       (SELECT GROUP_CONCAT(DISTINCT et.name ORDER BY et.name SEPARATOR &apos;, &apos;)
          FROM encounter e JOIN encounter_type et ON et.encounter_type_id = e.encounter_type
         WHERE e.visit_id = v.visit_id AND e.voided = 0) AS actes,
       (SELECT GROUP_CONCAT(DISTINCT CONCAT(prn.given_name, &apos; &apos;, prn.family_name) SEPARATOR &apos;, &apos;)
          FROM encounter e
          JOIN encounter_provider ep ON ep.encounter_id = e.encounter_id AND ep.voided = 0
          JOIN provider pr ON pr.provider_id = ep.provider_id
          JOIN person_name prn ON prn.person_id = pr.person_id AND prn.preferred = 1 AND prn.voided = 0
         WHERE e.visit_id = v.visit_id AND e.voided = 0) AS soignants
FROM visit v
JOIN patient pt ON pt.patient_id = v.patient_id AND pt.voided = 0
JOIN person p ON p.person_id = pt.patient_id
JOIN visit_type vt ON vt.visit_type_id = v.visit_type_id
LEFT JOIN person_name pn ON pn.person_id = p.person_id AND pn.preferred = 1 AND pn.voided = 0
LEFT JOIN patient_identifier pi ON pi.patient_id = pt.patient_id AND pi.preferred = 1 AND pi.voided = 0
WHERE v.voided = 0
  AND v.date_started &gt;= DATE(:startDate)
  AND v.date_started &lt; DATE(:endDate) + INTERVAL 1 DAY
  AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = v.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)
ORDER BY v.date_started</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', NOW(), creator, 0, '0f7a0000-c1c0-4000-8000-00000000b003'
FROM serialized_object
WHERE serialized_object_id = 12
  AND NOT EXISTS (SELECT 1 FROM serialized_object WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b003');
UPDATE serialized_object SET serialized_data = '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b003" retired="false">
  <name>Tableau de bord - Consultations détail</name>
  <description>Visites d''une période, avec UUID patient</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5">
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>startDate</name><label>Date début</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>endDate</name><label>Date fin</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
  </parameters>
  <sqlQuery>SELECT p.uuid AS uuid,
       TIME_FORMAT(v.date_started, &apos;%H:%i&apos;) AS heure,
       pi.identifier AS dossier,
       CONCAT(pn.family_name, &apos; &apos;, pn.given_name) AS patient,
       p.gender AS sexe,
       TIMESTAMPDIFF(YEAR, p.birthdate, v.date_started) AS age,
       vt.name AS type_visite,
       (SELECT GROUP_CONCAT(DISTINCT et.name ORDER BY et.name SEPARATOR &apos;, &apos;)
          FROM encounter e JOIN encounter_type et ON et.encounter_type_id = e.encounter_type
         WHERE e.visit_id = v.visit_id AND e.voided = 0) AS actes,
       (SELECT GROUP_CONCAT(DISTINCT CONCAT(prn.given_name, &apos; &apos;, prn.family_name) SEPARATOR &apos;, &apos;)
          FROM encounter e
          JOIN encounter_provider ep ON ep.encounter_id = e.encounter_id AND ep.voided = 0
          JOIN provider pr ON pr.provider_id = ep.provider_id
          JOIN person_name prn ON prn.person_id = pr.person_id AND prn.preferred = 1 AND prn.voided = 0
         WHERE e.visit_id = v.visit_id AND e.voided = 0) AS soignants
FROM visit v
JOIN patient pt ON pt.patient_id = v.patient_id AND pt.voided = 0
JOIN person p ON p.person_id = pt.patient_id
JOIN visit_type vt ON vt.visit_type_id = v.visit_type_id
LEFT JOIN person_name pn ON pn.person_id = p.person_id AND pn.preferred = 1 AND pn.voided = 0
LEFT JOIN patient_identifier pi ON pi.patient_id = pt.patient_id AND pi.preferred = 1 AND pi.voided = 0
WHERE v.voided = 0
  AND v.date_started &gt;= DATE(:startDate)
  AND v.date_started &lt; DATE(:endDate) + INTERVAL 1 DAY
  AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = v.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)
ORDER BY v.date_started</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', date_changed = NOW()
WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b003';

-- Tableau de bord - Recettes par jour
INSERT INTO serialized_object (name, description, type, subtype, serialization_class,
                               serialized_data, date_created, creator, retired, uuid)
SELECT 'Tableau de bord - Recettes par jour', 'Montants facturés et encaissés par jour', type, subtype, serialization_class, '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b004" retired="false">
  <name>Tableau de bord - Recettes par jour</name>
  <description>Montants facturés et encaissés par jour</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5">
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>startDate</name><label>Date début</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>endDate</name><label>Date fin</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
  </parameters>
  <sqlQuery>SELECT jour,
       SUM(factures) AS factures,
       SUM(facture) AS montant_facture,
       SUM(encaisse) AS montant_encaisse
FROM (
  SELECT DATE_FORMAT(b.date_created, &apos;%Y-%m-%d&apos;) AS jour,
         COUNT(DISTINCT b.bill_id) AS factures,
         SUM(li.price * li.quantity) AS facture,
         0 AS encaisse
  FROM cashier_bill b
  JOIN cashier_bill_line_item li ON li.bill_id = b.bill_id AND li.voided = 0
  WHERE b.voided = 0
    AND b.date_created &gt;= DATE(:startDate) AND b.date_created &lt; DATE(:endDate) + INTERVAL 1 DAY
    AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)
  GROUP BY DATE_FORMAT(b.date_created, &apos;%Y-%m-%d&apos;)
  UNION ALL
  SELECT DATE_FORMAT(bp.date_created, &apos;%Y-%m-%d&apos;), 0, 0, SUM(bp.amount)
  FROM cashier_bill_payment bp
  JOIN cashier_bill b ON b.bill_id = bp.bill_id AND b.voided = 0
  WHERE bp.voided = 0
    AND bp.date_created &gt;= DATE(:startDate) AND bp.date_created &lt; DATE(:endDate) + INTERVAL 1 DAY
    AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)
  GROUP BY DATE_FORMAT(bp.date_created, &apos;%Y-%m-%d&apos;)
) x
GROUP BY jour
ORDER BY jour</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', NOW(), creator, 0, '0f7a0000-c1c0-4000-8000-00000000b004'
FROM serialized_object
WHERE serialized_object_id = 12
  AND NOT EXISTS (SELECT 1 FROM serialized_object WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b004');
UPDATE serialized_object SET serialized_data = '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b004" retired="false">
  <name>Tableau de bord - Recettes par jour</name>
  <description>Montants facturés et encaissés par jour</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5">
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>startDate</name><label>Date début</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>endDate</name><label>Date fin</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
  </parameters>
  <sqlQuery>SELECT jour,
       SUM(factures) AS factures,
       SUM(facture) AS montant_facture,
       SUM(encaisse) AS montant_encaisse
FROM (
  SELECT DATE_FORMAT(b.date_created, &apos;%Y-%m-%d&apos;) AS jour,
         COUNT(DISTINCT b.bill_id) AS factures,
         SUM(li.price * li.quantity) AS facture,
         0 AS encaisse
  FROM cashier_bill b
  JOIN cashier_bill_line_item li ON li.bill_id = b.bill_id AND li.voided = 0
  WHERE b.voided = 0
    AND b.date_created &gt;= DATE(:startDate) AND b.date_created &lt; DATE(:endDate) + INTERVAL 1 DAY
    AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)
  GROUP BY DATE_FORMAT(b.date_created, &apos;%Y-%m-%d&apos;)
  UNION ALL
  SELECT DATE_FORMAT(bp.date_created, &apos;%Y-%m-%d&apos;), 0, 0, SUM(bp.amount)
  FROM cashier_bill_payment bp
  JOIN cashier_bill b ON b.bill_id = bp.bill_id AND b.voided = 0
  WHERE bp.voided = 0
    AND bp.date_created &gt;= DATE(:startDate) AND bp.date_created &lt; DATE(:endDate) + INTERVAL 1 DAY
    AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)
  GROUP BY DATE_FORMAT(bp.date_created, &apos;%Y-%m-%d&apos;)
) x
GROUP BY jour
ORDER BY jour</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', date_changed = NOW()
WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b004';

-- Tableau de bord - Factures détail
INSERT INTO serialized_object (name, description, type, subtype, serialization_class,
                               serialized_data, date_created, creator, retired, uuid)
SELECT 'Tableau de bord - Factures détail', 'Factures d''une période avec total et montant payé', type, subtype, serialization_class, '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b005" retired="false">
  <name>Tableau de bord - Factures détail</name>
  <description>Factures d''une période avec total et montant payé</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5">
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>startDate</name><label>Date début</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>endDate</name><label>Date fin</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
  </parameters>
  <sqlQuery>SELECT b.receipt_number AS facture,
       p.uuid AS uuid,
       CONCAT(pn.family_name, &apos; &apos;, pn.given_name) AS patient,
       TIME_FORMAT(b.date_created, &apos;%H:%i&apos;) AS heure,
       b.status AS statut,
       (SELECT COALESCE(SUM(li.price * li.quantity), 0) FROM cashier_bill_line_item li
         WHERE li.bill_id = b.bill_id AND li.voided = 0) AS total,
       (SELECT COALESCE(SUM(bp.amount), 0) FROM cashier_bill_payment bp
         WHERE bp.bill_id = b.bill_id AND bp.voided = 0) AS paye
FROM cashier_bill b
JOIN person p ON p.person_id = b.patient_id
LEFT JOIN person_name pn ON pn.person_id = p.person_id AND pn.preferred = 1 AND pn.voided = 0
WHERE b.voided = 0
  AND b.date_created &gt;= DATE(:startDate) AND b.date_created &lt; DATE(:endDate) + INTERVAL 1 DAY
  AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)
ORDER BY b.date_created</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', NOW(), creator, 0, '0f7a0000-c1c0-4000-8000-00000000b005'
FROM serialized_object
WHERE serialized_object_id = 12
  AND NOT EXISTS (SELECT 1 FROM serialized_object WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b005');
UPDATE serialized_object SET serialized_data = '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b005" retired="false">
  <name>Tableau de bord - Factures détail</name>
  <description>Factures d''une période avec total et montant payé</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5">
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>startDate</name><label>Date début</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>endDate</name><label>Date fin</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
  </parameters>
  <sqlQuery>SELECT b.receipt_number AS facture,
       p.uuid AS uuid,
       CONCAT(pn.family_name, &apos; &apos;, pn.given_name) AS patient,
       TIME_FORMAT(b.date_created, &apos;%H:%i&apos;) AS heure,
       b.status AS statut,
       (SELECT COALESCE(SUM(li.price * li.quantity), 0) FROM cashier_bill_line_item li
         WHERE li.bill_id = b.bill_id AND li.voided = 0) AS total,
       (SELECT COALESCE(SUM(bp.amount), 0) FROM cashier_bill_payment bp
         WHERE bp.bill_id = b.bill_id AND bp.voided = 0) AS paye
FROM cashier_bill b
JOIN person p ON p.person_id = b.patient_id
LEFT JOIN person_name pn ON pn.person_id = p.person_id AND pn.preferred = 1 AND pn.voided = 0
WHERE b.voided = 0
  AND b.date_created &gt;= DATE(:startDate) AND b.date_created &lt; DATE(:endDate) + INTERVAL 1 DAY
  AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)
ORDER BY b.date_created</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', date_changed = NOW()
WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b005';

-- Tableau de bord - Stock
INSERT INTO serialized_object (name, description, type, subtype, serialization_class,
                               serialized_data, date_created, creator, retired, uuid)
SELECT 'Tableau de bord - Stock', 'Stock par magasin, article et lot', type, subtype, serialization_class, '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b006" retired="false">
  <name>Tableau de bord - Stock</name>
  <description>Stock par magasin, article et lot</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5"/>
  <sqlQuery>SELECT loc.name AS magasin,
       COALESCE(d.name, si.common_name) AS article,
       sb.batch_no AS lot,
       DATE_FORMAT(sb.expiration, &apos;%Y-%m-%d&apos;) AS peremption,
       SUM(t.quantity) AS quantite,
       MAX(ucn.name) AS unite,
       si.reorder_level AS seuil,
       CASE WHEN SUM(t.quantity) &lt;= 0 THEN &apos;Rupture&apos;
            WHEN sb.expiration IS NOT NULL AND sb.expiration &lt; CURDATE() THEN &apos;Périmé&apos;
            WHEN sb.expiration IS NOT NULL AND sb.expiration &lt; CURDATE() + INTERVAL 90 DAY THEN &apos;Périme sous 90 jours&apos;
            WHEN si.reorder_level IS NOT NULL AND SUM(t.quantity) &lt;= si.reorder_level THEN &apos;Sous le seuil&apos;
            ELSE &apos;OK&apos; END AS etat
FROM stockmgmt_stock_item_transaction t
JOIN stockmgmt_stock_item si ON si.stock_item_id = t.stock_item_id AND si.voided = 0
JOIN stockmgmt_party pa ON pa.party_id = t.party_id
JOIN location loc ON loc.location_id = pa.location_id
LEFT JOIN drug d ON d.drug_id = si.drug_id
LEFT JOIN stockmgmt_stock_batch sb ON sb.stock_batch_id = t.stock_batch_id
LEFT JOIN stockmgmt_stock_item_packaging_uom u ON u.stock_item_packaging_uom_id = t.stock_item_packaging_uom_id
LEFT JOIN concept_name ucn ON ucn.concept_id = u.packaging_uom_id AND ucn.locale_preferred = 1 AND ucn.voided = 0
GROUP BY loc.location_id, si.stock_item_id, sb.stock_batch_id
ORDER BY magasin, article, peremption</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', NOW(), creator, 0, '0f7a0000-c1c0-4000-8000-00000000b006'
FROM serialized_object
WHERE serialized_object_id = 12
  AND NOT EXISTS (SELECT 1 FROM serialized_object WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b006');
UPDATE serialized_object SET serialized_data = '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b006" retired="false">
  <name>Tableau de bord - Stock</name>
  <description>Stock par magasin, article et lot</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5"/>
  <sqlQuery>SELECT loc.name AS magasin,
       COALESCE(d.name, si.common_name) AS article,
       sb.batch_no AS lot,
       DATE_FORMAT(sb.expiration, &apos;%Y-%m-%d&apos;) AS peremption,
       SUM(t.quantity) AS quantite,
       MAX(ucn.name) AS unite,
       si.reorder_level AS seuil,
       CASE WHEN SUM(t.quantity) &lt;= 0 THEN &apos;Rupture&apos;
            WHEN sb.expiration IS NOT NULL AND sb.expiration &lt; CURDATE() THEN &apos;Périmé&apos;
            WHEN sb.expiration IS NOT NULL AND sb.expiration &lt; CURDATE() + INTERVAL 90 DAY THEN &apos;Périme sous 90 jours&apos;
            WHEN si.reorder_level IS NOT NULL AND SUM(t.quantity) &lt;= si.reorder_level THEN &apos;Sous le seuil&apos;
            ELSE &apos;OK&apos; END AS etat
FROM stockmgmt_stock_item_transaction t
JOIN stockmgmt_stock_item si ON si.stock_item_id = t.stock_item_id AND si.voided = 0
JOIN stockmgmt_party pa ON pa.party_id = t.party_id
JOIN location loc ON loc.location_id = pa.location_id
LEFT JOIN drug d ON d.drug_id = si.drug_id
LEFT JOIN stockmgmt_stock_batch sb ON sb.stock_batch_id = t.stock_batch_id
LEFT JOIN stockmgmt_stock_item_packaging_uom u ON u.stock_item_packaging_uom_id = t.stock_item_packaging_uom_id
LEFT JOIN concept_name ucn ON ucn.concept_id = u.packaging_uom_id AND ucn.locale_preferred = 1 AND ucn.voided = 0
GROUP BY loc.location_id, si.stock_item_id, sb.stock_batch_id
ORDER BY magasin, article, peremption</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', date_changed = NOW()
WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b006';

-- Tableau de bord - Magasins
INSERT INTO serialized_object (name, description, type, subtype, serialization_class,
                               serialized_data, date_created, creator, retired, uuid)
SELECT 'Tableau de bord - Magasins', 'Lieux de stockage (tags Main Store / Main Pharmacy)', type, subtype, serialization_class, '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b007" retired="false">
  <name>Tableau de bord - Magasins</name>
  <description>Lieux de stockage (tags Main Store / Main Pharmacy)</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5"/>
  <sqlQuery>SELECT DISTINCT l.name AS magasin
FROM location l
JOIN location_tag_map m ON m.location_id = l.location_id
JOIN location_tag lt ON lt.location_tag_id = m.location_tag_id
WHERE l.retired = 0 AND lt.name IN (&apos;Main Store&apos;, &apos;Main Pharmacy&apos;)
ORDER BY magasin</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', NOW(), creator, 0, '0f7a0000-c1c0-4000-8000-00000000b007'
FROM serialized_object
WHERE serialized_object_id = 12
  AND NOT EXISTS (SELECT 1 FROM serialized_object WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b007');
UPDATE serialized_object SET serialized_data = '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b007" retired="false">
  <name>Tableau de bord - Magasins</name>
  <description>Lieux de stockage (tags Main Store / Main Pharmacy)</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5"/>
  <sqlQuery>SELECT DISTINCT l.name AS magasin
FROM location l
JOIN location_tag_map m ON m.location_id = l.location_id
JOIN location_tag lt ON lt.location_tag_id = m.location_tag_id
WHERE l.retired = 0 AND lt.name IN (&apos;Main Store&apos;, &apos;Main Pharmacy&apos;)
ORDER BY magasin</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', date_changed = NOW()
WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b007';

-- Tableau de bord - Indicateurs du jour
INSERT INTO serialized_object (name, description, type, subtype, serialization_class,
                               serialized_data, date_created, creator, retired, uuid)
SELECT 'Tableau de bord - Indicateurs du jour', 'Chiffres du jour pour l''écran Parcours patient', type, subtype, serialization_class, '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b008" retired="false">
  <name>Tableau de bord - Indicateurs du jour</name>
  <description>Chiffres du jour pour l''écran Parcours patient</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5"/>
  <sqlQuery>SELECT
  (SELECT COUNT(*) FROM patient pt WHERE pt.voided = 0 AND pt.date_created &gt;= CURDATE()
      AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = pt.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)) AS patients_jour,
  (SELECT COUNT(*) FROM visit v WHERE v.voided = 0 AND v.date_started &gt;= CURDATE()
      AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = v.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)) AS visites_jour,
  (SELECT COUNT(*) FROM visit v WHERE v.voided = 0 AND v.date_stopped IS NULL
      AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = v.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)) AS visites_ouvertes,
  (SELECT COUNT(*) FROM cashier_bill b WHERE b.voided = 0 AND b.date_created &gt;= CURDATE()
      AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)) AS factures_jour,
  (SELECT COALESCE(SUM(bp.amount), 0) FROM cashier_bill_payment bp
     JOIN cashier_bill b ON b.bill_id = bp.bill_id AND b.voided = 0
    WHERE bp.voided = 0 AND bp.date_created &gt;= CURDATE()
      AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)) AS encaisse_jour,
  (SELECT COUNT(*) FROM cashier_bill b WHERE b.voided = 0 AND (SELECT COALESCE(SUM(li.price * li.quantity), 0) FROM cashier_bill_line_item li WHERE li.bill_id = b.bill_id AND li.voided = 0) &gt; (SELECT COALESCE(SUM(bp.amount), 0) FROM cashier_bill_payment bp WHERE bp.bill_id = b.bill_id AND bp.voided = 0)
      AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)) AS impayes_nb,
  (SELECT COALESCE(SUM((SELECT COALESCE(SUM(li.price * li.quantity), 0) FROM cashier_bill_line_item li WHERE li.bill_id = b.bill_id AND li.voided = 0) - (SELECT COALESCE(SUM(bp.amount), 0) FROM cashier_bill_payment bp WHERE bp.bill_id = b.bill_id AND bp.voided = 0)), 0) FROM cashier_bill b
    WHERE b.voided = 0 AND (SELECT COALESCE(SUM(li.price * li.quantity), 0) FROM cashier_bill_line_item li WHERE li.bill_id = b.bill_id AND li.voided = 0) &gt; (SELECT COALESCE(SUM(bp.amount), 0) FROM cashier_bill_payment bp WHERE bp.bill_id = b.bill_id AND bp.voided = 0)
      AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)) AS impayes_montant,
  (SELECT COUNT(*) FROM orders o JOIN order_type ot ON ot.order_type_id = o.order_type_id
    WHERE o.voided = 0 AND ot.name = &apos;Test Order&apos; AND o.date_stopped IS NULL
      AND o.fulfiller_status IS NULL AND o.date_activated &gt;= CURDATE() - INTERVAL 7 DAY
      AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = o.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)) AS examens_en_attente</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', NOW(), creator, 0, '0f7a0000-c1c0-4000-8000-00000000b008'
FROM serialized_object
WHERE serialized_object_id = 12
  AND NOT EXISTS (SELECT 1 FROM serialized_object WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b008');
UPDATE serialized_object SET serialized_data = '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b008" retired="false">
  <name>Tableau de bord - Indicateurs du jour</name>
  <description>Chiffres du jour pour l''écran Parcours patient</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5"/>
  <sqlQuery>SELECT
  (SELECT COUNT(*) FROM patient pt WHERE pt.voided = 0 AND pt.date_created &gt;= CURDATE()
      AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = pt.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)) AS patients_jour,
  (SELECT COUNT(*) FROM visit v WHERE v.voided = 0 AND v.date_started &gt;= CURDATE()
      AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = v.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)) AS visites_jour,
  (SELECT COUNT(*) FROM visit v WHERE v.voided = 0 AND v.date_stopped IS NULL
      AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = v.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)) AS visites_ouvertes,
  (SELECT COUNT(*) FROM cashier_bill b WHERE b.voided = 0 AND b.date_created &gt;= CURDATE()
      AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)) AS factures_jour,
  (SELECT COALESCE(SUM(bp.amount), 0) FROM cashier_bill_payment bp
     JOIN cashier_bill b ON b.bill_id = bp.bill_id AND b.voided = 0
    WHERE bp.voided = 0 AND bp.date_created &gt;= CURDATE()
      AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)) AS encaisse_jour,
  (SELECT COUNT(*) FROM cashier_bill b WHERE b.voided = 0 AND (SELECT COALESCE(SUM(li.price * li.quantity), 0) FROM cashier_bill_line_item li WHERE li.bill_id = b.bill_id AND li.voided = 0) &gt; (SELECT COALESCE(SUM(bp.amount), 0) FROM cashier_bill_payment bp WHERE bp.bill_id = b.bill_id AND bp.voided = 0)
      AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)) AS impayes_nb,
  (SELECT COALESCE(SUM((SELECT COALESCE(SUM(li.price * li.quantity), 0) FROM cashier_bill_line_item li WHERE li.bill_id = b.bill_id AND li.voided = 0) - (SELECT COALESCE(SUM(bp.amount), 0) FROM cashier_bill_payment bp WHERE bp.bill_id = b.bill_id AND bp.voided = 0)), 0) FROM cashier_bill b
    WHERE b.voided = 0 AND (SELECT COALESCE(SUM(li.price * li.quantity), 0) FROM cashier_bill_line_item li WHERE li.bill_id = b.bill_id AND li.voided = 0) &gt; (SELECT COALESCE(SUM(bp.amount), 0) FROM cashier_bill_payment bp WHERE bp.bill_id = b.bill_id AND bp.voided = 0)
      AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)) AS impayes_montant,
  (SELECT COUNT(*) FROM orders o JOIN order_type ot ON ot.order_type_id = o.order_type_id
    WHERE o.voided = 0 AND ot.name = &apos;Test Order&apos; AND o.date_stopped IS NULL
      AND o.fulfiller_status IS NULL AND o.date_activated &gt;= CURDATE() - INTERVAL 7 DAY
      AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = o.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)) AS examens_en_attente</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', date_changed = NOW()
WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b008';

-- Tableau de bord - Médicaments
INSERT INTO serialized_object (name, description, type, subtype, serialization_class,
                               serialized_data, date_created, creator, retired, uuid)
SELECT 'Tableau de bord - Médicaments', 'Médicaments prescriptibles avec leur stock', type, subtype, serialization_class, '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b009" retired="false">
  <name>Tableau de bord - Médicaments</name>
  <description>Médicaments prescriptibles avec leur stock</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5"/>
  <sqlQuery>SELECT d.name AS medicament,
       d.strength AS dosage,
       (SELECT fcn.name FROM concept_name fcn
         WHERE fcn.concept_id = d.dosage_form AND fcn.voided = 0 AND fcn.locale_preferred = 1
         ORDER BY fcn.locale = &apos;fr&apos; DESC, fcn.locale = &apos;en&apos; DESC LIMIT 1) AS forme,
       COALESCE(st.quantite, 0) AS quantite,
       CASE WHEN st.stock_item_id IS NULL THEN &apos;Non suivi en stock&apos;
            WHEN st.quantite &lt;= 0 THEN &apos;Rupture&apos;
            ELSE &apos;En stock&apos; END AS etat
FROM drug d
LEFT JOIN (SELECT si.drug_id, MIN(si.stock_item_id) AS stock_item_id, COALESCE(SUM(t.quantity), 0) AS quantite
             FROM stockmgmt_stock_item si
             LEFT JOIN stockmgmt_stock_item_transaction t ON t.stock_item_id = si.stock_item_id
            WHERE si.voided = 0 AND si.drug_id IS NOT NULL
            GROUP BY si.drug_id) st ON st.drug_id = d.drug_id
WHERE d.retired = 0
ORDER BY d.name</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', NOW(), creator, 0, '0f7a0000-c1c0-4000-8000-00000000b009'
FROM serialized_object
WHERE serialized_object_id = 12
  AND NOT EXISTS (SELECT 1 FROM serialized_object WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b009');
UPDATE serialized_object SET serialized_data = '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b009" retired="false">
  <name>Tableau de bord - Médicaments</name>
  <description>Médicaments prescriptibles avec leur stock</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5"/>
  <sqlQuery>SELECT d.name AS medicament,
       d.strength AS dosage,
       (SELECT fcn.name FROM concept_name fcn
         WHERE fcn.concept_id = d.dosage_form AND fcn.voided = 0 AND fcn.locale_preferred = 1
         ORDER BY fcn.locale = &apos;fr&apos; DESC, fcn.locale = &apos;en&apos; DESC LIMIT 1) AS forme,
       COALESCE(st.quantite, 0) AS quantite,
       CASE WHEN st.stock_item_id IS NULL THEN &apos;Non suivi en stock&apos;
            WHEN st.quantite &lt;= 0 THEN &apos;Rupture&apos;
            ELSE &apos;En stock&apos; END AS etat
FROM drug d
LEFT JOIN (SELECT si.drug_id, MIN(si.stock_item_id) AS stock_item_id, COALESCE(SUM(t.quantity), 0) AS quantite
             FROM stockmgmt_stock_item si
             LEFT JOIN stockmgmt_stock_item_transaction t ON t.stock_item_id = si.stock_item_id
            WHERE si.voided = 0 AND si.drug_id IS NOT NULL
            GROUP BY si.drug_id) st ON st.drug_id = d.drug_id
WHERE d.retired = 0
ORDER BY d.name</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', date_changed = NOW()
WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b009';

-- Tableau de bord - Tarifs
INSERT INTO serialized_object (name, description, type, subtype, serialization_class,
                               serialized_data, date_created, creator, retired, uuid)
SELECT 'Tableau de bord - Tarifs', 'Actes facturables et leurs prix', type, subtype, serialization_class, '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b010" retired="false">
  <name>Tableau de bord - Tarifs</name>
  <description>Actes facturables et leurs prix</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5"/>
  <sqlQuery>SELECT s.name AS acte,
       s.short_name AS code,
       ip.name AS tarif,
       ip.price AS prix
FROM cashier_billable_service s
JOIN cashier_item_price ip ON ip.service_id = s.service_id AND ip.retired = 0
WHERE s.retired = 0
ORDER BY s.name, ip.price</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', NOW(), creator, 0, '0f7a0000-c1c0-4000-8000-00000000b010'
FROM serialized_object
WHERE serialized_object_id = 12
  AND NOT EXISTS (SELECT 1 FROM serialized_object WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b010');
UPDATE serialized_object SET serialized_data = '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b010" retired="false">
  <name>Tableau de bord - Tarifs</name>
  <description>Actes facturables et leurs prix</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5"/>
  <sqlQuery>SELECT s.name AS acte,
       s.short_name AS code,
       ip.name AS tarif,
       ip.price AS prix
FROM cashier_billable_service s
JOIN cashier_item_price ip ON ip.service_id = s.service_id AND ip.retired = 0
WHERE s.retired = 0
ORDER BY s.name, ip.price</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', date_changed = NOW()
WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b010';

-- Tableau de bord - Impayés
INSERT INTO serialized_object (name, description, type, subtype, serialization_class,
                               serialized_data, date_created, creator, retired, uuid)
SELECT 'Tableau de bord - Impayés', 'Factures non soldées, avec le reste à payer', type, subtype, serialization_class, '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b011" retired="false">
  <name>Tableau de bord - Impayés</name>
  <description>Factures non soldées, avec le reste à payer</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5"/>
  <sqlQuery>SELECT p.uuid AS uuid,
       b.receipt_number AS facture,
       DATE_FORMAT(b.date_created, &apos;%Y-%m-%d&apos;) AS date_facture,
       DATEDIFF(CURDATE(), b.date_created) AS jours,
       pi.identifier AS dossier,
       CONCAT(pn.family_name, &apos; &apos;, pn.given_name) AS patient,
       tel.value AS telephone,
       (SELECT COALESCE(SUM(li.price * li.quantity), 0) FROM cashier_bill_line_item li WHERE li.bill_id = b.bill_id AND li.voided = 0) AS total,
       (SELECT COALESCE(SUM(bp.amount), 0) FROM cashier_bill_payment bp WHERE bp.bill_id = b.bill_id AND bp.voided = 0) AS paye,
       (SELECT COALESCE(SUM(li.price * li.quantity), 0) FROM cashier_bill_line_item li WHERE li.bill_id = b.bill_id AND li.voided = 0) - (SELECT COALESCE(SUM(bp.amount), 0) FROM cashier_bill_payment bp WHERE bp.bill_id = b.bill_id AND bp.voided = 0) AS reste
FROM cashier_bill b
JOIN person p ON p.person_id = b.patient_id
LEFT JOIN person_name pn ON pn.person_id = p.person_id AND pn.preferred = 1 AND pn.voided = 0
LEFT JOIN patient_identifier pi ON pi.patient_id = b.patient_id AND pi.preferred = 1 AND pi.voided = 0
LEFT JOIN person_attribute tel ON tel.person_id = p.person_id AND tel.voided = 0
     AND tel.person_attribute_type_id = (SELECT person_attribute_type_id FROM person_attribute_type
                                         WHERE name = &apos;Téléphone&apos; LIMIT 1)
WHERE b.voided = 0
  AND (SELECT COALESCE(SUM(li.price * li.quantity), 0) FROM cashier_bill_line_item li WHERE li.bill_id = b.bill_id AND li.voided = 0) &gt; (SELECT COALESCE(SUM(bp.amount), 0) FROM cashier_bill_payment bp WHERE bp.bill_id = b.bill_id AND bp.voided = 0)
  AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)
ORDER BY b.date_created</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', NOW(), creator, 0, '0f7a0000-c1c0-4000-8000-00000000b011'
FROM serialized_object
WHERE serialized_object_id = 12
  AND NOT EXISTS (SELECT 1 FROM serialized_object WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b011');
UPDATE serialized_object SET serialized_data = '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b011" retired="false">
  <name>Tableau de bord - Impayés</name>
  <description>Factures non soldées, avec le reste à payer</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5"/>
  <sqlQuery>SELECT p.uuid AS uuid,
       b.receipt_number AS facture,
       DATE_FORMAT(b.date_created, &apos;%Y-%m-%d&apos;) AS date_facture,
       DATEDIFF(CURDATE(), b.date_created) AS jours,
       pi.identifier AS dossier,
       CONCAT(pn.family_name, &apos; &apos;, pn.given_name) AS patient,
       tel.value AS telephone,
       (SELECT COALESCE(SUM(li.price * li.quantity), 0) FROM cashier_bill_line_item li WHERE li.bill_id = b.bill_id AND li.voided = 0) AS total,
       (SELECT COALESCE(SUM(bp.amount), 0) FROM cashier_bill_payment bp WHERE bp.bill_id = b.bill_id AND bp.voided = 0) AS paye,
       (SELECT COALESCE(SUM(li.price * li.quantity), 0) FROM cashier_bill_line_item li WHERE li.bill_id = b.bill_id AND li.voided = 0) - (SELECT COALESCE(SUM(bp.amount), 0) FROM cashier_bill_payment bp WHERE bp.bill_id = b.bill_id AND bp.voided = 0) AS reste
FROM cashier_bill b
JOIN person p ON p.person_id = b.patient_id
LEFT JOIN person_name pn ON pn.person_id = p.person_id AND pn.preferred = 1 AND pn.voided = 0
LEFT JOIN patient_identifier pi ON pi.patient_id = b.patient_id AND pi.preferred = 1 AND pi.voided = 0
LEFT JOIN person_attribute tel ON tel.person_id = p.person_id AND tel.voided = 0
     AND tel.person_attribute_type_id = (SELECT person_attribute_type_id FROM person_attribute_type
                                         WHERE name = &apos;Téléphone&apos; LIMIT 1)
WHERE b.voided = 0
  AND (SELECT COALESCE(SUM(li.price * li.quantity), 0) FROM cashier_bill_line_item li WHERE li.bill_id = b.bill_id AND li.voided = 0) &gt; (SELECT COALESCE(SUM(bp.amount), 0) FROM cashier_bill_payment bp WHERE bp.bill_id = b.bill_id AND bp.voided = 0)
  AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)
ORDER BY b.date_created</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', date_changed = NOW()
WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b011';

-- Tableau de bord - Ventes par acte
INSERT INTO serialized_object (name, description, type, subtype, serialization_class,
                               serialized_data, date_created, creator, retired, uuid)
SELECT 'Tableau de bord - Ventes par acte', 'Quantités et montants facturés par acte sur une période', type, subtype, serialization_class, '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b012" retired="false">
  <name>Tableau de bord - Ventes par acte</name>
  <description>Quantités et montants facturés par acte sur une période</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5">
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>startDate</name><label>Date début</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>endDate</name><label>Date fin</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
  </parameters>
  <sqlQuery>SELECT COALESCE(s.name, li.price_name, &apos;Non spécifié&apos;) AS acte,
       SUM(li.quantity) AS quantite,
       SUM(li.price * li.quantity) AS montant
FROM cashier_bill b
JOIN cashier_bill_line_item li ON li.bill_id = b.bill_id AND li.voided = 0
LEFT JOIN cashier_billable_service s ON s.service_id = li.service_id
WHERE b.voided = 0
  AND b.date_created &gt;= DATE(:startDate) AND b.date_created &lt; DATE(:endDate) + INTERVAL 1 DAY
  AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)
GROUP BY COALESCE(s.name, li.price_name, &apos;Non spécifié&apos;)
ORDER BY montant DESC</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', NOW(), creator, 0, '0f7a0000-c1c0-4000-8000-00000000b012'
FROM serialized_object
WHERE serialized_object_id = 12
  AND NOT EXISTS (SELECT 1 FROM serialized_object WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b012');
UPDATE serialized_object SET serialized_data = '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000b012" retired="false">
  <name>Tableau de bord - Ventes par acte</name>
  <description>Quantités et montants facturés par acte sur une période</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 15:00:00 UTC</dateCreated>
  <parameters id="5">
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>startDate</name><label>Date début</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
    <org.openmrs.module.reporting.evaluation.parameter.Parameter>
      <name>endDate</name><label>Date fin</label>
      <type>java.util.Date</type>
    </org.openmrs.module.reporting.evaluation.parameter.Parameter>
  </parameters>
  <sqlQuery>SELECT COALESCE(s.name, li.price_name, &apos;Non spécifié&apos;) AS acte,
       SUM(li.quantity) AS quantite,
       SUM(li.price * li.quantity) AS montant
FROM cashier_bill b
JOIN cashier_bill_line_item li ON li.bill_id = b.bill_id AND li.voided = 0
LEFT JOIN cashier_billable_service s ON s.service_id = li.service_id
WHERE b.voided = 0
  AND b.date_created &gt;= DATE(:startDate) AND b.date_created &lt; DATE(:endDate) + INTERVAL 1 DAY
  AND NOT EXISTS (SELECT 1 FROM person_attribute dm
                  JOIN person_attribute_type dmt ON dmt.person_attribute_type_id = dm.person_attribute_type_id
                  WHERE dm.person_id = b.patient_id AND dm.voided = 0
                    AND dmt.name = &apos;demo_patient&apos; AND dm.value = &apos;true&apos;)
GROUP BY COALESCE(s.name, li.price_name, &apos;Non spécifié&apos;)
ORDER BY montant DESC</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', date_changed = NOW()
WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000b012';

SELECT serialized_object_id AS id, name, uuid FROM serialized_object
WHERE uuid LIKE '0f7a0000-c1c0-4000-8000-00000000b%' ORDER BY uuid;
