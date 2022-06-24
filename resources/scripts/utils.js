// Select elements

const tocAnchors = document.querySelectorAll('.toc-anchor');
const toTopButton = document.querySelector('.to-top-button');
const toc = document.querySelector('#toc');
const svgs = document.querySelectorAll('.svg-container svg');

// Callback-functions
const clickHandler = (e) => {
  e.preventDefault();
  const href = e.target.getAttribute('href');
  const target = document.getElementById(href.split('#').pop());
  const offSet = target.offsetTop + window.innerHeight / 4;
  scroll({
    target,
    behavior: 'smooth',
    top: offSet,
  });
};

const handleScroll = (entries, observer) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      toTopButton.classList.remove('is-active');
    } else {
      toTopButton.classList.add('is-active');
    }
  });
};

// Event-listeners
if (tocAnchors) {
  for (const link of tocAnchors) {
    link.addEventListener('click', clickHandler);
  }
}

if (toc) {
  let observer = new IntersectionObserver(handleScroll);
  observer.observe(toc);
  toTopButton.addEventListener('click', (e) => {
    e.preventDefault();
    scroll({
      top: 0,
      behavior: 'smooth',
    });
  });
}

if (svgs) {
  svgs.forEach((svg, index) => {
    const id = `svg-${index}`;
    svg.id = id;
    let panZoom = svgPanZoom(`#${id}`, {
      controlIconsEnabled: true,
    });
    window.addEventListener('resize', () => {
      panZoom.resize();
      panZoom.contain();
      panZoom.center();
    });
  });
}
