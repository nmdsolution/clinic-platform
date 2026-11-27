package org.openmrs.module.hgest.web;

import java.util.Map;

import org.openmrs.Order;
import org.openmrs.api.APIAuthenticationException;
import org.openmrs.api.APIException;
import org.openmrs.api.context.Context;
import org.openmrs.module.hgest.paiement.ControlePaiement;
import org.openmrs.module.webservices.rest.SimpleObject;
import org.openmrs.module.webservices.rest.web.RestConstants;
import org.openmrs.module.webservices.rest.web.response.IllegalRequestException;
import org.openmrs.module.webservices.rest.web.response.ObjectNotFoundException;
import org.openmrs.module.webservices.rest.web.v1_0.controller.BaseRestController;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;

/**
 * /ws/rest/v1/hgest/... :
 *   GET  paiement/bloques        prescriptions des visites ouvertes refusées tant qu'elles ne sont pas payées
 *   GET  paiement/{orderUuid}    situation d'une prescription
 *   GET  derogation?jours=30     dérogations accordées
 *   POST derogation              {"commande": "<uuid>", "motif": "..."} (privilège « HGest: Deroger au paiement »)
 */
@Controller
@RequestMapping("/rest/" + RestConstants.VERSION_1 + "/hgest")
public class PaiementController extends BaseRestController {

	@RequestMapping(value = "/paiement/bloques", method = RequestMethod.GET)
	@ResponseBody
	public SimpleObject bloques() {
		verifierConnexion();
		return new SimpleObject().add("results", ControlePaiement.get().actesBloques());
	}

	@RequestMapping(value = "/paiement/{orderUuid}", method = RequestMethod.GET)
	@ResponseBody
	public SimpleObject situation(@PathVariable("orderUuid") String orderUuid) {
		verifierConnexion();
		ControlePaiement controle = ControlePaiement.get();
		ControlePaiement.Situation s = controle.situation(commande(orderUuid));
		SimpleObject o = new SimpleObject().add("etat", s.etat.name()).add("montant", s.montant)
				.add("facture", s.facture).add("acte", s.acte);
		if (s.etat == ControlePaiement.Etat.A_PAYER) {
			o.add("message", controle.message(s, "Délivrance ou prélèvement"));
		}
		return o;
	}

	@RequestMapping(value = "/derogation", method = RequestMethod.GET)
	@ResponseBody
	public SimpleObject derogations(@RequestParam(value = "jours", defaultValue = "30") int jours) {
		verifierConnexion();
		return new SimpleObject().add("results", ControlePaiement.get().derogations(jours))
				.add("peutDeroger", Context.hasPrivilege(ControlePaiement.PRIVILEGE_DEROGATION));
	}

	@RequestMapping(value = "/derogation", method = RequestMethod.POST)
	@ResponseBody
	public SimpleObject creer(@RequestBody Map<String, Object> corps) {
		verifierConnexion();
		Object uuidCommande = corps.get("commande");
		Object motif = corps.get("motif");
		Order order = commande(uuidCommande == null ? null : uuidCommande.toString());
		try {
			String uuid = ControlePaiement.get().enregistrerDerogation(order, motif == null ? null : motif.toString());
			return new SimpleObject().add("uuid", uuid);
		}
		catch (APIAuthenticationException e) {
			throw e;
		}
		catch (APIException e) {
			// Motif manquant, dérogation déjà accordée, acte déjà payé : erreur de saisie (400), pas erreur serveur
			throw new IllegalRequestException(e.getMessage());
		}
	}

	private static Order commande(String uuid) {
		Order order = uuid == null ? null : Context.getOrderService().getOrderByUuid(uuid);
		if (order == null) {
			throw new ObjectNotFoundException();
		}
		return order;
	}

	private static void verifierConnexion() {
		if (!Context.isAuthenticated()) {
			throw new APIAuthenticationException("Connexion requise");
		}
	}
}
