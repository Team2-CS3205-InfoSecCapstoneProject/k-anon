$(document).ready(function() {

  $("#request_permission_form").submit( function(eventObj) {
      $('<input />').attr('type', 'hidden')
          .attr('name', "_csrf")
          .attr('value', csrfToken)
          .appendTo(this);
      return true;
  });

  $("#grant_permission_form").submit( function(eventObj) {
      $('<input />').attr('type', 'hidden')
          .attr('name', "_csrf")
          .attr('value', csrfToken)
          .appendTo(this);
      return true;
  });

  $('#datatable-checkbox').DataTable();

  $('#datatable').DataTable();
});

var csrfToken = $('meta[name="csrf-token"]').attr("content");
// if using ajax call, no need to append within the form, this below
// ajax prefilter will auto include inside the request header
$.ajaxPrefilter(function(options, originalOptions, jqXHR) {
  var method = options.type.toLowerCase();
  if (method === "post" || method === "put" || method === "delete") {
    jqXHR.setRequestHeader('X-CSRF-Token', csrfToken);
  }
});