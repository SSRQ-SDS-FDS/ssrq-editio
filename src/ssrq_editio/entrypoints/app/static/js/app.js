// External imports
import Alpine from 'alpinejs';
import 'htmx.org';

// Internal imports
import langSwitch from './components/langSwitch.js';
import dateRange from './components/dateRangeSlider.js';
import inputSync from './components/inputSync.js';
import tabs from './components/tabs.js';
import topButtonScrollHandler from './components/toTop.js';
import { removeEmptyParameters } from './utils/eventHelpers.js';

// Global setup of event listeners and Alpine-components
Alpine.data('dateRangeSlider', dateRange);
Alpine.data('inputSync', inputSync);
Alpine.data('langSwitch', langSwitch);
Alpine.data('tabs', tabs);
Alpine.data('topButtonScrollHandler', topButtonScrollHandler);
document.addEventListener('htmx:configRequest', removeEmptyParameters);
// Start Alpine.js
Alpine.start();
