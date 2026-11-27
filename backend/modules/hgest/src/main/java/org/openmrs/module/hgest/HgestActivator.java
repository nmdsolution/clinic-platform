package org.openmrs.module.hgest;

import org.openmrs.module.BaseModuleActivator;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/** Module HGest FASSE : une facture par visite, contrôle du paiement avant délivrance et prélèvement. */
public class HgestActivator extends BaseModuleActivator {

	private static final Logger log = LoggerFactory.getLogger(HgestActivator.class);

	@Override
	public void started() {
		log.info("Module HGest démarré : facture par visite et contrôle du paiement actifs (voir hgest.* dans les paramètres)");
	}

	@Override
	public void stopped() {
		log.info("Module HGest arrêté");
	}
}
