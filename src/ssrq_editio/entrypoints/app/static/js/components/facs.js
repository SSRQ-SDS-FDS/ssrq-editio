import OpenSeadragon from 'openseadragon';

function createSSRQViewer() {
  let viewer = null;
  let tileSources = [];
  let currentPageIndex = 0;
  let nextFacsOnInit = null;

  function init() {
    document.addEventListener('ssrq:facsviewer', (e) => {
      tileSources = e.detail.tileSources;
      if (viewer) {
        viewer.destroy();
      }
      viewer = createFacsViewer();
      setupPageCounter('#viewerCurrentPage', e.detail.tileSources.length);

      // if facs is changed while viewer is not initalized
      if (nextFacsOnInit) {
        goToFacs(nextFacsOnInit);
        nextFacsOnInit = null;
      }
    });
  }

  function createFacsViewer() {
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
      autoHideControls: false,
      showRotationControl: true,
      rotationIncrement: 90,
      // Icon options
      zoomInButton: 'viewerZoomIn',
      zoomOutButton: 'viewerZoomOut',
      rotateLeftButton: 'viewerRotateCCW',
      rotateRightButton: 'viewerRotateCW',
      homeButton: 'viewerHome',
      fullPageButton: 'viewerFull',
      previousButton: 'viewerPrev',
      nextButton: 'viewerNext',
    };
    const facsViewer = OpenSeadragon(viewerOptions);
    facsViewer.addHandler('open', () => {
      // Keep the entire IIIF image visible at the lowest zoom level, regardless of its
      // dimensions relative to the viewer container.
      const fitZoom = facsViewer.viewport.getHomeZoom();
      facsViewer.viewport.setMinZoomLevel = fitZoom;
      facsViewer.viewport.goHome(true);
    });
    return facsViewer;
  }

  function setupPageCounter(containerId, totalPages) {
    const container = document.querySelector(containerId);

    if (!container) {
      console.error(`Container for page counter not found: ${containerId}`);
      return;
    }

    currentPageIndex = 0;
    container.textContent = `1|${totalPages}`;
    viewer.addHandler('page', (data) => {
      currentPageIndex = data.page;
      container.textContent = `${currentPageIndex + 1}|${totalPages}`;
    });
  }

  function goToFacs(facsName) {
    if (!viewer || tileSources.length === 0) {
      nextFacsOnInit = facsName;
      return;
    }

    const newPageIndex = indexOfImageByName(facsName);
    if (newPageIndex > -1 && newPageIndex !== currentPageIndex) {
      viewer.goToPage(newPageIndex);
    }
  }
  function indexOfImageByName(imgName) {
    const imgIndex = tileSources.findIndex((item) => item.includes(imgName));
    if (imgIndex === -1) {
      console.error(
        `Couldn't find image with name '${imgName}' in dataset ${tileSources}`,
      );
    }
    return imgIndex;
  }
  return {
    init,
    goToFacs,
  };
}

export default createSSRQViewer;
