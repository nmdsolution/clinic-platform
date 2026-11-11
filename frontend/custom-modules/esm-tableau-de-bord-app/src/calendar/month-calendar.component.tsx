import React from 'react';
import { Button } from '@carbon/react';
import { ChevronLeft, ChevronRight } from '@carbon/react/icons';
import { isoDay } from '../api';
import styles from './month-calendar.scss';

const JOURS = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
const MOIS = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];

export function monthRange(month: Date) {
  const start = new Date(month.getFullYear(), month.getMonth(), 1);
  const end = new Date(month.getFullYear(), month.getMonth() + 1, 0);
  return { startDate: isoDay(start), endDate: isoDay(end) };
}

interface Props {
  month: Date;
  onMonthChange: (month: Date) => void;
  selectedDay: string;
  onSelectDay: (isoDay: string) => void;
  /** Contenu affiché dans la case d'un jour (AAAA-MM-JJ) ; appelé pour chaque jour, même vide */
  renderDay: (isoDay: string) => React.ReactNode;
  /** Vrai si le jour a de l'activité (case mise en évidence) */
  isActive: (isoDay: string) => boolean;
}

/** Calendrier mensuel : chaque jour est cliquable et affiche sa valeur, zéro compris */
const MonthCalendar: React.FC<Props> = ({ month, onMonthChange, selectedDay, onSelectDay, renderDay, isActive }) => {
  const year = month.getFullYear();
  const m = month.getMonth();
  const daysInMonth = new Date(year, m + 1, 0).getDate();
  const offset = (new Date(year, m, 1).getDay() + 6) % 7; // lundi = 0
  const today = isoDay(new Date());

  const cells: Array<string | null> = [
    ...Array(offset).fill(null),
    ...Array.from({ length: daysInMonth }, (_, i) => isoDay(new Date(year, m, i + 1))),
  ];

  return (
    <div className={styles.calendar}>
      <div className={styles.header}>
        <Button
          kind="ghost"
          size="sm"
          hasIconOnly
          renderIcon={ChevronLeft}
          iconDescription="Mois précédent"
          onClick={() => onMonthChange(new Date(year, m - 1, 1))}
        />
        <span className={styles.monthName}>
          {MOIS[m]} {year}
        </span>
        <Button
          kind="ghost"
          size="sm"
          hasIconOnly
          renderIcon={ChevronRight}
          iconDescription="Mois suivant"
          onClick={() => onMonthChange(new Date(year, m + 1, 1))}
        />
      </div>
      <div className={styles.grid}>
        {JOURS.map((j) => (
          <div key={j} className={styles.weekday}>
            {j}
          </div>
        ))}
        {cells.map((day, i) =>
          day ? (
            <button
              key={day}
              type="button"
              className={[
                styles.day,
                isActive(day) ? styles.active : '',
                day === selectedDay ? styles.selected : '',
                day === today ? styles.today : '',
              ].join(' ')}
              onClick={() => onSelectDay(day)}>
              <span className={styles.dayNumber}>{Number(day.slice(8))}</span>
              <span className={styles.dayValue}>{renderDay(day)}</span>
            </button>
          ) : (
            <div key={`vide-${i}`} />
          ),
        )}
      </div>
    </div>
  );
};

export default MonthCalendar;
