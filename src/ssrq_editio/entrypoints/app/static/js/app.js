// External imports
import 'https://cdn.jsdelivr.net/npm/alpinejs@3.13.5/dist/cdn.min.js';
import 'https://unpkg.com/htmx.org@2.0.0/dist/htmx.min.js';

// Internal imports
import langSwitch from './components/langSwitch.js';
import topButtonScrollHandler from './components/toTop.js';
import { removeEmptyParameters } from './utils/eventHelpers.js';

// Global setup of event listeners
Alpine.data('langSwitch', langSwitch);
Alpine.data('topButtonScrollHandler', topButtonScrollHandler);
document.addEventListener('htmx:configRequest', removeEmptyParameters);
