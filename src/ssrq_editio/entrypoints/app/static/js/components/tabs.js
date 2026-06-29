const tabs = function () {
  return {
    tabGroup: null,

    setup(activeTab = null, tabGroup = null) {
      if (!tabGroup) { throw new Error('Missing tab group.') }
      this.tabGroup = tabGroup;

      if (activeTab !== null) {
        this.$store.ssrqDocument.setActiveTab(this.tabGroup, activeTab);
        return;
      }
      // Set the first tab as default
      // if no activeTab is provided
      const el = this.$el;
      const firstTab = el.querySelector('template');
      if (firstTab !== null) {
        this.$store.ssrqDocument.setActiveTab(this.tabGroup, firstTab.ariaLabel);
      }
    },

    setActiveTab(tabName) {
      if (!tabName) { throw new Error('Missing tab name.') }

      this.$store.ssrqDocument.setActiveTab(this.tabGroup, tabName);
    },

    getActiveTab() {
      return this.$store.ssrqDocument.getActiveTab(this.tabGroup);
    },
  };
};

export default tabs;
