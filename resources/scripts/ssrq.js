const cantonlist = document.getElementById('cantonlist');

if (cantonlist) {
  cantonlist.addEventListener('click', (e) => {
    if (e.target.tagName.toLowerCase() === 'a') {
      e.preventDefault();
      e.stopPropagation();
      const url = new URL(window.location.href);
      url.searchParams.set('collection', e.target.dataset.collection);
      window.location.href = url.href;
    }
  });
}
