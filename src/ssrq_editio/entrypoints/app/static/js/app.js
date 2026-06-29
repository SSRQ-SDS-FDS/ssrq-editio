// External imports
import Alpine from 'alpinejs';
import 'htmx.org';

// Internal imports
import langSwitch from './components/langSwitch.js';
import createSSRQViewer from './components/facs.js';
import dateRange from './components/dateRangeSlider.js';
import inputSync from './components/inputSync.js';
import initPbSpacing from './components/pbSpacing.js';
import tabs from './components/tabs.js';
import topButtonScrollHandler from './components/toTop.js';
import popup from './components/popup.js';
import { removeEmptyParameters } from './utils/eventHelpers.js';

import ssrqDocumentStore from './stores/document.js';

// Global setup of event listeners and Alpine-components
const ssrqViewer = createSSRQViewer();
ssrqViewer.init();
initPbSpacing();

Alpine.store('ssrqDocument', ssrqDocumentStore(ssrqViewer));
Alpine.data('dateRangeSlider', dateRange);
Alpine.data('inputSync', inputSync);
Alpine.data('langSwitch', langSwitch);
Alpine.data('tabs', tabs);
Alpine.data('topButtonScrollHandler', topButtonScrollHandler);
Alpine.data('popup', popup);
document.addEventListener('htmx:configRequest', removeEmptyParameters);
// Start Alpine.js
Alpine.start();
