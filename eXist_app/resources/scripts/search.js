$(document).ready(function () {
  $("#bearbeitungstext").on("change", function () {
    var checked = $(this).prop("checked");
    if (checked) {
      $(".bearbeitungstext").prop("checked", true);
    } else {
      $(".bearbeitungstext").prop("checked", false);
    }
  });
  $(".bearbeitungstext").on("change", function () {
    var cb_checked = $(".bearbeitungstext:checked").length;
    var cb_total = $(".bearbeitungstext").length;
    var cb_top = document.getElementById("bearbeitungstext");
    cb_top.checked = cb_checked === cb_total;
    cb_top.indeterminate = cb_checked > 0 && cb_checked !== cb_total;
  });

  var val = $("#bearbeitungstext").prop("value");
  if (val && val.length > 0) {
    var checked = $(".bearbeitungstext:checked").length;
    if (checked === 5) {
      $("#bearbeitungstext").prop("checked", true);
    } else {
      $("#bearbeitungstext").prop("checked", false);
    }
  } else {
    $("#bearbeitungstext").prop("checked", true);
    $(".bearbeitungstext").prop("checked", true);
  }

  // if there are highlighted search results in the page,
  // open the corresponding collapsible to make them visible to the user
  $("mark").each(function () {
    $(this).parents(".collapse").collapse("show");
  });

  $("#sort-select").on("change", function () {
    var sortBy = $(this).val();
    console.log("sorting by %s", sortBy);
    var href = window.location.href.replace(/&sort=\w*/, "");
    window.location.replace(href + "&sort=" + sortBy);
  });
  $("#sort-browse").on("change", function () {
    $(this).parents("form").submit();
  });

  // Handle Reset action in the search form
  $("#searchPanel button[type='reset']").click(function (e) {
    e.preventDefault();
    resetSelects();
    resetInputs();
  });
});

function resetSelects() {
  $("#searchPanel select").each(function (i, select) {
    $("option", select).prop("selected", false);
    if (!select.multiple) {
      $("option:first", select).prop("selected", true);
    }
  });
}

function resetInputs() {
  $("#searchPanel input").each(function (i, input) {
    switch (input.type) {
      case "search":
        input.value = "";
        break;
      case "checkbox":
        controlCheckbox(input);
        break;
      case "number":
        input.value = "";
        break;
      default:
        break;
    }
  });
}

function controlCheckbox(box) {
  switch (box.name) {
    case "subtype":
      box.checked = true;
      break;
    case "filter-language":
      box.checked = false;
      break;
    default:
      box.checked = true;
      break;
  }
}
