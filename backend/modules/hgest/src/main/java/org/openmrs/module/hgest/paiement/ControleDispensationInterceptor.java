package org.openmrs.module.hgest.paiement;

import ca.uhn.fhir.rest.server.exceptions.UnprocessableEntityException;
import org.aopalliance.intercept.MethodInterceptor;
import org.aopalliance.intercept.MethodInvocation;
import org.hl7.fhir.r4.model.MedicationDispense;
import org.hl7.fhir.r4.model.Reference;
import org.openmrs.Order;
import org.openmrs.api.context.Context;

/**
 * Pharmacie : refuse l'enregistrement d'une délivrance « terminée » (FHIR MedicationDispense, statut
 * completed) dont la prescription n'est pas payée. Les autres statuts (en attente, refusée) passent.
 */
public class ControleDispensationInterceptor implements MethodInterceptor {

	@Override
	public Object invoke(MethodInvocation invocation) throws Throwable {
		String nom = invocation.getMethod().getName();
		if ("create".equals(nom) || "update".equals(nom)) {
			for (Object argument : invocation.getArguments()) {
				if (argument instanceof MedicationDispense) {
					verifier((MedicationDispense) argument);
				}
			}
		}
		return invocation.proceed();
	}

	private void verifier(MedicationDispense delivrance) {
		if (delivrance.getStatus() != MedicationDispense.MedicationDispenseStatus.COMPLETED) {
			return;
		}
		ControlePaiement controle = ControlePaiement.get();
		for (Reference prescription : delivrance.getAuthorizingPrescription()) {
			String uuid = prescription.getReferenceElement().getIdPart();
			if (uuid == null) {
				continue;
			}
			Order order = Context.getOrderService().getOrderByUuid(uuid);
			ControlePaiement.Situation s = controle.situation(order);
			if (s.etat == ControlePaiement.Etat.A_PAYER) {
				throw new UnprocessableEntityException(controle.message(s, "Délivrance"));
			}
		}
	}
}
