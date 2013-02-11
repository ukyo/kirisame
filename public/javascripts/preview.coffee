$ = document.querySelector.bind document
window.onmessage = (e) ->
  message = e.data
  $('#preview-title').innerHTML = message.title
  tagsHTML = ''
  for tag in message.tags.split /,\s*/g
    tagsHTML += "<li class='tag'><a href='/entry/#{tag}'>#{tag}</a></li>"
  $('#preview-tags').innerHTML = tagsHTML
  $('#preview-body').innerHTML = message.body