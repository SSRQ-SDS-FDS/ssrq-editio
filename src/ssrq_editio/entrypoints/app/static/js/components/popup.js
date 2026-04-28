/**
 * Creates an Alpine.js popup component.
 *
 * The component links trigger + popover and keeps viewport listeners lazy:
 * listeners are attached only while the popover is open, and removed again
 * as soon as it closes.
 *
 * @returns {object} Alpine.js popup component state and methods
 */
const popup = function () {
  return {
    /** @type {HTMLButtonElement|null} */
    trigger: null,
    /** @type {HTMLElement|null} */
    popupBody: null,
    /** @type {HTMLElement[]} */
    scrollParents: [],
    /** @type {(() => void)|null} */
    viewportChangeHandler: null,
    /** @type {((event: ToggleEvent) => void)|null} */
    beforeToggleHandler: null,
    /** @type {((event: ToggleEvent) => void)|null} */
    toggleHandler: null,
    /** @type {boolean} */
    viewportListenersActive: false,

    /**
     * Returns true when both trigger and popup are available.
     *
     * @returns {boolean}
     */
    hasRequiredElements() {
      return this.trigger instanceof HTMLButtonElement && this.popupBody instanceof HTMLElement;
    },

    /**
     * Finds and stores trigger and popup nodes inside the current component.
     */
    cacheElements() {
      this.trigger = this.$el.querySelector('button');
      this.popupBody = this.$el.querySelector('.popup-body');
    },

    /**
     * Connects trigger and popup using the Popover API.
     */
    wirePopoverTarget() {
      this.trigger.popoverTargetElement = this.popupBody;
    },

    /**
     * Stores scrollable ancestors used as clipping/visibility boundaries.
     */
    cacheScrollParents() {
      this.scrollParents = this.getScrollParents(this.trigger);
    },

    /**
     * Closes an open popup to avoid detached-looking overlays while scrolling.
     */
    onViewportChange() {
      if (this.popupBody !== null && this.popupBody.matches(':popover-open')) {
        if (!this.isTriggerVisible()) {
          this.popupBody.hidePopover();
        }
      }
    },

    /**
     * Checks if a rectangle intersects the browser viewport.
     *
     * @param {DOMRect} rect - Element rectangle
     * @returns {boolean} True if visible in the viewport
     */
    isRectVisibleInViewport(rect) {
      return rect.bottom > 0
        && rect.right > 0
        && rect.top < window.innerHeight
        && rect.left < window.innerWidth;
    },

    /**
     * Checks if two rectangles intersect each other.
     *
     * @param {DOMRect} elementRect - Rectangle of the anchor element
     * @param {DOMRect} containerRect - Rectangle of a clipping container
     * @returns {boolean} True if both rectangles overlap
     */
    isRectVisibleInElement(elementRect, containerRect) {
      return elementRect.bottom > containerRect.top
        && elementRect.top < containerRect.bottom
        && elementRect.right > containerRect.left
        && elementRect.left < containerRect.right;
    },

    /**
     * Checks whether the popup trigger is still visible in viewport and all
     * scrollable clipping parents.
     *
     * @returns {boolean} True when trigger remains visible
     */
    isTriggerVisible() {
      if (!(this.trigger instanceof HTMLButtonElement)) {
        return false;
      }

      const triggerRect = this.trigger.getBoundingClientRect();
      if (!this.isRectVisibleInViewport(triggerRect)) {
        return false;
      }

      for (const parent of this.scrollParents) {
        const parentRect = parent.getBoundingClientRect();
        if (!this.isRectVisibleInElement(triggerRect, parentRect)) {
          return false;
        }
      }
      return true;
    },

    /**
     * Adds viewport listeners used while popover is open.
     */
    addViewportListeners() {
      if (this.viewportChangeHandler === null || this.viewportListenersActive) {
        return;
      }

      for (const parent of this.scrollParents) {
        parent.addEventListener('scroll', this.viewportChangeHandler, { passive: true });
      }
      window.addEventListener('scroll', this.viewportChangeHandler, { passive: true });
      window.addEventListener('resize', this.viewportChangeHandler, { passive: true });
      this.viewportListenersActive = true;
    },

    /**
     * Removes viewport listeners when popover is closed.
     */
    removeViewportListeners() {
      if (this.viewportChangeHandler === null || !this.viewportListenersActive) {
        return;
      }

      for (const parent of this.scrollParents) {
        parent.removeEventListener('scroll', this.viewportChangeHandler);
      }
      window.removeEventListener('scroll', this.viewportChangeHandler);
      window.removeEventListener('resize', this.viewportChangeHandler);
      this.viewportListenersActive = false;
    },

    /**
     * Attaches listeners for popover open/close transitions.
     *
     * `beforetoggle` is used so listeners are already active before the popup
     * becomes visible. `toggle` handles cleanup after close.
     */
    bindPopoverLifecycle() {
      this.beforeToggleHandler = (event) => {
        if (event.newState === 'open') {
          this.addViewportListeners();
        }
      };

      this.toggleHandler = (event) => {
        if (event.newState === 'closed') {
          this.removeViewportListeners();
        }
      };

      this.popupBody.addEventListener('beforetoggle', this.beforeToggleHandler);
      this.popupBody.addEventListener('toggle', this.toggleHandler);
    },

    /**
     * Removes listeners for popover lifecycle events.
     */
    unbindPopoverLifecycle() {
      if (this.beforeToggleHandler !== null) {
        this.popupBody.removeEventListener('beforetoggle', this.beforeToggleHandler);
      }
      if (this.toggleHandler !== null) {
        this.popupBody.removeEventListener('toggle', this.toggleHandler);
      }
    },

    /**
     * Returns scrollable ancestors of an element up to document root.
     *
     * @param {HTMLElement} element - Start element
     * @returns {HTMLElement[]} All scrollable ancestor elements
     */
    getScrollParents(element) {
      const parents = [];
      let current = element.parentElement;

      while (current !== null) {
        const style = window.getComputedStyle(current);
        const overflow = `${style.overflow}${style.overflowX}${style.overflowY}`;
        if (/(auto|scroll|overlay)/.test(overflow)) {
          parents.push(current);
        }
        current = current.parentElement;
      }
      return parents;
    },

    /**
     * Wires the first trigger button to the popup body within this component.
     */
    init() {
      this.cacheElements();
      if (!this.hasRequiredElements()) {
        return;
      }

      this.wirePopoverTarget();
      this.cacheScrollParents();
      this.viewportChangeHandler = this.onViewportChange.bind(this);
      this.bindPopoverLifecycle();
    },

    /**
     * Cleans up listeners when Alpine tears down the component.
     */
    destroy() {
      this.unbindPopoverLifecycle();
      this.removeViewportListeners();
    },
  };
};

export default popup;
