package org.openmrs.module.hgest.paiement;

import org.aopalliance.aop.Advice;
import org.openmrs.module.fhir2.api.FhirMedicationDispenseService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.aop.Advisor;
import org.springframework.aop.framework.Advised;
import org.springframework.aop.framework.ProxyFactory;
import org.springframework.beans.factory.config.BeanPostProcessor;

/**
 * Le service FHIR MedicationDispense enregistre directement en base (pas via MedicationDispenseService),
 * donc un « advice » OpenMRS classique ne le voit pas. On ajoute le contrôle de paiement au proxy Spring
 * du service au moment où il est créé.
 */
public class ControleDispensationPostProcessor implements BeanPostProcessor {

	private static final Logger log = LoggerFactory.getLogger(ControleDispensationPostProcessor.class);

	@Override
	public Object postProcessAfterInitialization(Object bean, String beanName) {
		if (!(bean instanceof FhirMedicationDispenseService)) {
			return bean;
		}
		if (bean instanceof Advised && !((Advised) bean).isFrozen()) {
			Advised advised = (Advised) bean;
			for (Advisor advisor : advised.getAdvisors()) {
				Advice advice = advisor.getAdvice();
				if (advice != null && advice.getClass().getName().equals(ControleDispensationInterceptor.class.getName())) {
					return bean;
				}
			}
			advised.addAdvice(new ControleDispensationInterceptor());
			log.info("Contrôle du paiement ajouté au service FHIR MedicationDispense ({})", beanName);
			return bean;
		}
		ProxyFactory proxy = new ProxyFactory(bean);
		proxy.addInterface(FhirMedicationDispenseService.class);
		proxy.addAdvice(new ControleDispensationInterceptor());
		log.info("Contrôle du paiement ajouté au service FHIR MedicationDispense ({}, nouveau proxy)", beanName);
		return proxy.getProxy(bean.getClass().getClassLoader());
	}
}
