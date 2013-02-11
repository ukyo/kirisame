window.onload = ->
  # alias of querySelector
  $ = document.querySelector.bind document
  
  # initialize ACE.
  window.editor = ace.edit 'editor'
  editor.setShowInvisibles true
  editor.getSession().setUseWrapMode true
  editor.getSession().setTabSize 2
  editor.getSession().setMode 'ace/mode/markdown'
  editor.setTheme 'ace/theme/ambiance'

  # input fields
  titleField = $ 'input[name=title]'
  nameField = $ 'input[name=name]'
  tagsField = $ 'input[name=tags]'

  isNewEntry = /^.*\/admin\/entry[\/#]?$/.test location.href
  oldTags = tagsField.value

  # convert markdown to html.
  md2html = (md) ->
    dummy = document.createElement 'p'
    dummy.innerHTML = markdown.toHTML5 md, 'GFM'
    pres = dummy.querySelectorAll 'pre[class^=lang]'
    for pre in pres
      code = pre.querySelector 'code'
      lang = pre.getAttribute('class').match(/lang-([a-zA-Z+]*)/)[1]
      lang = 'c_cpp' if lang is 'c' or lang is 'cpp'
      pre.innerHTML = ace.highlight(code.innerHTML, "ace/mode/#{lang}").innerHTML
    dummy.innerHTML
  

  ###
  User inputs metadatas from the this panel.
  metadatas:
  * Entry title
  * Entry name(http://example.com/entry/path-to-entry)
  * Tags that is sepalated ','.
  ###
  metadataPanel = new class
    # private members
    panel = $ '#metadata .wrap'

    # show the metadata panel and focus on the title input field.
    show: =>
      panel.classList.remove 'disabled'
      titleField.focus()

    # hide the metadata panel and focus on the editor.
    hide: =>
      panel.classList.add 'disabled'
      editor.focus()

    # toggle the metadata panel
    toggle: => unless @isVisibled() then @show() else @hide()
  
    # check the metadata panel is visibled.
    isVisibled: => not panel.classList.contains 'disabled'

  ###
  previewWindow controlls the realtime preview window.
  It watches editing texts and update every a second.
  Ofcourse, if texts was not updated, it does not update the preview.
  ###
  previewWindow = new class
    # private members
    prev = null
    current = editor.getValue()
    preview = null
    interval = null

    open: =>
      return if @isOpen()
      preview = window.open '/admin/preview', 'preview', 'width=800,height=600'
      preview.onload = =>
        @update()
        @run()

    close: =>
      if @isOpen()
        preview.close()
        @stop()
        prev = null

    toggle: => unless @isOpen() then @open() else @close()

    isOpen: => unless preview then false else not preview.closed

    run: => interval = setInterval @update, 1000

    stop: => clearInterval interval

    update: =>
      console.log Date.now()
      # check the preview window is open.
      return unless @isOpen()
      # check the text was updated.
      current = editor.getValue()
      return if prev is current
      prev = current
      message =
        title: titleField.value
        tags: tagsField.value
        body: md2html current
      preview.postMessage message, '*'


  ###
  This panel notifies some informations.
  It down from adove of the window.
  ###
  infoPanel = new class
    #private member
    panel = $ '#info'

    show: => panel.classList.remove 'disabled'
    hide: => panel.classList.add 'disabled'
    setContent: (content) => panel.innerHTML = content


  # validate title and path of entry.
  validate = ->
    if titleField.value is ''
      metadataPanel.show()
      return false
    if nameField.value is ''
      metadataPanel.show()
      nameField.focus()
      return false
    true

  # save the entry.
  save = ->
    return unless validate()
    # send with ajax.
    xhr = new XMLHttpRequest
    method = if isNewEntry then 'POST' else 'PUT'
    xhr.open method, "/admin/entry/#{nameField.value}"
    xhr.onload = ->
      return if xhr.response is 'error'
      href = "http://#{location.host}/entry/#{nameField.value}"
      infoPanel.setContent "succeeded to save: <a href='#{href}' target='_blank'>#{href}</a>"
      infoPanel.show()
      setTimeout infoPanel.hide, 5000
      isNewEntry = false
      oldTags = tagsField.value
    fd = common.createFormData
      title: titleField.value
      name: nameField.value
      tags: tagsField.value
      oldTags: oldTags
      text: editor.getValue()
      html: md2html editor.getValue()
    xhr.send fd

  # back to admin home.
  home = -> location.href = '/admin' if confirm 'back to admin home.'

  # bind to click events
  $('#home').onclick = home
  $('#preview').onclick = previewWindow.toggle
  $('#save').onclick = save
  # $('.up-down').onclick = metadataPanel.toggle

  # bind to shortcuts
  shortcut.add 'Ctrl+I', metadataPanel.toggle
  shortcut.add 'Ctrl+S', save
  shortcut.add 'Ctrl+Shift+H', home