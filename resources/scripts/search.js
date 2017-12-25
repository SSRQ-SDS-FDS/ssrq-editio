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

    var checked = $(".bearbeitungstext:checked").length;
    if (checked === 0 || checked === 5) {
        $('#bearbeitungstext').prop('checked', true);
        $(".bearbeitungstext").prop('checked', true);
    } else {
        $('#bearbeitungstext').prop('checked', false);
    }
});
