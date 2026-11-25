import { duree, estOubliee } from './visites-ouvertes-tab.component';

describe('Visites ouvertes', () => {
  it('signale une consultation ouverte depuis plus de 24 h', () => {
    expect(estOubliee({ type_visite: 'Consultation au centre', heures: 30 })).toBe(true);
    expect(estOubliee({ type_visite: 'Consultation au centre', heures: 5 })).toBe(false);
  });

  it("ne signale jamais une hospitalisation", () => {
    expect(estOubliee({ type_visite: 'Hospitalisation', heures: 1134 })).toBe(false);
  });

  it('affiche la durée en heures puis en jours', () => {
    expect(duree(5)).toBe('5 h');
    expect(duree(47)).toBe('47 h');
    expect(duree(1134)).toBe('47 j');
  });
});
