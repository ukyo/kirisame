window.common =
  createFormData: (params) ->
    fd = new FormData
    for key, param of params
      fd.append key, param
    fd.append '_csrf', document.getElementById('csrftoken').value
    fd
    
  cookie: (key) ->
    for item in document.cookie.split ';'
      [k, v] = item.split '='
      return v if k is key