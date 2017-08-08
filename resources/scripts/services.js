$(document).ready(function() {

    var HOST = "https://www.ssrq-sds-fds.ch";
    var PLACES_API = HOST + "/places-db-edit/views/get-info.xq";
    var KEYWORD_API = HOST + "/lemma-db-edit/views/get-key-info.xq";
    var LEMMA_API = HOST + "/lemma-db-edit/views/get-lem-info.xq";

    $(".places li").each(function() {
        var elem = $(this);
        var key = elem.attr("data-ref");
        $.ajax({
            url: PLACES_API,
            data: {
                "id": key
            },
            dataType: "json",
            success: function(entry) {
                if (entry.type) {
                    elem.find("a").text(entry.stdName['#text']);
                    if (entry.location) {
                        elem.append($('<span class="location"></span>').text(entry.location));
                    }
                    elem.append($('<span class="type"></span>').text(entry.type));

                    var label = entry.stdName['#text'] + ' (' + entry.location + '), ' +
                        entry.type;
                    $("#document-pane span[data-ref='" + key + "']").text(label);
                }
            }
        });
    });

    $(".keywords li").each(function() {
        var elem = $(this);
        var key = elem.attr("data-ref");
        $.ajax({
            url: KEYWORD_API,
            data: {
                "id": key
            },
            dataType: "json",
            success: function(entry) {
                if (entry.type) {
                    elem.find("a").text(entry.name['#text']);
                }

                $("#document-pane span[data-ref='" + key + "']").text(entry.name['#text']);
            }
        });
    });

    $(".lemmata li").each(function() {
        var elem = $(this);
        var key = elem.attr("data-ref");
        $.ajax({
            url: LEMMA_API,
            data: {
                "id": key
            },
            dataType: "json",
            success: function(entry) {
                if (entry.morphology) {
                    var label = entry.stdName['#text'] + ' (' +
                        entry.morphology + '): ' + entry.definition['#text'];
                    elem.find("a").text(label);
                    $("#document-pane span[data-ref='" + key + "']").text(label);
                }
            }
        });
    });

    $('.reference').
        popover({
            content: function() {
                console.log(this);
                return $(this).find(".altcontent").html();
            },
            html: true,
            trigger: 'hover',
            container: "#document-wrapper",
            viewport: "#document-pane",
            placement: "auto top"
        });
});
