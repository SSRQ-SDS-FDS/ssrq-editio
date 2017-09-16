$(document).ready(function() {

    var HOST = "https://www.ssrq-sds-fds.ch";
    var PLACES_API = HOST + "/places-db-edit/views/get-info.xq";
    var KEYWORD_API = HOST + "/lemma-db-edit/views/get-key-info.xq";
    var LEMMA_API = HOST + "/lemma-db-edit/views/get-lem-info.xq";
    var PERSON_API = HOST + "/persons-db-api/";

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

    $(".persons li").each(function() {
        var elem = $(this);
        var key = elem.attr("data-ref");
        $.ajax({
            url: PERSON_API,
            data: {
                "query": key
            },
            dataType: "json",
            success: function(entry) {
                if (entry.name) {
                    elem.find("a").text(entry.name);
                    if (entry.dates) {
                        elem.append($('<span class="dates"></span>').text(entry.dates));
                    }

                    var label = entry.name + ' (' + entry.dates + ')';
                    $("#document-pane span[data-ref='" + key + "']").text(label);
                }
            }
        });
    });

    $(".organizations li").each(function() {
        var elem = $(this);
        var key = elem.attr("data-ref");
        $.ajax({
            url: PERSON_API,
            data: {
                "query": key
            },
            dataType: "json",
            success: function(entry) {
                if (entry.name) {
                    elem.find("a").text(entry.name);
                    if (entry.type) {
                        elem.append($('<span class="dates"></span>').text(entry.type));
                    }

                    var label = entry.name + ' (' + entry.type + ')';
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
                        entry.morphology + ')';
                    elem.find("a").text(label);
                    if (entry.definition) {
                        elem.append($('<span class="dates"></span>').text(': ' + entry.definition['#text']));
                    }
                    $("#document-pane span[data-ref='" + key + "']").text(label);
                }
            }
        });
    });
});
