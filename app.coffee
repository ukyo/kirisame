express = require 'express'
http = require 'http'
path = require 'path'
auth = require './auth'
model = require './model'
config = require './config'

Entry = model.Entry
app = express()


# middlewares

addRecentEntries = (req, res, next) ->
  Entry.getRecentEntries (err, recentEntries) ->
    res.locals {recentEntries}
    next()

addTagCloud = (req, res, next) ->
  Entry.getTagCloud (err, tagCloud) ->
    res.locals {tagCloud}
    next()

addDefaultContext = (req, res, next) ->
  res.locals
    blogTitle: config.blogTitle
    description: config.description
    copy: config.copyright
    author: config.author
    disqus: config.disqus
    req: req
  next()

addCsrfToken = (req, res, next) ->
  res.locals {csrf: req.session._csrf}
  next()

overwritePageIndex = (req, res, next) ->
  page = parseInt req.query.page
  page = 1 if isNaN page
  page = 1 if page < 1
  req.query.page = page
  next()


# configuration

app.configure ->
  app.set 'port', process.env.PORT || 3000
  app.set 'views', "#{__dirname}/views"
  app.set 'view engine', 'jade'
  app.use express.favicon()
  app.use express.logger 'dev'
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.cookieParser config.cookieSeed
  app.use express.session()
  app.use auth.passport.initialize()
  app.use auth.passport.session()
  app.use app.router
  app.use express.csrf()
  app.use require('less-middleware') src: "#{__dirname}/public"
  app.use express.static path.join(__dirname, 'public')

app.configure 'development', ->
  app.use express.errorHandler()


# routing

# set middlewares
app.all '/admin*', auth.ensureAuthenticated(failureRedirect: '/login'), addCsrfToken
app.get '/admin/entries*', overwritePageIndex
app.get '/', addRecentEntries, addTagCloud, overwritePageIndex, addDefaultContext
app.get '/tag/*', addRecentEntries, addTagCloud, overwritePageIndex, addDefaultContext
app.get '/entry/*', addRecentEntries, addTagCloud, addDefaultContext
app.get '/admin/preview', addRecentEntries, addTagCloud, addDefaultContext

# index page
app.get '/', (req, res) ->
  Entry.getIndexEntries req.query.page, (err, entries, context) ->
    return res.render 'index', context unless err
    res.send 'error'

# rss
app.get '/atom', (req, res) -> res.render 'atom'

# entry page
app.get '/entry/:name', (req, res) ->
  Entry.findByName req.params.name, (err, entry) ->
    return res.render 'entry', {entry: entry} unless err
    res.send 'error'

# tag page
app.get '/tag/:name', (req, res) ->
  tag = req.params.name
  res.locals tag: tag
  Entry.getTagEntries req.query.page, tag, (err, entries, context) ->
    return res.render 'tag', context unless err
    res.send 'error'

# login page for administrator
app.get '/login', (req, res) -> res.render 'login'

app.post '/login', auth.authenticate
  successRedirect: '/admin'
  failureRedirect: '/login'

# logout page for administrator
app.get '/logout', (req, res) ->
  req.logout()
  res.redirect '/login'

# admin root
app.get '/admin', (req, res) -> res.render 'admin/index'

# admin entries manager
app.get '/admin/entries', (req, res) ->
  Entry.getAdminEntries req.query.page, (err, entries, context) ->
    return res.render 'admin/entries', context unless err
    res.send 'error'

# open the entry editor to create new one
app.get '/admin/entry', (req, res) -> res.render 'admin/edit', {isNew: true}

# open the entry editor to update one
app.get '/admin/entry/:name', (req, res) ->
  Entry.findByName req.params.name, (err, entry) ->
    return res.render 'admin/edit', entry unless err
    res.send 'error'

genOnComplete = (res) ->
  (err, entry) -> res.send unless err then 'success' else 'error'

# create the new entry
app.post '/admin/entry/:name', (req, res) ->
  entry = new Entry req.body
  entry.save genOnComplete res

# update the entry
app.put '/admin/entry/:name', (req, res) ->
  Entry.findByNameAndUpdate req.params.name, req.body, genOnComplete res

# delete the entry
app.delete '/admin/entry/:name', (req, res) ->
  Entry.findByNameAndRemove req.params.name, genOnComplete res

# preview the entry
app.get '/admin/preview', (req, res) -> res.render 'preview'


# run server
http.createServer(app).listen app.get('port'), ->
  console.log "Express server listening on port #{app.get 'port'}"
