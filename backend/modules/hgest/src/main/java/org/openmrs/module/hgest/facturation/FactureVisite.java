package org.openmrs.module.hgest.facturation;

import java.util.Comparator;
import java.util.List;

import org.openmrs.Encounter;
import org.openmrs.Order;
import org.openmrs.api.context.Context;
import org.openmrs.module.billing.api.BillService;
import org.openmrs.module.billing.api.billing.BillingResult;
import org.openmrs.module.billing.api.model.Bill;
import org.openmrs.module.billing.api.model.BillLineItem;
import org.openmrs.module.billing.api.model.BillStatus;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Une facture par visite : une ordonnance ou un examen s'ajoute à la facture encore en attente
 * (PENDING) de la même visite. Une facture finalisée ou payée ne reçoit plus de lignes : l'acte
 * suivant ouvre alors une nouvelle facture de la visite, comme le fait le module billing.
 */
public final class FactureVisite {

	public static final String GP_ACTIF = "hgest.facturation.uneFactureParVisite";

	private static final Logger log = LoggerFactory.getLogger(FactureVisite.class);

	private FactureVisite() {
	}

	/** La facture en attente la plus récente de la visite de la prescription, ou null. */
	public static Bill factureEnAttente(BillService billService, Order order) {
		String actif = Context.getAdministrationService().getGlobalProperty(GP_ACTIF, "true");
		if (!"true".equalsIgnoreCase(actif.trim())) {
			return null;
		}
		Encounter encounter = order.getEncounter();
		if (encounter == null || encounter.getVisit() == null || order.getPatient() == null) {
			return null;
		}
		Integer visitId = encounter.getVisit().getVisitId();
		List<Bill> factures = billService.getBillsByPatientUuid(order.getPatient().getUuid(), null);
		if (factures == null) {
			return null;
		}
		return factures.stream()
				.filter(b -> !Boolean.TRUE.equals(b.getVoided()))
				.filter(b -> b.getStatus() == BillStatus.PENDING)
				.filter(b -> b.getVisit() != null && visitId.equals(b.getVisit().getVisitId()))
				.max(Comparator.comparing(Bill::getId))
				.orElse(null);
	}

	/** Ajoute la ligne à la facture existante et l'enregistre. */
	public static BillingResult ajouter(BillService billService, Bill facture, BillLineItem ligne, Order order) {
		facture.addLineItem(ligne);
		Bill enregistree = billService.saveBill(facture);
		log.info("Ordonnance {} ajoutée à la facture {} de la visite", order.getUuid(), enregistree.getUuid());
		return BillingResult.updated(enregistree);
	}
}
