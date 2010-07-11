$(function() {
  $("#search").autocomplete({
    source: '/search.json',
    select: function(event, ui) {
      var url = '/titles/' + ui['item']['label'];
      $(location).attr('href', url);
    }
  });
});
