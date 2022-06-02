$(document).ready(function () {
  const root = document.documentElement.dataset.app;
  const docId = location.href
    .substring(root.length + 1)
    .replace(/\.html\/?/, '')
    .split('/')
    .join('-');
  const aside = $('#aside');
  aside.load(root + '/api/facets?doc=' + docId, function () {
    aside.find('li').each(function () {
      var key = $(this).attr('data-ref');
      var label = $(this).text();

      function filterSpan(i, span) {
        var ref = $(span).attr('data-ref');
        if (ref === key) {
          return true;
        }
        return /^[\.a-zA-Z]/.test(ref.substring(key.length));
      }

      var scribes = $(".scribe[data-ref^='" + key + "']").filter(filterSpan);
      var refs = $(".ref[data-ref^='" + key + "']").filter(filterSpan);
      scribes.text(label);
      refs.text(label);
      $(this)
        .find('.select-facet')
        .on('change', function () {
          if (this.checked) {
            refs.parents('.reference').addClass('highlight');
          } else {
            refs.parents('.reference').removeClass('highlight');
          }
        });
    });
  });

  $('.reference span[data-url]').click(function (ev) {
    window.open($(this).attr('data-url'), 'ssrq.references');
  });
});
