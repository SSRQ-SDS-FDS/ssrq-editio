$(function () {
    $('#bearbeitungstext').on('change', function() {
        var checked = $(this).prop('checked');
        if (checked) {
            $(".bearbeitungstext").prop('checked', true);
        } else {
            $(".bearbeitungstext").prop('checked', false);
        }
    });
    $('.bearbeitungstext').on('change', function() {
        $('#bearbeitungstext').prop('checked', false);
    });

    var val = $('#bearbeitungstext').prop('value');
    if (val && val.length > 0) {
        var checked = $(".bearbeitungstext:checked").length;
        if (checked === 5) {
            $('#bearbeitungstext').prop('checked', true);
        } else {
            $('#bearbeitungstext').prop('checked', false);
        }
    } else {
        $('#bearbeitungstext').prop('checked', true);
        $(".bearbeitungstext").prop('checked', true);
    }

    // if there are highlighted search results in the page,
    // open the corresponding collapsible to make them visible to the user
    $('mark').each(function() {
        $(this).parents('.collapse').collapse('show');
    });

    $('#sort-select').on('change', function() {
        var sortBy = $(this).val();
        console.log("sorting by %s", sortBy);
        var href = window.location.href.replace(/&sort=\w+/, '');
        window.location.replace(href + '&sort=' + sortBy);
    });
});
