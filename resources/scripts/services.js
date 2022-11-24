function insertTooltipFromApi(context, eventListener) {
  var key = $(context).attr('data-ref');
  var label = $(context).text();

  function filterSpan(i, span) {
    var ref = $(span).attr('data-ref');
    return ref === key || /^[\.a-zA-Z]/.test(ref.substring(key.length));
  }

  var scribes = $(".scribe[data-ref^='" + key + "']").filter(filterSpan);
  var refs = $(".ref[data-ref^='" + key + "']").filter(filterSpan);
  scribes.text(label);
  refs.text(label);

  if (eventListener) {
    $(context)
      .find('.select-facet')
      .on('change', function () {
        if (this.checked) {
          refs.parents('.reference').addClass('highlight');
        } else {
          refs.parents('.reference').removeClass('highlight');
        }
      });
  }
}

$(document).ready(function () {
  const root = document.documentElement.dataset.app;
  const context = new URL(location.href);
  let docId = (context.origin + context.pathname)
    .split(root)[1]
    .replace(/^\//, '')
    .replace(/\.html$/, '')
    .replace(/\/+/g, '-');
  docId = docId.startsWith('temp-') ? docId.replace('temp-', '') : docId;
  const apiUrl = `${root}/api/facets?doc=${docId}${
    context.searchParams.has('lang') &&
    ['de', 'en', 'fr', 'it'].some(
      (lang) => lang === context.searchParams.get('lang')
    )
      ? `&lang=${context.searchParams.get('lang')}`
      : ''
  }`;
  const aside = $('#aside');
  if (aside.length) {
    aside.load(apiUrl, function () {
      aside.find('li').each(function () {
        insertTooltipFromApi(this, true);
      });
    });
  } else {
    $.ajax({
      url: apiUrl,
      success: function (response) {
        $(response)
          .find('li')
          .each(function () {
            insertTooltipFromApi(this, aside.length > 0);
          });
      },
    });
  }

  $('.reference span[data-url]').click(function (ev) {
    window.open($(this).attr('data-url'), 'ssrq.references');
  });
});
