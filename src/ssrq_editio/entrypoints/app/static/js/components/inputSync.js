/**
 * Creates an AlpineJS component for synchronizing input values between two elements
 * @param {string} target - CSS selector for the target input element to sync with
 * @returns {Object} AlpineJS component object with init and sync methods
 */
const inputSync = function (target) {
  return {
    /** @type {HTMLInputElement|null} The target input element to sync with */
    syncTarget: null,

    /**
     * Initialize the component and find the target element
     * Sets up the syncTarget if a valid input element is found
     */
    init() {
      const inputTarget = document.querySelector(target);
      if (inputTarget !== null && inputTarget instanceof HTMLInputElement) {
        this.syncTarget = inputTarget;
      }
    },

    /**
     * Synchronizes the current element's value with the target element
     * Only syncs if syncTarget is a valid input element
     */
    sync() {
      if (this.syncTarget !== null) {
        this.syncTarget.value = this.$el.value;
      }
    },
  };
};

export default inputSync;
