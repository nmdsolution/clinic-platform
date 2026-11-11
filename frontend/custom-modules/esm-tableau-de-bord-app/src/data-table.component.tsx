import React, { useEffect, useState } from 'react';
import {
  InlineLoading,
  InlineNotification,
  Pagination,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableHeader,
  TableRow,
} from '@carbon/react';
import type { Row } from './api';
import styles from './root.scss';

export interface Column {
  key: string;
  header: string;
  render?: (row: Row) => React.ReactNode;
  numeric?: boolean;
}

interface Props {
  columns: Array<Column>;
  rows: Array<Row>;
  loading?: boolean;
  error?: string | null;
  emptyText: string;
  onRowClick?: (row: Row) => void;
  pageSize?: number;
}

/** Tableau simple avec pagination, utilisé par tous les onglets */
const DataTable: React.FC<Props> = ({ columns, rows, loading, error, emptyText, onRowClick, pageSize = 25 }) => {
  const [page, setPage] = useState(1);
  const [size, setSize] = useState(pageSize);

  // Revenir à la première page quand la liste change (recherche, nouveau jour)
  useEffect(() => setPage(1), [rows]);

  if (loading) return <InlineLoading description="Chargement..." />;
  if (error) return <InlineNotification kind="error" title={error} lowContrast hideCloseButton />;
  if (!rows.length) return <p className={styles.empty}>{emptyText}</p>;

  const visible = rows.slice((page - 1) * size, page * size);

  return (
    <TableContainer>
      <Table size="sm" useZebraStyles>
        <TableHead>
          <TableRow>
            {columns.map((c) => (
              <TableHeader key={c.key} className={c.numeric ? styles.number : undefined}>
                {c.header}
              </TableHeader>
            ))}
          </TableRow>
        </TableHead>
        <TableBody>
          {visible.map((row, i) => (
            <TableRow
              key={i}
              className={onRowClick ? styles.clickable : undefined}
              onClick={onRowClick ? () => onRowClick(row) : undefined}>
              {columns.map((c) => (
                <TableCell key={c.key} className={c.numeric ? styles.number : undefined}>
                  {c.render ? c.render(row) : (row[c.key] ?? '')}
                </TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </Table>
      {rows.length > size && (
        <Pagination
          page={page}
          pageSize={size}
          pageSizes={[25, 50, 100]}
          totalItems={rows.length}
          itemsPerPageText="Lignes par page"
          onChange={({ page: p, pageSize: s }) => {
            setPage(p);
            setSize(s);
          }}
        />
      )}
    </TableContainer>
  );
};

export default DataTable;
