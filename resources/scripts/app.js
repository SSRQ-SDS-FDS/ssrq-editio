$(document).ready(function () {
  var historySupport = !!(window.history && window.history.pushState);
  var appRoot = $('html').data('app');
  var tableOfContents = false;

  var iiifApi = 'https://iiif.rechtsquellen.ch/iiif/2/';

  var seadragon;

  var facsimiles = [];
  var pagebreaks = [];

  // initialize seadragon for viewing facsimiles
  if (document.getElementById('image-container')) {
    console.log('Initializing seadragon...');
    seadragon = OpenSeadragon({
      id: 'image-container',
      prefixUrl: 'resources/scripts/vendor/images/',
      preserveViewport: true,
      sequenceMode: true,
      showZoomControl: true,
      showHomeControl: true,
      showFullPageControl: true,
      showNavigator: true,
      autoHideControls: false,
      visibilityRatio: 1,
      minZoomLevel: 1,
      defaultZoomLevel: 1,
    });
    seadragon.setControlsEnabled(true);
  }

  function viewFacsimile(pb) {
    var prev = pb.previousSibling;
    var facs;
    while (prev) {
      facs = $(prev).find('.facs');
      if (facs.length > 0) {
        break;
      }
      prev = prev.previousSibling;
    }
    var src = facs[0].getAttribute('data-facs');
    var pos = facsimiles.indexOf(iiifApi + src + '/info.json');
    if (seadragon.currentPage() !== pos) {
      seadragon.goToPage(pos);
    }
  }

  function resize() {}

  function getFontSize() {
    var size = $('#document-wrapper').css('font-size');
    return parseInt(size.replace(/^(\d+)px/, '$1'));
  }

  function initContent() {
    $('.content .note, #document-pane .note').each(initFootnote);
    $('.content .fn-back').click(function (ev) {
      ev.preventDefault();
      var offset = $('#main-wrapper').offset().top;
      var top = document.getElementById(this.hash.substring(1));
      top.scrollIntoView();
      var shiftWindow = function () {
        scrollBy(0, -offset);
      };
      setTimeout(shiftWindow, 1);
    });
    $('.content .alternate, .content .reference').each(initAlternate);
    if (document.getElementById('image-container')) {
      var foundFacs = {};
      facsimiles = [];
      $('#document-pane .facs').each(function () {
        var src = $(this).attr('data-facs');
        var url = iiifApi + src + '/info.json';
        if (!foundFacs[url]) {
          facsimiles.push(url);
          foundFacs[url] = url;
        }
        // seadragon.open(iiifApi + src + "/info.json");
      });
      seadragon.open(facsimiles);

      pagebreaks = [];
      $('.pb-pagination, .pb-foliation, .pb-empty')
        .each(function () {
          pagebreaks.push(this);
        })
        .on('mouseover', function (ev) {
          viewFacsimile(this);
        });
    }
  }

  function initAlternate() {
    var elem = $(this);
    elem.popover({
      content: function () {
        var content = [elem.children('.altcontent').html()];
        elem.parents('.alternate').each(function () {
          content.push($(this).children('.altcontent').html());
        });
        if (content.length > 1) {
          var list = '<ol>';
          for (var i = 0; i < content.length; i++) {
            list += '<li>' + content[i] + '</li>';
          }
          return list + '</ol>';
        }
        return content.join('');
      },
      trigger: 'manual',
      html: true,
      container: '#document-wrapper',
      viewport: '#document-pane',
      placement: 'auto top',
    });
    elem.on('mouseenter mouseover', function (ev) {
      ev.preventDefault();
      ev.stopPropagation();
      if (elem.data('bs.popover').tip().is(':visible')) {
        return;
      }
      elem.popover('show');
    });
    elem.on('mouseout', function (ev) {
      elem.popover('hide');
    });
  }

  function popupFixed() {
    var elem = $(this);
    elem.popover({
      content: function () {
        var content = [elem.children('.altcontent').html()];
        elem.parents('.alternate').each(function () {
          content.push($(this).children('.altcontent').html());
        });
        if (content.length > 1) {
          var list = '<ol>';
          for (var i = 0; i < content.length; i++) {
            list += '<li>' + content[i] + '</li>';
          }
          return list + '</ol>';
        }
        return content.join('');
      },
      trigger: 'click',
      html: true,
      container: '#idno',
      viewport: '#document-pane',
      placement: 'auto top',
    });
  }

  function initFootnote() {
    var elem = $(this);
    elem.popover({
      content: function () {
        var fn = document.getElementById(this.hash.substring(1));
        var content = $(fn).find('.fn-content').html();
        return content.replace(
          /<span .[^class]* class="note-wrap">.*<\/span>/,
          ''
        );
      },
      trigger: 'manual',
      html: true,
      placement: 'auto bottom',
      viewport: '#document-pane',
    });
    elem.on('mouseenter mouseover', function (ev) {
      ev.preventDefault();
      ev.stopPropagation();
      if (elem.data('bs.popover').tip().is(':visible')) {
        return;
      }
      elem.popover('show');
    });
    elem.on('mouseout', function (ev) {
      elem.popover('hide');
    });
    elem.on('click', function (ev) {
      ev.preventDefault();
      var offset = $('#main-wrapper').offset().top;
      var top = document.getElementById(this.hash.substring(1));
      top.scrollIntoView();
      var shiftWindow = function () {
        scrollBy(0, -offset);
      };
      setTimeout(shiftWindow, 1);
    });
  }

  function initLinks(ev) {
    ev && ev.preventDefault();
    // var relPath = this.pathname.replace(/^.*?\/([^\/]+)$/, "$1");
    var relPath = $(this).attr('data-doc');
    var url = 'doc=' + relPath + '&' + this.search.substring(1);
    if (historySupport) {
      history.pushState(
        {
          path: relPath,
        },
        'Navigate page',
        this.href.replace(/^.*?\/([^\/]+)$/, '$1')
      );
    }
    load(url, this.className.split(' ')[0]);
  }

  function tocLoaded() {
    $("#toc a[data-toggle='collapse']").click(function (ev) {
      var icon = $(this).find('span').text();
      $(this)
        .find('span')
        .text(icon == 'expand_less' ? 'expand_more' : 'expand_less');
    });
    $('.toc-link').click(function (ev) {
      $('#sidebar').offcanvas('hide');
    });
    $('.toc-link').click(initLinks);
  }

  resize();

  $('#zoom-in').click(function (ev) {
    ev.preventDefault();
    var size = getFontSize();
    $('#document-wrapper').css('font-size', size + 1 + 'px');
  });
  $('#zoom-out').click(function (ev) {
    ev.preventDefault();
    var size = getFontSize();
    $('#document-wrapper').css('font-size', size - 1 + 'px');
  });

  $('#logout').on('click', function (ev) {
    ev.preventDefault();
    window.location.search = window.location.search + '&logout=true';
  });

  $('.toc-toggle').click(function (ev) {
    $('#toc-loading').each(function () {
      console.log('Loading toc...');
      var doc =
        $('.nav-next').attr('data-doc') || $('.nav-prev').attr('data-doc');
      $('#toc').load(
        'templates/toc.html?doc=' +
          doc +
          '&' +
          window.location.search.substring(1),
        tocLoaded
      );
    });
  });

  initContent();

  // initialize popups for comment section
  $(
    '#comment .alternate, #sourceDesc .alternate, #comment .reference, #sourceDesc .reference'
  ).each(initAlternate);

  // initialize popups for sigle section
  $('#idno .alternate').each(popupFixed);

  $('#lang-select').on('change', function (ev) {
    var loc = window.location;
    var lang = $(this).val();
    var search;
    if (loc.search) {
      search = loc.search.replace(/\&?lang=[\w]+/, '');
      if (search == '?') {
        search = search + 'lang=' + lang;
      } else {
        search = search + '&lang=' + lang;
      }
    } else {
      search = '?lang=' + lang;
    }
    loc.replace(
      loc.protocol +
        '//' +
        loc.hostname +
        ':' +
        loc.port +
        loc.pathname +
        search +
        loc.hash
    );
  });
});

$(window).load(function () {
  if ($('#main-wrapper').length == 0) {
    return;
  }
  /*
   * Scroll the window to move anchor targets with hash under the topnav bar
   * https://github.com/twitter/bootstrap/issues/1768
   */
  var offset = $('#main-wrapper').offset().top;
  var shiftWindow = function () {
    scrollBy(0, -offset);
  };
  if (location.hash) {
    setTimeout(shiftWindow, 1);
  }
  window.addEventListener('hashchange', shiftWindow);
});
