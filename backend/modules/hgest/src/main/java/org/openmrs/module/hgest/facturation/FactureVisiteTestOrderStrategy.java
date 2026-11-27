package org.openmrs.module.hgest.facturation;

import org.openmrs.Order;
import org.openmrs.Patient;
import org.openmrs.module.billing.api.billing.BillingResult;
import org.openmrs.module.billing.api.billing.impl.TestOrderBillingStrategy;
import org.openmrs.module.billing.api.model.Bill;
import org.openmrs.module.billing.api.model.BillLineItem;

/** Examens : comme FactureVisiteDrugOrderStrategy, avec le prix du service facturable de l'examen. */
public class FactureVisiteTestOrderStrategy extends TestOrderBillingStrategy {

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
