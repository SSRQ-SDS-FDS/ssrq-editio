// Select elements

const tocAnchors = document.querySelectorAll('.toc-anchor');
const toTopButton = document.querySelector('.to-top-button');
const toc = document.querySelector('#toc');
const svgs = document.querySelectorAll('.svg-container svg');

// Callback-functions
const clickHandler = (e) => {
  e.preventDefault();
  const href = e.target.getAttribute('href');
  const offsetTop = document.querySelector(href).offsetTop;
  scroll({
    top: offsetTop + window.innerHeight / 2,
    behavior: 'smooth',
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
    svgPanZoom(`#${id}`, {
      zoomEnabled: true,
      controlIconsEnabled: true,
      fit: true,
    });
  });
}
