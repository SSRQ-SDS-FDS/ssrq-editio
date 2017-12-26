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
});
