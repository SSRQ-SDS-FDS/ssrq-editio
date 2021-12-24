$(document).ready(function () {
  var aside = $('#aside');
  var root = $(document.documentElement).attr('data-app');
  var docPath = location.pathname.substr(root.length + 1);
  var pathArray = location.pathname.split('/');
  aside.load(
    'templates/facets.html?doc=' +
      docPath +
      '&id=' +
      pathArray[pathArray.length - 1].split('.')[0],
    function () {
      var lang = $('#lang-select').val();
      var colon = lang === 'fr' ? ' : ' : ': ';
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
    }
  );

  $('.reference span[data-url]').click(function (ev) {
    window.open($(this).attr('data-url'), 'ssrq.references');
  });
});
