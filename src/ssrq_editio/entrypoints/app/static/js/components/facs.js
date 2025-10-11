import OpenSeadragon from 'openseadragon';

const createFacsViewer = (tileSources) => {
  /*
    ToDo:
        - Replace default icons
        - Switch image if needed
  */
  const viewerOptions = {
    // Element used to place the viewer in
    id: 'img-container',
    // Options to control the loading of images
    tileSources: tileSources,
    crossOriginPolicy: true,
    // Viewer options
    sequenceMode: true,
    preserveViewport: true,
    visibilityRatio: 1,
    minZoomLevel: 1,
    defaultZoomLevel: 1,
    autoHideControls: false,
    // Icon options
    prefixUrl:
      'https://cdn.jsdelivr.net/gh/Benomrans/openseadragon-icons@main/images/',
  };
  return OpenSeadragon(viewerOptions);
};

document.addEventListener('ssrq:facsviewer', (e) => {
  createFacsViewer(e.detail.tileSources);
});
