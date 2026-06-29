const ssrqDocumentStore = (facsViewer) => ({
  activeTabs: {
    transcriptCol: null,
    metadataCol: null,
  },
  metadataOpen: true,
  popupMarkerVisible: true,
  
  init() {
    /* ToDo: load/save current gui state in sessionStorage/URL parameter */

    document.addEventListener('click', (e) => {
      const buttonElement = e.target.closest('button.tei-pb[data-facs]');
      if(!buttonElement){ return; }
      this.openFacs(buttonElement.dataset.facs);
    });
  },

  openFacs(facsName){
    this.metadataOpen = true;
    this.setActiveTab('metadataCol', 'digital_copy');
    requestAnimationFrame(() => {
      facsViewer.goToFacs(facsName);
    });
  },

  toggleMetadata() {
    this.metadataOpen = !this.metadataOpen;
  },

  togglePopupMarker() {
    this.popupMarkerVisible =  !this.popupMarkerVisible;
  },

  getActiveTab(tabGroup){
    return this.activeTabs[tabGroup];
  },

  setActiveTab(tabGroup, tabName){
    this.activeTabs[tabGroup] = tabName;

  },
});

export default ssrqDocumentStore;
