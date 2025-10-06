/**
 * Creates an AlpineJS component for synchronizing input values between two elements
 * @param {string} target - CSS selector for the target input element to sync with
 * @param {boolean} [dispatch=false] - Whether to dispatch an 'input' event on the target element after syncing
 * @returns {Object} AlpineJS component object with init and sync methods
 */
const inputSync = function (target, dispatch = false) {
  return {
    /** @type {HTMLInputElement|null} The target input element to sync with */
    syncTarget: null,
    dispatchEventOnTarget: true,

    /**
     * Initialize the component and find the target element
     * Sets up the syncTarget if a valid input element is found
     */
    init() {
      const inputTarget = document.querySelector(target);
      if (inputTarget !== null && inputTarget instanceof HTMLInputElement) {
        this.syncTarget = inputTarget;
        this.dispatchEventOnTarget = dispatch;
      }
    },

    /**
     * Synchronizes the current element's value with the target element
     * Only syncs if syncTarget is a valid input element
     */
    sync() {
      if (this.syncTarget !== null) {
        this.syncTarget.value = this.$el.value;

        if (this.dispatchEventOnTarget) {
          this.syncTarget.dispatchEvent(new Event('input'));
        }
      }
    },
  };
};

export default inputSync;
