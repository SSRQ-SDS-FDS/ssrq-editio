const tabs = function () {
  return {
    activeTab: null,

    init(activeTab = null) {
      if (activeTab !== null) {
        this.activeTab = activeTab;
        return;
      }
      // Set the first tab as default
      // if no activeTab is provided
      const el = this.$el;
      const firstTab = el.querySelector('template');
      if (firstTab !== null) {
        this.activeTab = firstTab.ariaLabel;
      }
    },

    switchTab(tabName) {
      this.activeTab = tabName;
    },
  };
};

export default tabs;
