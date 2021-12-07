$(function () {
  $('#bearbeitungstext').on('change', function () {
    var checked = $(this).prop('checked');
    if (checked) {
      $('.bearbeitungstext').prop('checked', true);
    } else {
      $('.bearbeitungstext').prop('checked', false);
    }
  });
  $('.bearbeitungstext').on('change', function () {
    $('#bearbeitungstext').prop('checked', false);
  });

  var val = $('#bearbeitungstext').prop('value');
  if (val && val.length > 0) {
    var checked = $('.bearbeitungstext:checked').length;
    if (checked === 5) {
      $('#bearbeitungstext').prop('checked', true);
    } else {
      $('#bearbeitungstext').prop('checked', false);
    }
  } else {
    $('#bearbeitungstext').prop('checked', true);
    $('.bearbeitungstext').prop('checked', true);
  }

  // if there are highlighted search results in the page,
  // open the corresponding collapsible to make them visible to the user
  $('mark').each(function () {
    $(this).parents('.collapse').collapse('show');
  });

  $('#sort-select').on('change', function () {
    var sortBy = $(this).val();
    console.log('sorting by %s', sortBy);
    var href = window.location.href.replace(/&sort=\w*/, '');
    window.location.replace(href + '&sort=' + sortBy);
  });
  $('#sort-browse').on('change', function () {
    $(this).parents('form').submit();
  });
});

// Handling Reset Action in the Seach-Form
const resetButton = document.querySelector("button[type='reset']");
if (resetButton) {
  resetButton.addEventListener('click', (e) => {
    handleReset(e);
  });
}

function handleReset(e) {
  e.preventDefault();
  resetSelects();
  resetInputs();
}

function resetSelects() {
  const selects = document.querySelectorAll('#searchPanel select');
  selects.forEach((select) => {
    if (select.multiple) {
      const options = select.querySelectorAll('option');
      options.forEach((option) => (option.selected = false));
    } else {
      const defaultOption = select.querySelector('option');
      defaultOption.selected = true;
    }
  });
}

function resetInputs() {
  const inputs = document.querySelectorAll('#searchPanel input');
  inputs.forEach((input) => {
    switch (input.type) {
      case 'search':
        input.value = '';
        break;
      case 'checkbox':
        controlCheckbox(input);
        break;
      case 'number':
        input.value = '';
        break;
      default:
        break;
    }
  });
}

function controlCheckbox(box) {
  switch (box.name) {
    case 'subtype':
      box.checked = true;
      break;
    case 'filter-language':
      box.checked = false;
      break;
    default:
      box.checked = true;
      break;
  }
}
