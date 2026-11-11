import React, { useMemo, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { InlineLoading, InlineNotification } from '@carbon/react';
import { DATASETS, formatDay, isoDay, num, useDataSet } from '../api';
import MonthCalendar, { monthRange } from '../calendar/month-calendar.component';
import DataTable, { type Column } from '../data-table.component';
import { openPatientChart } from '../patients/patients-tab.component';
import styles from '../root.scss';

/** Nombre de consultations (visites) par jour sur un calendrier, détail du jour choisi en dessous */
const ConsultationsTab: React.FC = () => {
  const { t } = useTranslation();
  const [month, setMonth] = useState(() => new Date(new Date().getFullYear(), new Date().getMonth(), 1));
  const [day, setDay] = useState(() => isoDay(new Date()));

  const range = useMemo(() => monthRange(month), [month]);
  const parJour = useDataSet(DATASETS.consultationsParJour, range);
  const detail = useDataSet(DATASETS.consultationsDetail, { startDate: day, endDate: day });

  const byDay = useMemo(() => new Map(parJour.rows.map((r) => [String(r.jour), num(r.visites)])), [parJour.rows]);
  const totalMois = useMemo(() => parJour.rows.reduce((s, r) => s + num(r.visites), 0), [parJour.rows]);

  const columns: Array<Column> = [
    { key: 'heure', header: t('heure', 'Heure') },
    { key: 'dossier', header: t('dossier', 'N° dossier') },
    { key: 'patient', header: t('patient', 'Patient') },
    { key: 'sexe', header: t('sexe', 'Sexe') },
    { key: 'age', header: t('age', 'Âge'), numeric: true },
    { key: 'type_visite', header: t('typeVisite', 'Type de visite') },
    { key: 'actes', header: t('actes', 'Actes saisis') },
    { key: 'soignants', header: t('soignants', 'Soignant(s)') },
  ];

  return (
    <>
      <div className={styles.totals}>
        <div>
          <span className={styles.totalLabel}>{t('consultationsDuMois', 'Consultations du mois')}</span>
          <span className={styles.totalValue}>{parJour.loading ? '…' : totalMois}</span>
        </div>
        <div>
          <span className={styles.totalLabel}>{t('consultationsDuJour', 'Consultations le')} {formatDay(day)}</span>
          <span className={styles.totalValue}>{parJour.loading ? '…' : (byDay.get(day) ?? 0)}</span>
        </div>
      </div>
      {parJour.error && <InlineNotification kind="error" title={parJour.error} lowContrast hideCloseButton />}
      {parJour.loading && <InlineLoading description={t('chargement', 'Chargement...')} />}
      <MonthCalendar
        month={month}
        onMonthChange={setMonth}
        selectedDay={day}
        onSelectDay={setDay}
        isActive={(d) => (byDay.get(d) ?? 0) > 0}
        renderDay={(d) => {
          const n = byDay.get(d) ?? 0;
          return `${n} consult.`;
        }}
      />
      <h4 className={styles.sectionTitle}>
        {t('consultationsDu', 'Consultations du')} {formatDay(day)}
      </h4>
      <DataTable
        columns={columns}
        rows={detail.rows}
        loading={detail.loading}
        error={detail.error}
        emptyText={t('aucuneConsultation', 'Aucune consultation ce jour-là (0).')}
        onRowClick={openPatientChart}
      />
    </>
  );
};

export default ConsultationsTab;
