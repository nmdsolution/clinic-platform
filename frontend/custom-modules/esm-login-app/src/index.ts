import { defineConfigSchema, getSyncLifecycle } from '@openmrs/esm-framework';
import { configSchema } from './config-schema';
import changeLocationLinkComponent from './change-location-link/change-location-link.extension';
import changePasswordLinkComponent from './change-password/change-password-link.extension';
import changePasswordModalComponent from './change-password/change-password.modal';
import locationPickerComponent from './location-picker/location-picker-view.component';
import logoutButtonComponent from './logout/logout.extension';
import rootComponent from './root.component';

// Same package name the app shell already expects for the "login" page (see routes.json) -
// this fork replaces the module the import map points at, it doesn't add a new route.
const moduleName = '@openmrs/esm-login-app';

const options = {
  featureName: 'login',
  moduleName,
};

export function startupApp() {
  defineConfigSchema(moduleName, configSchema);
}

export const root = getSyncLifecycle(rootComponent, options);
export const locationPicker = getSyncLifecycle(locationPickerComponent, options);
export const logoutButton = getSyncLifecycle(logoutButtonComponent, options);
export const changeLocationLink = getSyncLifecycle(changeLocationLinkComponent, options);
export const changePasswordLink = getSyncLifecycle(changePasswordLinkComponent, options);
export const changePasswordModal = getSyncLifecycle(changePasswordModalComponent, options);
