-- ============================================================
-- RAPPORTS FASSE : « Stock de la pharmacie » et « Consultations par date »
-- Même chemin que « Liste des patients » : Rapports > choisir le rapport > Aperçu web.
-- Les lignes sont copiées du rapport « Liste des patients » (serialized_object 12 et 13),
-- seuls le nom, la description, la requête et l'UUID changent.
-- Script idempotent : peut être relancé sans créer de doublons.
-- ============================================================
-- Usage :
-- docker exec -i clinic-platform-db-1 mysql -u openmrs -popenmrs openmrs < /opt/clinic-platform/grille/rapports_stock_consultations.sql

SET NAMES utf8mb4;
-- Stock de la pharmacie
INSERT INTO serialized_object (name, description, type, subtype, serialization_class,
                               serialized_data, date_created, creator, retired, uuid)
SELECT 'Stock de la pharmacie', 'Quantités en stock à la Pharmacie principale, par article et par lot', type, subtype, serialization_class,
       '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000a001" retired="false">
  <name>Stock de la pharmacie</name>
  <description>Quantités en stock à la Pharmacie principale, par article et par lot</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 12:00:00 UTC</dateCreated>
  <parameters id="5"/>
  <sqlQuery>SELECT COALESCE(d.name, si.common_name) AS `Article`,
       sb.batch_no AS `Lot`,
       DATE(sb.expiration) AS `Péremption`,
       SUM(t.quantity) AS `Quantité`,
       MAX(ucn.name) AS `Unité`,
       si.reorder_level AS `Seuil d&apos;alerte`,
       CASE WHEN SUM(t.quantity) &lt;= 0 THEN &apos;Rupture&apos;
            WHEN sb.expiration IS NOT NULL AND sb.expiration &lt; CURDATE() THEN &apos;Périmé&apos;
            WHEN sb.expiration IS NOT NULL AND sb.expiration &lt; CURDATE() + INTERVAL 90 DAY THEN &apos;Périme sous 90 jours&apos;
            WHEN si.reorder_level IS NOT NULL AND SUM(t.quantity) &lt;= si.reorder_level THEN &apos;Sous le seuil&apos;
            ELSE &apos;OK&apos; END AS `État`
FROM stockmgmt_stock_item_transaction t
JOIN stockmgmt_stock_item si ON si.stock_item_id = t.stock_item_id AND si.voided = 0
JOIN stockmgmt_party pa ON pa.party_id = t.party_id
JOIN location loc ON loc.location_id = pa.location_id AND loc.name = &apos;Pharmacie principale&apos;
LEFT JOIN drug d ON d.drug_id = si.drug_id
LEFT JOIN stockmgmt_stock_batch sb ON sb.stock_batch_id = t.stock_batch_id
LEFT JOIN stockmgmt_stock_item_packaging_uom u ON u.stock_item_packaging_uom_id = t.stock_item_packaging_uom_id
LEFT JOIN concept_name ucn ON ucn.concept_id = u.packaging_uom_id AND ucn.locale_preferred = 1 AND ucn.voided = 0
GROUP BY si.stock_item_id, sb.stock_batch_id
ORDER BY `Article`, `Péremption`</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', NOW(), creator, 0, '0f7a0000-c1c0-4000-8000-00000000a001'
FROM serialized_object
WHERE serialized_object_id = 12
  AND NOT EXISTS (SELECT 1 FROM serialized_object WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000a001');
INSERT INTO serialized_object (name, description, type, subtype, serialization_class,
                               serialized_data, date_created, creator, retired, uuid)
SELECT 'Stock de la pharmacie', 'Quantités en stock à la Pharmacie principale, par article et par lot', type, subtype, serialization_class,
       '<org.openmrs.module.reporting.report.definition.ReportDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000a002" retired="false">
  <name>Stock de la pharmacie</name>
  <description>Quantités en stock à la Pharmacie principale, par article et par lot</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 12:00:00 UTC</dateCreated>
  <parameters id="5"/>
  <dataSetDefinitions class="linked-hash-map" id="6">
    <entry>
      <string>Stock-de-la-pharmacie</string>
      <org.openmrs.module.reporting.evaluation.parameter.Mapped id="7">
        <parameterizable class="org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition" id="8" uuid="0f7a0000-c1c0-4000-8000-00000000a001"/>
        <parameterMappings id="9"/>
      </org.openmrs.module.reporting.evaluation.parameter.Mapped>
    </entry>
  </dataSetDefinitions>
</org.openmrs.module.reporting.report.definition.ReportDefinition>', NOW(), creator, 0, '0f7a0000-c1c0-4000-8000-00000000a002'
FROM serialized_object
WHERE serialized_object_id = 13
  AND NOT EXISTS (SELECT 1 FROM serialized_object WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000a002');

-- Consultations par date
INSERT INTO serialized_object (name, description, type, subtype, serialization_class,
                               serialized_data, date_created, creator, retired, uuid)
SELECT 'Consultations par date', 'Visites des patients sur une période choisie (hors patients de démonstration)', type, subtype, serialization_class,
       '<org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000a003" retired="false">
  <name>Consultations par date</name>
  <description>Visites des patients sur une période choisie (hors patients de démonstration)</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 12:00:00 UTC</dateCreated>
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
  <sqlQuery>SELECT DATE(v.date_started) AS `Date`,
       TIME_FORMAT(v.date_started, &apos;%H:%i&apos;) AS `Heure`,
       pi.identifier AS `N° dossier`,
       CONCAT(pn.family_name, &apos; &apos;, pn.given_name) AS `Patient`,
       p.gender AS `Sexe`,
       TIMESTAMPDIFF(YEAR, p.birthdate, v.date_started) AS `Âge`,
       vt.name AS `Type de visite`,
       loc.name AS `Lieu`,
       (SELECT GROUP_CONCAT(DISTINCT et.name ORDER BY et.name SEPARATOR &apos;, &apos;)
          FROM encounter e JOIN encounter_type et ON et.encounter_type_id = e.encounter_type
         WHERE e.visit_id = v.visit_id AND e.voided = 0) AS `Actes saisis`,
       (SELECT GROUP_CONCAT(DISTINCT CONCAT(prn.given_name, &apos; &apos;, prn.family_name) SEPARATOR &apos;, &apos;)
          FROM encounter e
          JOIN encounter_provider ep ON ep.encounter_id = e.encounter_id AND ep.voided = 0
          JOIN provider pr ON pr.provider_id = ep.provider_id
          JOIN person_name prn ON prn.person_id = pr.person_id AND prn.preferred = 1 AND prn.voided = 0
         WHERE e.visit_id = v.visit_id AND e.voided = 0) AS `Soignant(s)`
FROM visit v
JOIN patient pt ON pt.patient_id = v.patient_id AND pt.voided = 0
JOIN person p ON p.person_id = pt.patient_id
JOIN visit_type vt ON vt.visit_type_id = v.visit_type_id
LEFT JOIN location loc ON loc.location_id = v.location_id
LEFT JOIN person_name pn ON pn.person_id = p.person_id AND pn.preferred = 1 AND pn.voided = 0
LEFT JOIN patient_identifier pi ON pi.patient_id = pt.patient_id AND pi.preferred = 1 AND pi.voided = 0
WHERE v.voided = 0
  AND v.date_started &gt;= DATE(:startDate)
  AND v.date_started &lt; DATE(:endDate) + INTERVAL 1 DAY
  AND NOT EXISTS (SELECT 1 FROM person_attribute d
                  JOIN person_attribute_type dt ON dt.person_attribute_type_id = d.person_attribute_type_id
                  WHERE d.person_id = p.person_id AND d.voided = 0
                    AND dt.name = &apos;demo_patient&apos; AND d.value = &apos;true&apos;)
ORDER BY v.date_started</sqlQuery>
</org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition>', NOW(), creator, 0, '0f7a0000-c1c0-4000-8000-00000000a003'
FROM serialized_object
WHERE serialized_object_id = 12
  AND NOT EXISTS (SELECT 1 FROM serialized_object WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000a003');
INSERT INTO serialized_object (name, description, type, subtype, serialization_class,
                               serialized_data, date_created, creator, retired, uuid)
SELECT 'Consultations par date', 'Visites des patients sur une période choisie (hors patients de démonstration)', type, subtype, serialization_class,
       '<org.openmrs.module.reporting.report.definition.ReportDefinition id="1" uuid="0f7a0000-c1c0-4000-8000-00000000a004" retired="false">
  <name>Consultations par date</name>
  <description>Visites des patients sur une période choisie (hors patients de démonstration)</description>
  <creator id="2" uuid="82f18b44-6814-11e8-923f-e9a88dcb533f"/>
  <dateCreated id="3">2026-11-11 12:00:00 UTC</dateCreated>
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
  <dataSetDefinitions class="linked-hash-map" id="6">
    <entry>
      <string>Consultations-par-date</string>
      <org.openmrs.module.reporting.evaluation.parameter.Mapped id="7">
        <parameterizable class="org.openmrs.module.reporting.dataset.definition.SqlDataSetDefinition" id="8" uuid="0f7a0000-c1c0-4000-8000-00000000a003"/>
        <parameterMappings id="9">
          <entry><string>startDate</string><string>${startDate}</string></entry>
          <entry><string>endDate</string><string>${endDate}</string></entry>
        </parameterMappings>
      </org.openmrs.module.reporting.evaluation.parameter.Mapped>
    </entry>
  </dataSetDefinitions>
</org.openmrs.module.reporting.report.definition.ReportDefinition>', NOW(), creator, 0, '0f7a0000-c1c0-4000-8000-00000000a004'
FROM serialized_object
WHERE serialized_object_id = 13
  AND NOT EXISTS (SELECT 1 FROM serialized_object WHERE uuid = '0f7a0000-c1c0-4000-8000-00000000a004');

SELECT serialized_object_id AS id, name, SUBSTRING_INDEX(type, '.', -1) AS type, uuid
FROM serialized_object
WHERE uuid LIKE '0f7a0000-c1c0-4000-8000-00000000a00%' OR serialized_object_id IN (12, 13)
ORDER BY serialized_object_id;
