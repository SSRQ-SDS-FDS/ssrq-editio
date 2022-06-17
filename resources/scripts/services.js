function insertTooltipFromApi(context, eventListener) {
  var key = $(context).attr('data-ref');
  var label = $(context).text();

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

  if (eventListener) {
    $(context)
      .find('.select-facet')
      .on('change', function () {
        if (context.checked) {
          refs.parents('.reference').addClass('highlight');
        } else {
          refs.parents('.reference').removeClass('highlight');
        }
      });
  }
}

$(document).ready(function () {
  const root = document.documentElement.dataset.app;
  const docId = (location.origin + location.pathname)
    .substring(root.length + 1)
    .replace(/\.html\/?/, '')
    .split('/')
    .join('-');
  const apiUrl = `${root}/api/facets?doc=${docId}`;
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
            insertTooltipFromApi(this, false);
          });
      },
    });
  }

  $('.reference span[data-url]').click(function (ev) {
    window.open($(this).attr('data-url'), 'ssrq.references');
  });
});
