// Generated by CoffeeScript 1.4.0
(function() {
  var $;

  $ = document.querySelector.bind(document);

  window.onmessage = function(e) {
    var message, tag, tagsHTML, _i, _len, _ref;
    message = e.data;
    $('#preview-title').innerHTML = message.title;
    tagsHTML = '';
    _ref = message.tags.split(/,\s*/g);
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      tag = _ref[_i];
      tagsHTML += "<li class='tag'><a href='/entry/" + tag + "'>" + tag + "</a></li>";
    }
    $('#preview-tags').innerHTML = tagsHTML;
    return $('#preview-body').innerHTML = message.body;
  };

}).call(this);