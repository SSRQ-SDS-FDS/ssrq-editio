// Select elements

const tocAnchors = document.querySelectorAll('.toc-anchor');
const toTopButton = document.querySelector('.to-top-button');
const toc = document.querySelector('#toc');
const svgs = document.querySelectorAll('.svg-container svg');
const persons = document.querySelectorAll('span.person span[data-url]');

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

const fetchInsertPersons = async (root, doc) => {
  try {
    const request = await fetch(`${root}/api/persons?doc=${doc}`);
    const data = await request.json();
    insertPersonTooltip(data);
  } catch (error) {
    console.log(`Failed to fetch the Persons-API; ${error}`);
  }
};

const insertPersonTooltip = (data) => {
  persons.forEach((person) => {
    const id = person.dataset.url.split('=')[1];
    if (id.length > 0) {
      const entry = data.filter(
        (item) => item.id === id || item.name === person.innerText
      )[0];
      if (entry) {
        person.parentNode.nextSibling.insertAdjacentHTML(
          'beforeend',
          `${entry.name} (${entry.dates})`
        );
      }
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

if (persons.length > 0) {
  const root = document.documentElement.dataset.app;
  const docId = (location.origin + location.pathname)
    .substring(root.length + 1)
    .replace(/\.html\/?/, '')
    .split('/')
    .join('-');
  fetchInsertPersons(root, docId);
}
