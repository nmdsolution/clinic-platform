/**
 * Corrections d'affichage des modules officiels, injectées une fois au démarrage.
 *
 * Les sélecteurs visent le début du nom de classe CSS Modules
 * (« -esm-<module>__<fichier>__<classe>___<hash> ») pour rester valables quand le
 * hash change à une mise à jour du module.
 */
export const STYLES_GLOBAUX = `
/* Facturation : la barre d'actions de la facture (Demander une remise, Ajouter des éléments,
   Supprimer, Finaliser, Imprimer) passe à la ligne au lieu de déborder sous le menu de gauche. */
[class*="-esm-billing__invoice__actionsContainer"] {
  flex-wrap: wrap;
  justify-content: flex-end;
  row-gap: 0.5rem;
}

/* Facturation : paiements et totaux se placent l'un sous l'autre quand la largeur manque
   (moins de ~1100 px), au lieu de pousser les totaux et le bouton de paiement hors de l'écran. */
[class*="-esm-billing__payments__wrapper"] {
  flex-wrap: wrap;
  gap: 1rem;
}
[class*="-esm-billing__payments__paymentTotals"] {
  flex: 1 1 18rem;
  min-width: 0;
}
[class*="-esm-billing__payments__processPayments"] {
  flex-wrap: wrap;
  gap: 0.5rem;
  width: auto;
}
[class*="-esm-billing__payments__processPayments"] .cds--btn {
  flex: 1 1 auto;
  max-width: none;
}
`;

export function injecterStylesGlobaux(): void {
  if (document.getElementById('hgest-styles-globaux')) {
    return;
  }
  const style = document.createElement('style');
  style.id = 'hgest-styles-globaux';
  style.textContent = STYLES_GLOBAUX;
  document.head.appendChild(style);
}
