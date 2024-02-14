import "https://cdn.jsdelivr.net/npm/svg-pan-zoom@3.5.0/dist/svg-pan-zoom.min.js";

document.addEventListener("DOMContentLoaded", function () {
  // Select elements
  const tocAnchors = document.querySelectorAll(".toc-anchor");
  const svgs = document.querySelectorAll(".svg-container svg");

  // Callback-function for toc-anchors
  const clickHandler = (e) => {
    e.preventDefault();
    const href = e.target.getAttribute("href");
    const target = document.getElementById(href.split("#").pop());
    const offSet = target.offsetTop + window.innerHeight / 4;
    scroll({
      target,
      behavior: "smooth",
      top: offSet,
    });
  };

  // Event-listener
  if (tocAnchors) {
    for (const link of tocAnchors) {
      link.addEventListener("click", clickHandler);
    }
  }

  if (svgs) {
    svgs.forEach((svg, index) => {
      const id = `svg-${index}`;
      svg.id = id;
      let panZoom = svgPanZoom(`#${id}`, {
        controlIconsEnabled: true,
      });
      window.addEventListener("resize", () => {
        panZoom.resize();
        panZoom.contain();
        panZoom.center();
      });
    });
  }
});
