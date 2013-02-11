window.onload = ->
  csrfToken = common.cookie 'csrftoken'

  successCallback = ->
    alert 'success'
    location.href = '/admin/entries'

  errorCallback = -> alert 'error'

  deleteEntry = (e) ->
    e.preventDefault()
    return if not confirm "delete #{@href}."
    xhr = new XMLHttpRequest
    xhr.open 'DELETE', @href
    xhr.onload = successCallback
    xhr.onerror = errorCallback
    fd = new FormData
    fd.append 'csrftoken', csrfToken
    xhr.send(fd)

  link.onclick = deleteEntry for link in document.querySelectorAll '.delete'