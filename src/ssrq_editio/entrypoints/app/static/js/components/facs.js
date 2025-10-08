import OpenSeadragon from 'openseadragon';

const createFacsViewer = (tileSources) => {
  /*
    ToDo:
        - Find Image to display
        - Replace default icons
        - Switch image if needed
  */
  const viewerOptions = {
    id: 'img-container',
    prefixUrl:
      'https://cdnjs.cloudflare.com/ajax/libs/openseadragon/4.1.0/images/',
    tileSources: tileSources,
    preserveViewport: true,
    sequenceMode: true,
    showZoomControl: true,
    showHomeControl: true,
    showFullPageControl: true,
    //showNavigator: true,
    autoHideControls: false,
    visibilityRatio: 1,
    minZoomLevel: 1,
    defaultZoomLevel: 1,
  };
  const viewer = OpenSeadragon(viewerOptions);
};

document.addEventListener('ssrq:facsviewer', (e) => {
  createFacsViewer(e.detail.tileSources);
});
