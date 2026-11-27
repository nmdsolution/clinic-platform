package org.openmrs.module.hgest.facturation;

import org.openmrs.Order;
import org.openmrs.Patient;
import org.openmrs.module.billing.api.billing.BillingResult;
import org.openmrs.module.billing.api.billing.impl.DrugOrderBillingStrategy;
import org.openmrs.module.billing.api.model.Bill;
import org.openmrs.module.billing.api.model.BillLineItem;

/**
 * Ordonnances : même prix, même caisse et même annulation de ligne que le module billing ;
 * seule la facture de destination change (celle en attente de la visite si elle existe).
 */
public class FactureVisiteDrugOrderStrategy extends DrugOrderBillingStrategy {

	/** Passe avant la règle du module billing (qui renvoie Integer.MAX_VALUE). */
	@Override
	public int getOrder() {
		return 0;
	}

	@Override
	protected BillingResult createBill(Patient patient, BillLineItem lineItem, Order order) {
		Bill facture = FactureVisite.factureEnAttente(billService, order);
		if (facture == null) {
			return super.createBill(patient, lineItem, order);
		}
		return FactureVisite.ajouter(billService, facture, lineItem, order);
	}
}
