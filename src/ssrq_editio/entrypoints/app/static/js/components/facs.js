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
    zoomInButton:  'viewerZoomIn',
    zoomOutButton: 'viewerZoomOut',
    homeButton:    'viewerHome',
    fullPageButton:'viewerFull',
    previousButton: 'viewerPrev',
    nextButton: 'viewerNext'
  };
  return OpenSeadragon(viewerOptions);
};

document.addEventListener('ssrq:facsviewer', (e) => {
  const viewer = createFacsViewer(e.detail.tileSources);
  document.getElementById("viewerCurrentPage").innerHTML = `1|${e.detail.tileSources.length}`;
  viewer.addHandler("page", function(data){
    document.getElementById("viewerCurrentPage").innerHTML = `${data.page + 1}|${e.detail.tileSources.length}`;
  });
});
