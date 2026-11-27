package org.openmrs.module.hgest.paiement;

import java.lang.reflect.Method;

import org.openmrs.Order;
import org.openmrs.TestOrder;
import org.openmrs.api.db.hibernate.HibernateUtil;
import org.springframework.aop.MethodBeforeAdvice;

/**
 * Laboratoire : le module labo passe la prescription « en cours » au prélèvement et « terminée » à la
 * validation (POST order/{uuid}/fulfillerdetails → OrderService.updateOrderFulfillerStatus).
 * Les deux sont refusés si l'examen n'est pas payé.
 */
public class ControleLaboAdvice implements MethodBeforeAdvice {

	@Override
	public void before(Method method, Object[] args, Object target) {
		if (!"updateOrderFulfillerStatus".equals(method.getName()) || args == null || args.length < 2
				|| !(args[0] instanceof Order)) {
			return;
		}
		Object statut = args[1];
		String action;
		if (statut == Order.FulfillerStatus.IN_PROGRESS) {
			action = "Prélèvement";
		} else if (statut == Order.FulfillerStatus.COMPLETED) {
			action = "Validation du résultat";
		} else {
			return;
		}
		Object order = HibernateUtil.getRealObjectFromProxy(args[0]);
		if (order instanceof TestOrder) {
			ControlePaiement.get().verifier((Order) order, action);
		}
	}
}
