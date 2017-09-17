$(document).ready(function() {

    var HOST = "https://www.ssrq-sds-fds.ch";
    var PLACES_API = HOST + "/places-db-edit/views/get-info.xq";
    var KEYWORD_API = HOST + "/lemma-db-edit/views/get-key-info.xq";
    var LEMMA_API = HOST + "/lemma-db-edit/views/get-lem-info.xq";
    var PERSON_API = HOST + "/persons-db-api/";

    function updateSpans(key, label) {
        $("span[data-ref='" + key + "']").text(': ' + label);
        $("span[data-ref^='" + key + ".']").text(': ' + label);
    }

    function query(uri, param, list, callback) {
        var head = list.shift();
        if (head) {
            var key = $(head).attr("data-ref").replace(/^([^\.]+).*$/, "$1");
            var params = {};
            params[param] = key;
            $.ajax({
                url: uri,
                data: params,
                dataType: "json",
                success: function(data) {
                    query(uri, param, list, callback);
                    callback($(head), data);
                },
                error: function() {
                    query(uri, param, list, callback);
                }
            });
        }
    }

    query(PLACES_API, "id", $(".places li").toArray(), function(elem, entry) {
        if (entry.type) {
            elem.find("a").text(entry.stdName['#text']);
            if (entry.location) {
                elem.append($('<span class="location"></span>').text(entry.location));
            }
            elem.append($('<span class="type"></span>').text(entry.type));

            var label = entry.stdName['#text'] + ' (' + entry.location + '), ' +
                entry.type;
            updateSpans(elem.attr("data-ref"), label);
        }
    });

    query(PERSON_API, "query", $(".persons li").toArray(), function(elem, entry) {
        if (entry.name) {
            elem.find("a").text(entry.name);
            if (entry.dates) {
                elem.append($('<span class="info"></span>').text(entry.dates));
            }
            updateSpans(elem.attr("data-ref"), entry.name + ' (' + entry.dates + ')');
        }
    });
    query(PERSON_API, "query", $(".organizations li").toArray(), function(elem, entry) {
        if (entry.name) {
            elem.find("a").text(entry.name);
            if (entry.type) {
                elem.append($('<span class="info"></span>').text(entry.type));
            }

            updateSpans(elem.attr("data-ref"), entry.name + ' (' + entry.type + ')');
        }
    });

    query(KEYWORD_API, "id", $(".keywords li").toArray(), function(elem, entry) {
        if (entry.name) {
            elem.find("a").text(entry.name['#text']);
            console.log(entry);
            if (entry.definition['#text']) {
                elem.append($('<span class="info"></span>').text(entry.definition['#text']));
            }
        }

        updateSpans(elem.attr("data-ref"), entry.name['#text']);
    });

    query(LEMMA_API, "id", $(".lemmata li").toArray(), function(elem, entry) {
        if (entry.morphology) {
            var label = entry.stdName['#text'] + ' (' +
                entry.morphology + ')';
            elem.find("a").text(label);
            if (entry.definition) {
                elem.append($('<span class="info"></span>').text(': ' + entry.definition['#text']));
            }
            updateSpans(elem.attr("data-ref"), label);
        }
    });
});
