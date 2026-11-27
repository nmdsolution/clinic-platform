package org.openmrs.module.hgest.paiement;

import org.openmrs.api.APIException;

/** Délivrance ou prélèvement refusé : l'acte n'est pas payé et aucune dérogation n'existe. */
public class PaiementRequisException extends APIException {

	private static final long serialVersionUID = 1L;

	public PaiementRequisException(String message) {
		super(message);
	}
}
