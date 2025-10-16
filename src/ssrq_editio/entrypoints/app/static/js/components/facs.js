import OpenSeadragon from 'openseadragon';

const createFacsViewer = (tileSources) => {
  /*
    ToDo:
        - Switch image if needed automatically when changing page
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
    zoomInButton: 'viewerZoomIn',
    zoomOutButton: 'viewerZoomOut',
    homeButton: 'viewerHome',
    fullPageButton: 'viewerFull',
    previousButton: 'viewerPrev',
    nextButton: 'viewerNext',
  };
  return OpenSeadragon(viewerOptions);
};

const setupPageCounter = (viewer, containerId, totalPages) => {
  const container = document.querySelector(containerId);

  if (!container) {
    console.error(`Container for page counter not found: ${containerId}`);
    return;
  }

  container.innerHTML = `1|${totalPages}`;
  viewer.addHandler('page', function (data) {
    container.innerHTML = `${data.page + 1}|${totalPages}`;
  });
};

document.addEventListener('ssrq:facsviewer', (e) => {
  const viewer = createFacsViewer(e.detail.tileSources);
  setupPageCounter(viewer, '#viewerCurrentPage', e.detail.tileSources.length);
});
