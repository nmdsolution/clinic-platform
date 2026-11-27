package org.openmrs.module.hgest.paiement;

import java.math.BigDecimal;
import java.text.DecimalFormat;
import java.text.DecimalFormatSymbols;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Date;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.stream.Collectors;

import org.apache.commons.lang3.StringUtils;
import org.openmrs.Order;
import org.openmrs.api.APIAuthenticationException;
import org.openmrs.api.APIException;
import org.openmrs.api.context.Context;
import org.openmrs.api.db.hibernate.DbSessionFactory;
import org.springframework.transaction.annotation.Transactional;

/**
 * Contrôle du paiement d'une prescription (médicament ou examen) avant délivrance ou prélèvement.
 *
 * Une prescription est « à payer » si sa ligne de facture (cashier_bill_line_item.order_id) existe,
 * coûte plus de 0, et que ni la ligne ni la facture ne sont PAID ou EXEMPTED. Elle reste autorisée si
 * la visite est exemptée (type ou attribut configurés) ou si une dérogation est enregistrée.
 * Sans ligne de facture (médicament sans prix, facturation pas encore passée), rien n'est bloqué.
 */
public class ControlePaiement {

	public static final String PRIVILEGE_DEROGATION = "HGest: Deroger au paiement";

	public static final String GP_ACTIF = "hgest.paiement.controleActif";

	public static final String GP_TYPES_VISITE = "hgest.paiement.typesVisiteExemptes";

	public static final String GP_VALEURS_ATTRIBUT = "hgest.paiement.valeursAttributVisiteExemptees";

	static final String TYPE_EXAMEN = "52a447d3-a64a-11e3-9aeb-50e549534c5e";

	static final String TYPE_MEDICAMENT = "131168f4-15f5-102d-96e4-000c29c2a5d7";

	private static final Set<String> STATUTS_REGLES = new HashSet<>(Arrays.asList("PAID", "EXEMPTED"));

	public enum Etat {
		CONTROLE_INACTIF, SANS_FACTURE, PAYE, EXEMPTE, DEROGATION, A_PAYER
	}

	/** Résultat du contrôle d'une prescription. */
	public static class Situation {

		public final Etat etat;

		public final BigDecimal montant;

		public final String facture;

		public final String acte;

		Situation(Etat etat, BigDecimal montant, String facture, String acte) {
			this.etat = etat;
			this.montant = montant;
			this.facture = facture;
			this.acte = acte;
		}

		static Situation de(Etat etat) {
			return new Situation(etat, null, null, null);
		}
	}

	private DbSessionFactory dbSessionFactory;

	public void setDbSessionFactory(DbSessionFactory dbSessionFactory) {
		this.dbSessionFactory = dbSessionFactory;
	}

	public static ControlePaiement get() {
		return Context.getRegisteredComponent("hgestControlePaiement", ControlePaiement.class);
	}

	// ------------------------------------------------------------------ contrôle

	@Transactional(readOnly = true)
	public Situation situation(Order order) {
		if (!controleActif()) {
			return Situation.de(Etat.CONTROLE_INACTIF);
		}
		if (order == null || order.getOrderId() == null) {
			return Situation.de(Etat.SANS_FACTURE);
		}
		Integer orderId = order.getOrderId();

		// Les colonnes sont toutes nommées (c0, c1…) : Hibernate refuse deux colonnes de même nom (uuid, status).
		List<?> visite = sql("SELECT v.visit_id AS c0, vt.uuid AS c1 FROM orders o"
				+ " JOIN encounter e ON e.encounter_id = o.encounter_id"
				+ " JOIN visit v ON v.visit_id = e.visit_id"
				+ " JOIN visit_type vt ON vt.visit_type_id = v.visit_type_id"
				+ " WHERE o.order_id = :id", "id", orderId);
		if (!visite.isEmpty()) {
			Object[] v = (Object[]) visite.get(0);
			if (visiteExemptee(((Number) v[0]).intValue(), (String) v[1])) {
				return Situation.de(Etat.EXEMPTE);
			}
		}

		List<?> lignes = sql("SELECT b.status AS c0, li.status AS c1, li.price * li.quantity AS c2, b.receipt_number AS c3,"
				+ " COALESCE(s.name, d.name, li.price_name) AS c4"
				+ " FROM cashier_bill_line_item li"
				+ " JOIN cashier_bill b ON b.bill_id = li.bill_id"
				+ " LEFT JOIN cashier_billable_service s ON s.service_id = li.service_id"
				+ " LEFT JOIN drug_order dro ON dro.order_id = li.order_id"
				+ " LEFT JOIN drug d ON d.drug_id = dro.drug_inventory_id"
				+ " WHERE li.order_id = :id AND li.voided = 0 AND b.voided = 0"
				+ " ORDER BY li.bill_line_item_id DESC", "id", orderId);
		if (lignes.isEmpty()) {
			return Situation.de(Etat.SANS_FACTURE);
		}
		Object[] l = (Object[]) lignes.get(0);
		BigDecimal montant = l[2] == null ? BigDecimal.ZERO : new BigDecimal(l[2].toString());
		if (STATUTS_REGLES.contains(String.valueOf(l[0])) || STATUTS_REGLES.contains(String.valueOf(l[1]))
				|| montant.signum() <= 0) {
			return Situation.de(Etat.PAYE);
		}
		if (aDerogation(orderId)) {
			return Situation.de(Etat.DEROGATION);
		}
		return new Situation(Etat.A_PAYER, montant, (String) l[3], (String) l[4]);
	}

	/** Lève PaiementRequisException si la prescription est à payer. */
	public void verifier(Order order, String action) {
		Situation s = situation(order);
		if (s.etat == Etat.A_PAYER) {
			throw new PaiementRequisException(message(s, action));
		}
	}

	public String message(Situation s, String action) {
		return action + " refusé(e) : « " + StringUtils.defaultIfBlank(s.acte, "cet acte") + " » n'est pas payé ("
				+ formatFcfa(s.montant) + ", facture " + StringUtils.defaultString(s.facture)
				+ "). Encaissez-le à la caisse, ou demandez une dérogation (Ventes › Dérogations).";
	}

	boolean visiteExemptee(int visitId, String typeVisiteUuid) {
		if (liste(GP_TYPES_VISITE).contains(typeVisiteUuid)) {
			return true;
		}
		Set<String> valeurs = liste(GP_VALEURS_ATTRIBUT);
		if (valeurs.isEmpty()) {
			return false;
		}
		List<?> attributs = sql("SELECT value_reference FROM visit_attribute WHERE visit_id = :id AND voided = 0", "id",
				visitId);
		return attributs.stream().anyMatch(a -> a != null && valeurs.contains(a.toString().trim()));
	}

	boolean aDerogation(int orderId) {
		return !sql("SELECT 1 FROM hgest_derogation_paiement WHERE order_id = :id AND voided = 0", "id", orderId)
				.isEmpty();
	}

	// ------------------------------------------------------------------ dérogations

	/** Enregistre une dérogation (privilège requis). Renvoie l'UUID de la dérogation. */
	@Transactional
	public String enregistrerDerogation(Order order, String motif) {
		if (!Context.hasPrivilege(PRIVILEGE_DEROGATION)) {
			throw new APIAuthenticationException("Vous n'avez pas le droit d'accorder une dérogation au paiement.");
		}
		if (order == null) {
			throw new APIException("Prescription introuvable.");
		}
		String m = StringUtils.trimToEmpty(motif);
		if (m.length() < 5) {
			throw new APIException("Indiquez le motif de la dérogation (au moins 5 caractères).");
		}
		if (m.length() > 500) {
			m = m.substring(0, 500);
		}
		Situation s = situation(order);
		if (s.etat == Etat.DEROGATION) {
			throw new APIException("Une dérogation existe déjà pour cette prescription.");
		}
		if (s.etat != Etat.A_PAYER) {
			throw new APIException("Cette prescription n'est pas bloquée : aucune dérogation nécessaire.");
		}
		String uuid = UUID.randomUUID().toString();
		dbSessionFactory.getCurrentSession()
				.createSQLQuery("INSERT INTO hgest_derogation_paiement (order_id, motif, creator, date_created, voided, uuid)"
						+ " VALUES (:o, :m, :u, :d, 0, :uuid)")
				.setParameter("o", order.getOrderId())
				.setParameter("m", m)
				.setParameter("u", Context.getAuthenticatedUser().getUserId())
				.setParameter("d", new Date())
				.setParameter("uuid", uuid)
				.executeUpdate();
		return uuid;
	}

	/** Prescriptions des visites ouvertes qui seront refusées à la délivrance ou au prélèvement. */
	@Transactional(readOnly = true)
	public List<Map<String, Object>> actesBloques() {
		if (!controleActif()) {
			return new ArrayList<>();
		}
		List<?> lignes = sql("SELECT o.uuid AS c0, o.order_number AS c1, ot.uuid AS c2,"
				+ " COALESCE(s.name, d.name, li.price_name) AS c3, li.price * li.quantity AS c4, b.receipt_number AS c5,"
				+ " TRIM(CONCAT(COALESCE(pn.given_name, ''), ' ', COALESCE(pn.family_name, ''))) AS c6, pi.identifier AS c7,"
				+ " p.uuid AS c8, v.date_started AS c9, v.visit_id AS c10, vt.uuid AS c11"
				+ " FROM orders o"
				+ " JOIN order_type ot ON ot.order_type_id = o.order_type_id"
				+ " JOIN encounter e ON e.encounter_id = o.encounter_id"
				+ " JOIN visit v ON v.visit_id = e.visit_id AND v.voided = 0 AND v.date_stopped IS NULL"
				+ " JOIN visit_type vt ON vt.visit_type_id = v.visit_type_id"
				+ " JOIN cashier_bill_line_item li ON li.order_id = o.order_id AND li.voided = 0"
				+ " JOIN cashier_bill b ON b.bill_id = li.bill_id AND b.voided = 0"
				+ " JOIN person p ON p.person_id = o.patient_id AND p.voided = 0"
				+ " LEFT JOIN person_name pn ON pn.person_id = o.patient_id AND pn.voided = 0 AND pn.preferred = 1"
				+ " LEFT JOIN patient_identifier pi ON pi.patient_id = o.patient_id AND pi.voided = 0 AND pi.preferred = 1"
				+ " LEFT JOIN cashier_billable_service s ON s.service_id = li.service_id"
				+ " LEFT JOIN drug_order dro ON dro.order_id = o.order_id"
				+ " LEFT JOIN drug d ON d.drug_id = dro.drug_inventory_id"
				+ " WHERE o.voided = 0 AND o.date_stopped IS NULL AND o.order_action <> 'DISCONTINUE'"
				+ " AND ot.uuid IN ('" + TYPE_EXAMEN + "', '" + TYPE_MEDICAMENT + "')"
				+ " AND b.status NOT IN ('PAID', 'EXEMPTED') AND li.status NOT IN ('PAID', 'EXEMPTED')"
				+ " AND li.price * li.quantity > 0"
				+ " AND NOT EXISTS (SELECT 1 FROM hgest_derogation_paiement dg WHERE dg.order_id = o.order_id AND dg.voided = 0)"
				+ " AND NOT EXISTS (SELECT 1 FROM medication_dispense md WHERE md.drug_order_id = o.order_id AND md.voided = 0)"
				+ " AND (o.fulfiller_status IS NULL OR o.fulfiller_status NOT IN ('COMPLETED', 'DECLINED'))"
				+ " ORDER BY v.date_started DESC, o.order_id");
		List<Map<String, Object>> resultat = new ArrayList<>();
		for (Object ligne : lignes) {
			Object[] r = (Object[]) ligne;
			if (visiteExemptee(((Number) r[10]).intValue(), (String) r[11])) {
				continue;
			}
			Map<String, Object> m = new LinkedHashMap<>();
			m.put("commande", r[0]);
			m.put("numero", r[1]);
			m.put("type", TYPE_EXAMEN.equals(r[2]) ? "Examen" : "Médicament");
			m.put("acte", r[3]);
			m.put("montant", r[4]);
			m.put("facture", r[5]);
			m.put("patient", r[6]);
			m.put("dossier", r[7]);
			m.put("patient_uuid", r[8]);
			m.put("debut_visite", date(r[9]));
			resultat.add(m);
		}
		return resultat;
	}

	/** Dérogations accordées sur les derniers jours, les plus récentes en premier. */
	@Transactional(readOnly = true)
	public List<Map<String, Object>> derogations(int jours) {
		List<?> lignes = sql("SELECT dg.uuid AS c0, dg.date_created AS c1, dg.motif AS c2,"
				+ " TRIM(CONCAT(COALESCE(upn.given_name, ''), ' ', COALESCE(upn.family_name, ''))) AS c3, u.username AS c4,"
				+ " o.order_number AS c5, ot.uuid AS c6, COALESCE(s.name, d.name, li.price_name) AS c7,"
				+ " li.price * li.quantity AS c8, b.receipt_number AS c9, b.status AS c10,"
				+ " TRIM(CONCAT(COALESCE(pn.given_name, ''), ' ', COALESCE(pn.family_name, ''))) AS c11,"
				+ " pi.identifier AS c12, p.uuid AS c13"
				+ " FROM hgest_derogation_paiement dg"
				+ " JOIN orders o ON o.order_id = dg.order_id"
				+ " JOIN order_type ot ON ot.order_type_id = o.order_type_id"
				+ " JOIN person p ON p.person_id = o.patient_id"
				+ " JOIN users u ON u.user_id = dg.creator"
				+ " LEFT JOIN person_name upn ON upn.person_id = u.person_id AND upn.voided = 0 AND upn.preferred = 1"
				+ " LEFT JOIN person_name pn ON pn.person_id = o.patient_id AND pn.voided = 0 AND pn.preferred = 1"
				+ " LEFT JOIN patient_identifier pi ON pi.patient_id = o.patient_id AND pi.voided = 0 AND pi.preferred = 1"
				+ " LEFT JOIN cashier_bill_line_item li ON li.bill_line_item_id = (SELECT MAX(li2.bill_line_item_id)"
				+ "   FROM cashier_bill_line_item li2 WHERE li2.order_id = o.order_id AND li2.voided = 0)"
				+ " LEFT JOIN cashier_bill b ON b.bill_id = li.bill_id"
				+ " LEFT JOIN cashier_billable_service s ON s.service_id = li.service_id"
				+ " LEFT JOIN drug_order dro ON dro.order_id = o.order_id"
				+ " LEFT JOIN drug d ON d.drug_id = dro.drug_inventory_id"
				+ " WHERE dg.voided = 0 AND dg.date_created >= DATE_SUB(NOW(), INTERVAL :jours DAY)"
				+ " ORDER BY dg.date_created DESC", "jours", Math.max(1, Math.min(jours, 366)));
		List<Map<String, Object>> resultat = new ArrayList<>();
		for (Object ligne : lignes) {
			Object[] r = (Object[]) ligne;
			Map<String, Object> m = new LinkedHashMap<>();
			m.put("uuid", r[0]);
			m.put("date", date(r[1]));
			m.put("motif", r[2]);
			m.put("accordee_par", StringUtils.defaultIfBlank((String) r[3], (String) r[4]));
			m.put("numero", r[5]);
			m.put("type", TYPE_EXAMEN.equals(r[6]) ? "Examen" : "Médicament");
			m.put("acte", r[7]);
			m.put("montant", r[8]);
			m.put("facture", r[9]);
			m.put("statut_facture", r[10]);
			m.put("patient", r[11]);
			m.put("dossier", r[12]);
			m.put("patient_uuid", r[13]);
			resultat.add(m);
		}
		return resultat;
	}

	// ------------------------------------------------------------------ outils

	boolean controleActif() {
		String v = Context.getAdministrationService().getGlobalProperty(GP_ACTIF, "true");
		return "true".equalsIgnoreCase(StringUtils.trimToEmpty(v));
	}

	private Set<String> liste(String gp) {
		String v = Context.getAdministrationService().getGlobalProperty(gp, "");
		return Arrays.stream(StringUtils.defaultString(v).split(","))
				.map(String::trim)
				.filter(StringUtils::isNotEmpty)
				.collect(Collectors.toSet());
	}

	private List<?> sql(String requete, Object... parametres) {
		org.hibernate.SQLQuery q = dbSessionFactory.getCurrentSession().createSQLQuery(requete);
		for (int i = 0; i + 1 < parametres.length; i += 2) {
			q.setParameter((String) parametres[i], parametres[i + 1]);
		}
		return q.list();
	}

	/** Date « AAAA-MM-JJ HH:MM » (heure du serveur), ou null. */
	static String date(Object valeur) {
		return valeur instanceof Date ? new SimpleDateFormat("yyyy-MM-dd HH:mm").format((Date) valeur) : null;
	}

	static String formatFcfa(BigDecimal montant) {
		DecimalFormatSymbols symboles = new DecimalFormatSymbols(Locale.FRANCE);
		symboles.setGroupingSeparator(' ');
		DecimalFormat f = new DecimalFormat("#,##0", symboles);
		return f.format(montant == null ? BigDecimal.ZERO : montant) + " FCFA";
	}
}
